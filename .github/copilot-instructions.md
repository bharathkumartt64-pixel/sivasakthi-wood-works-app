# Sivasakthi Wood Works — workspace guidance

- Frontend: React, Vite, JavaScript, React Router, Supabase JS, plain CSS.
- Backend schema, Row Level Security, storage policies, and order RPC live in `supabase/migrations/`.
- Only use public Supabase URL/publishable key in browser code; never expose service-role keys.
- Payments are Cash on Delivery only. Do not invent business contact details, credentials, reviews, or claims.
- Run `npm.cmd run build` on Windows to validate production output; use the `.cmd` shim if PowerShell blocks `npm.ps1`.
- Local setup and deployment guidance is in `README.md`.

## Project setup status

- [x] Requirements clarified from the supplied specification.
- [x] React/Vite project scaffolded in the current workspace.
- [x] Responsive storefront, account, commerce and admin flows implemented.
- [x] Supabase schema, RLS, storage policies and COD order RPC added.
- [x] Dependencies installed; production build validation in progress.
- [x] No additional extensions required.
- [x] Vercel SPA routing and project README added.
