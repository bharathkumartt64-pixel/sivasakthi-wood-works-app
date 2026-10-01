-- Read-only inspection of migration objects. Safe to run in Supabase SQL Editor.
-- This query contains SELECT statements only; it creates, alters, or deletes nothing.
with
requested_tables(table_name) as (
  values
    ('profiles'), ('categories'), ('products'), ('product_images'),
    ('cart_items'), ('wishlist_items'), ('orders'), ('order_items'),
    ('quote_requests'), ('contact_messages'), ('gallery'), ('reviews')
),
requested_functions(function_name) as (
  values ('is_admin'), ('handle_new_user'), ('sync_profile_email'), ('place_cod_order')
),
expected_triggers(schema_name, table_name, trigger_name) as (
  values
    ('auth', 'users', 'on_auth_user_created'),
    ('auth', 'users', 'on_auth_user_email_changed'),
    ('public', 'profiles', 'set_updated_at'),
    ('public', 'categories', 'set_updated_at'),
    ('public', 'products', 'set_updated_at'),
    ('public', 'cart_items', 'set_updated_at'),
    ('public', 'orders', 'set_updated_at'),
    ('public', 'quote_requests', 'set_updated_at'),
    ('public', 'contact_messages', 'set_updated_at'),
    ('public', 'gallery', 'set_updated_at'),
    ('public', 'reviews', 'set_updated_at')
),
actual_triggers as (
  select
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    pg_get_triggerdef(t.oid, true) as trigger_definition
  from pg_trigger t
  join pg_class c on c.oid = t.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
  where not t.tgisinternal
    and (
      (n.nspname = 'public' and c.relname in (select table_name from requested_tables))
      or (n.nspname = 'auth' and c.relname = 'users')
    )
),
policy_summary as (
  select
    tablename,
    count(*) as policy_count,
    string_agg(format('%I (%s)', policyname, cmd), ', ' order by policyname) as policy_list
  from pg_policies
  where schemaname = 'public'
    and tablename in (select table_name from requested_tables)
  group by tablename
)
select category, object_name, status, details
from (
  select
    'TABLE'::text as category,
    format('public.%I', rt.table_name) as object_name,
    case when c.oid is null then 'NOT EXISTS' else 'EXISTS' end as status,
    case when c.oid is null then 'Not found as a table/partition in public schema'
         else format('RLS %s', case when c.relrowsecurity then 'enabled' else 'disabled' end)
    end as details
  from requested_tables rt
  left join pg_namespace n on n.nspname = 'public'
  left join pg_class c on c.relnamespace = n.oid
    and c.relname = rt.table_name
    and c.relkind in ('r', 'p')

  union all

  select
    'FUNCTION',
    format('public.%I', rf.function_name),
    case when count(p.oid) > 0 then 'EXISTS' else 'NOT EXISTS' end,
    coalesce(string_agg(case when p.oid is not null then format('%I(%s)', p.proname, pg_get_function_identity_arguments(p.oid)) end, '; ' order by pg_get_function_identity_arguments(p.oid)), 'No matching function in public schema')
  from requested_functions rf
  left join pg_namespace n on n.nspname = 'public'
  left join pg_proc p on p.pronamespace = n.oid and p.proname = rf.function_name
  group by rf.function_name

  union all

  select
    'TRIGGER',
    format('%I.%I.%I', at.schema_name, at.table_name, at.trigger_name),
    'EXISTS',
    at.trigger_definition
  from actual_triggers at

  union all

  select
    'TRIGGER',
    format('%I.%I.%I', et.schema_name, et.table_name, et.trigger_name),
    'NOT EXISTS',
    'Expected migration trigger not found'
  from expected_triggers et
  where not exists (
    select 1 from actual_triggers at
    where at.schema_name = et.schema_name
      and at.table_name = et.table_name
      and at.trigger_name = et.trigger_name
  )

  union all

  select
    'RLS POLICIES',
    format('public.%I', rt.table_name),
    case when c.oid is null or coalesce(ps.policy_count, 0) = 0 then 'NOT EXISTS' else 'EXISTS' end,
    case when c.oid is null then 'Table not found'
         when coalesce(ps.policy_count, 0) = 0 then format('RLS %s; no policies found', case when c.relrowsecurity then 'enabled' else 'disabled' end)
         else format('RLS %s; %s polic%s: %s', case when c.relrowsecurity then 'enabled' else 'disabled' end, ps.policy_count, case when ps.policy_count = 1 then 'y' else 'ies' end, ps.policy_list)
    end
  from requested_tables rt
  left join pg_namespace n on n.nspname = 'public'
  left join pg_class c on c.relnamespace = n.oid
    and c.relname = rt.table_name
    and c.relkind in ('r', 'p')
  left join policy_summary ps on ps.tablename = rt.table_name

  union all

  select
    'RLS POLICY',
    format('public.%I.%I', pol.tablename, pol.policyname),
    'EXISTS',
    format('command=%s; roles=%s; using=%s; check=%s', pol.cmd, array_to_string(pol.roles, ','), coalesce(pol.qual, '—'), coalesce(pol.with_check, '—'))
  from pg_policies pol
  where pol.schemaname = 'public'
    and pol.tablename in (select table_name from requested_tables)

  union all

  select
    'STORAGE BUCKET',
    'woodwork-media',
    case when exists (select 1 from storage.buckets b where b.id = 'woodwork-media') then 'EXISTS' else 'NOT EXISTS' end,
    coalesce((select format('id=%s; name=%s; public=%s', b.id, b.name, b.public::text) from storage.buckets b where b.id = 'woodwork-media' limit 1), 'No matching bucket in storage.buckets')
) report
order by category, object_name;
