# Sivasakthi Wood Works

Premium, responsive storefront and business management application for Sivasakthi Wood Works, Ayyalur – Trichy Main Road, Tamil Nadu, India. Includes catalog, COD orders, authentication, quotes, contact, reviews, gallery, and role-protected administration backed by Supabase.

## Stack
React, Vite, JavaScript, React Router, Supabase Auth/PostgreSQL/Storage, plain CSS. Payments are Cash on Delivery only; no payment provider is integrated.

## Install and run
1. Install Node.js 20.19+ (Vite 7 requirement).
2. Run `npm install`.
3. Copy `.env.example` to `.env.local` and set your Supabase project URL and publishable/anon key.
4. Apply `supabase/migrations/20260930000000_initial.sql` in Supabase SQL Editor (or Supabase CLI).
5. Create a public Storage bucket named `woodwork-media`; the migration installs its policies.
6. Run `npm run dev`, then open the local Vite URL.
7. Run `npm run build`; use `npm run preview` to preview the production bundle.

Without Supabase credentials, the public UI shows an explicit configuration state and does not pretend data or writes succeeded. Replace the curated visual placeholders with business-approved product imagery.

## Supabase setup
Create a Supabase project and configure Authentication email sign-in and redirect URLs for local and deployed origins. SQL creates profiles, catalog, cart, wishlist, COD orders, enquiries, contact messages, gallery and review tables, indexes, timestamps, triggers and RLS policies. Public users can read active products/categories/gallery and approved reviews; authenticated customers can access only their own records; administrator policies rely on `profiles.role = 'admin'` and must not be replaced by frontend checks. The browser only uses the publishable key. Never put a service-role key in Vite environment variables.

## Admin setup
Sign up a normal account first. Promote its profile to admin only from the Supabase SQL Editor using the account UUID from Authentication → Users. Example: `update public.profiles set role = 'admin' where id = '<auth-user-uuid>';`. Never ship admin credentials in source. Admin routes also check the profile role; all privileged database actions are enforced by RLS.

## Storage
The `woodwork-media` bucket is public for storefront image delivery. Policies restrict uploads, updates, and deletes to authenticated admins. Quote uploads are optional and must use this bucket. Review bucket size/type limits in the Supabase dashboard before production use.

## Deployment to Vercel
Import the repository, set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` in project environment variables, deploy, and add the deployed origin to Supabase Auth redirect URLs. `vercel.json` handles SPA routes. Vite variables are public by design; do not add service-role secrets.
See [DEPLOY_TO_VERCEL.md](DEPLOY_TO_VERCEL.md) for this repository's import and environment-variable setup.

## Production checklist
Set legal/privacy/return policies, verify business contact/map/WhatsApp details, add real product/gallery images, tune storage limits and email templates, verify RLS with separate user/admin accounts, enable backups, and test order workflows before accepting live customers. COD order rows are inserted with the authenticated user's ID; authoritative totals and inventory should be hardened with a trusted database function before high-volume production. The COD flow has an atomic server-side database function that calculates totals from current product prices and updates stock. Confirm your delivery/pricing business rules before taking live orders. No fake reviews or business credentials are seeded.
