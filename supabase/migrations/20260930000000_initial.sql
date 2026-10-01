-- Sivasakthi Wood Works initial schema. Apply through Supabase SQL editor/CLI.
create extension if not exists pgcrypto;
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;

create table if not exists public.profiles (id uuid primary key references auth.users(id) on delete cascade, full_name text not null default '', phone text, address text, city text, state text, pincode text, avatar_url text, role text not null default 'user' check(role in ('user','admin')), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), email text);
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin'); $$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,email,full_name,phone) values(new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name',''),new.raw_user_meta_data->>'phone') on conflict(id) do update set email=excluded.email; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
create or replace function public.sync_profile_email() returns trigger language plpgsql security definer set search_path=public as $$ begin update public.profiles set email=new.email where id=new.id; return new; end; $$;
drop trigger if exists on_auth_user_email_changed on auth.users;
create trigger on_auth_user_email_changed after update of email on auth.users for each row execute procedure public.sync_profile_email();
create table if not exists public.categories (id uuid primary key default gen_random_uuid(), name text not null unique, slug text not null unique, description text, image_url text, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.products (id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique, category_id uuid references public.categories(id) on delete set null, description text not null default '', price numeric(12,2) not null check(price>=0), discount_price numeric(12,2) check(discount_price is null or (discount_price>=0 and discount_price<=price)), image_url text, stock_quantity integer not null default 0 check(stock_quantity>=0), active boolean not null default true, featured boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.product_images (id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade, image_url text not null, alt_text text, sort_order integer not null default 0, created_at timestamptz not null default now());
create table if not exists public.cart_items (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, product_id uuid not null references public.products(id) on delete cascade, quantity integer not null default 1 check(quantity between 1 and 99), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,product_id));
create table if not exists public.wishlist_items (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, product_id uuid not null references public.products(id) on delete cascade, created_at timestamptz not null default now(), unique(user_id,product_id));
create table if not exists public.orders (id uuid primary key default gen_random_uuid(), order_number text not null unique default ('SW-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10))), user_id uuid not null references public.profiles(id), customer_name text not null, phone text not null, address text not null, city text not null, state text not null, pincode text not null, subtotal numeric(12,2) not null check(subtotal>=0), total numeric(12,2) not null check(total>=0), payment_method text not null default 'Cash on Delivery' check(payment_method='Cash on Delivery'), status text not null default 'Pending' check(status in ('Pending','Confirmed','Processing','Shipped','Delivered','Cancelled')), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.order_items (id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, product_id uuid references public.products(id) on delete set null, product_name text not null, image_url text, unit_price numeric(12,2) not null check(unit_price>=0), quantity integer not null check(quantity>0), created_at timestamptz not null default now());
create table if not exists public.quote_requests (id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(id) on delete set null, name text not null, phone text not null, email text, category text, work_type text, description text not null, approximate_budget text, preferred_contact text not null default 'Phone', image_url text, status text not null default 'New' check(status in ('New','Contacted','In Progress','Completed','Closed')), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.contact_messages (id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(id) on delete set null, name text not null, email text, phone text, message text not null, status text not null default 'New' check(status in ('New','Read','Replied','Closed')), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.gallery (id uuid primary key default gen_random_uuid(), title text not null, category text not null, image_url text not null, description text, active boolean not null default true, sort_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.reviews (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, product_id uuid references public.products(id) on delete set null, rating integer not null check(rating between 1 and 5), review text not null, approved boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,product_id));
create index if not exists products_active_featured_idx on public.products(active,featured,created_at desc);
create index if not exists products_category_idx on public.products(category_id);
create index if not exists orders_user_created_idx on public.orders(user_id,created_at desc);
create index if not exists quote_requests_created_idx on public.quote_requests(created_at desc);

alter table public.profiles enable row level security; alter table public.categories enable row level security; alter table public.products enable row level security; alter table public.product_images enable row level security; alter table public.cart_items enable row level security; alter table public.wishlist_items enable row level security; alter table public.orders enable row level security; alter table public.order_items enable row level security; alter table public.quote_requests enable row level security; alter table public.contact_messages enable row level security; alter table public.gallery enable row level security; alter table public.reviews enable row level security;
create policy "profile own read" on public.profiles for select using(id=auth.uid() or public.is_admin()); create policy "profile own update" on public.profiles for update using(id=auth.uid() or public.is_admin()) with check(id=auth.uid() or public.is_admin()); create policy "admin profiles" on public.profiles for all using(public.is_admin()) with check(public.is_admin());
create policy "public active categories" on public.categories for select using(active or public.is_admin()); create policy "admin categories" on public.categories for all using(public.is_admin()) with check(public.is_admin());
create policy "public active products" on public.products for select using(active or public.is_admin()); create policy "admin products" on public.products for all using(public.is_admin()) with check(public.is_admin());
create policy "public product images" on public.product_images for select using(exists(select 1 from public.products p where p.id=product_id and (p.active or public.is_admin()))); create policy "admin product images" on public.product_images for all using(public.is_admin()) with check(public.is_admin());
create policy "own cart" on public.cart_items for all using(user_id=auth.uid() or public.is_admin()) with check(user_id=auth.uid() or public.is_admin()); create policy "own wishlist" on public.wishlist_items for all using(user_id=auth.uid() or public.is_admin()) with check(user_id=auth.uid() or public.is_admin());
create policy "own orders read" on public.orders for select using(user_id=auth.uid() or public.is_admin()); create policy "own orders create" on public.orders for insert with check(user_id=auth.uid()); create policy "admin orders manage" on public.orders for all using(public.is_admin()) with check(public.is_admin()); create policy "order items read" on public.order_items for select using(exists(select 1 from public.orders o where o.id=order_id and (o.user_id=auth.uid() or public.is_admin()))); create policy "own order items create" on public.order_items for insert with check(exists(select 1 from public.orders o where o.id=order_id and o.user_id=auth.uid())); create policy "admin order items" on public.order_items for all using(public.is_admin()) with check(public.is_admin());
create policy "quote own or admin read" on public.quote_requests for select using(user_id=auth.uid() or public.is_admin()); create policy "public quote create" on public.quote_requests for insert with check(user_id is null or user_id=auth.uid()); create policy "admin quote manage" on public.quote_requests for all using(public.is_admin()) with check(public.is_admin());
create policy "public contact create" on public.contact_messages for insert with check(user_id is null or user_id=auth.uid()); create policy "admin contact manage" on public.contact_messages for all using(public.is_admin()) with check(public.is_admin());
create policy "public gallery read" on public.gallery for select using(active or public.is_admin()); create policy "admin gallery manage" on public.gallery for all using(public.is_admin()) with check(public.is_admin()); create policy "approved reviews read" on public.reviews for select using(approved or user_id=auth.uid() or public.is_admin()); create policy "own review create" on public.reviews for insert with check(user_id=auth.uid() and approved=false); create policy "own review update" on public.reviews for update using(user_id=auth.uid() and approved=false) with check(user_id=auth.uid() and approved=false); create policy "admin reviews manage" on public.reviews for all using(public.is_admin()) with check(public.is_admin());
-- Public image reads; only admins can upload/change/delete. Keep service-role keys server-side.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('woodwork-media','woodwork-media',true,5242880,array['image/jpeg','image/png','image/webp']) on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
create policy "public read woodwork media" on storage.objects for select using(bucket_id='woodwork-media'); create policy "admin upload woodwork media" on storage.objects for insert with check(bucket_id='woodwork-media' and public.is_admin()); create policy "admin update woodwork media" on storage.objects for update using(bucket_id='woodwork-media' and public.is_admin()) with check(bucket_id='woodwork-media' and public.is_admin()); create policy "admin delete woodwork media" on storage.objects for delete using(bucket_id='woodwork-media' and public.is_admin());

-- Allow optional guest quote-reference uploads in an isolated public prefix.
create policy "guest quote reference upload" on storage.objects for insert with check(bucket_id='woodwork-media' and name like 'quote-requests/guest/%' and auth.uid() is null);
create policy "user quote reference upload" on storage.objects for insert with check(bucket_id='woodwork-media' and name like ('quote-requests/'||auth.uid()::text||'/%'));

-- Prevent customers from changing their own authorization role.
revoke update on public.profiles from authenticated;
grant update(full_name,phone,address,city,state,pincode,avatar_url) on public.profiles to authenticated;

insert into public.categories(name,slug) values
('Main Doors','main-doors'),('Wooden Doors','wooden-doors'),('Pooja Doors','pooja-doors'),('Interior Doors','interior-doors'),('Windows','windows'),('Modular Kitchen','modular-kitchen'),('TV Units','tv-units'),('Wardrobes','wardrobes'),('Dining Tables','dining-tables'),('Bedroom Furniture','bedroom-furniture'),('Office Furniture','office-furniture'),('Custom Wood Works','custom-wood-works')
on conflict(slug) do nothing;

-- Server-side price lookup, inventory checks, and order creation run atomically.
create or replace function public.place_cod_order(
  p_customer_name text, p_phone text, p_address text, p_city text, p_state text, p_pincode text, p_items jsonb
) returns table(order_id uuid, order_number text)
language plpgsql security definer set search_path=public,pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_order_id uuid;
  v_order_number text;
  v_subtotal numeric(12,2) := 0;
  v_item record;
  v_product public.products%rowtype;
  v_price numeric(12,2);
begin
  if v_user is null then raise exception 'Please sign in before placing an order'; end if;
  if length(trim(coalesce(p_customer_name,''))) not between 1 and 120
    or length(trim(coalesce(p_phone,''))) not between 7 and 20
    or length(trim(coalesce(p_address,''))) not between 1 and 300
    or length(trim(coalesce(p_city,''))) not between 1 and 100
    or length(trim(coalesce(p_state,''))) not between 1 and 100
    or p_pincode !~ '^[0-9]{6}$' then raise exception 'Please provide a valid delivery address'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) not between 1 and 50 then raise exception 'Your cart is empty or invalid'; end if;
  for v_item in select (x->>'product_id')::uuid as product_id, (x->>'quantity')::integer as quantity from jsonb_array_elements(p_items) x loop
    if v_item.quantity is null or v_item.quantity not between 1 and 99 then raise exception 'Invalid item quantity'; end if;
    select * into v_product from public.products where id=v_item.product_id and active=true for update;
    if not found then raise exception 'A product in your cart is no longer available'; end if;
    if v_product.stock_quantity > 0 and v_item.quantity > v_product.stock_quantity then raise exception 'Not enough stock for %', v_product.name; end if;
    v_price := coalesce(v_product.discount_price,v_product.price);
    v_subtotal := v_subtotal + v_price * v_item.quantity;
  end loop;
  insert into public.orders(user_id,customer_name,phone,address,city,state,pincode,subtotal,total,payment_method)
    values(v_user,trim(p_customer_name),trim(p_phone),trim(p_address),trim(p_city),trim(p_state),trim(p_pincode),v_subtotal,v_subtotal,'Cash on Delivery')
    returning id,orders.order_number into v_order_id,v_order_number;
  for v_item in select (x->>'product_id')::uuid as product_id, (x->>'quantity')::integer as quantity from jsonb_array_elements(p_items) x loop
    select * into v_product from public.products where id=v_item.product_id;
    v_price := coalesce(v_product.discount_price,v_product.price);
    insert into public.order_items(order_id,product_id,product_name,image_url,unit_price,quantity)
      values(v_order_id,v_product.id,v_product.name,v_product.image_url,v_price,v_item.quantity);
    if v_product.stock_quantity > 0 then update public.products set stock_quantity=stock_quantity-v_item.quantity where id=v_product.id; end if;
  end loop;
  delete from public.cart_items where user_id=v_user;
  return query select v_order_id,v_order_number;
end;
$$;
revoke all on function public.place_cod_order(text,text,text,text,text,text,jsonb) from public, anon;
grant execute on function public.place_cod_order(text,text,text,text,text,text,jsonb) to authenticated;

insert into public.products(name,slug,category_id,description,price,discount_price,image_url,stock_quantity,active,featured)
select seed.name,seed.slug,c.id,seed.description,seed.price,seed.discount_price,seed.image_url,0,true,seed.featured
from (values
  ('Hand-finished Main Door','sample-hand-finished-main-door','main-doors','A made-to-order main door concept with a warm wood finish. Contact us to discuss dimensions and detailing.',28500::numeric,null::numeric,'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=900&q=80',true),
  ('Classic Interior Door','sample-classic-interior-door','interior-doors','A clean-lined interior door concept for a calm, cohesive home. Finish and sizing can be discussed.',12500::numeric,11250::numeric,'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?auto=format&fit=crop&w=900&q=80',true),
  ('Solid Wood Dining Table','sample-solid-wood-dining-table','dining-tables','A made-to-order dining table concept. Share your preferred dimensions and finish for a tailored quote.',32000::numeric,null::numeric,'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=900&q=80',true),
  ('Custom Media Unit','sample-custom-media-unit','tv-units','A custom media unit concept with storage planned around your room and equipment.',18500::numeric,null::numeric,'https://images.unsplash.com/photo-1600210491369-e753d80a41f3?auto=format&fit=crop&w=900&q=80',true)
) as seed(name,slug,category_slug,description,price,discount_price,image_url,featured)
join public.categories c on c.slug=seed.category_slug
on conflict(slug) do nothing;

do $$
declare
  table_name text;
begin
  foreach table_name in array array['profiles','categories','products','cart_items','orders','quote_requests','contact_messages','gallery','reviews'] loop
    execute format('drop trigger if exists set_updated_at on public.%I', table_name);
    execute format('create trigger set_updated_at before update on public.%I for each row execute procedure public.set_updated_at()', table_name);
  end loop;
end;
$$;
