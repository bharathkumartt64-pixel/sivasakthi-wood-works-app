# Deploy this existing project to Vercel

The existing project has been pushed to https://github.com/bharathkumartt64-pixel/Sivasakthi-Wood-Works on the `master` branch. `.env.local` is excluded by `.gitignore` and was not pushed.

To deploy without changing the application:

1. In Vercel, choose **Add New → Project**, import `bharathkumartt64-pixel/Sivasakthi-Wood-Works`, and use:
   - Framework preset: Vite (or Other)
   - Build command: `npm run build`
   - Output directory: `dist`
   - Install command: `npm install`
2. In the Vercel project’s **Settings → Environment Variables**, add these for Production (and Preview/Development as desired):
   - `VITE_SUPABASE_URL` — your Supabase project URL
   - `VITE_SUPABASE_PUBLISHABLE_KEY` — your Supabase publishable key

   Never add a Supabase service-role or secret key to frontend environment variables.
3. Deploy. Then add the resulting Vercel domain to Supabase **Authentication → URL Configuration → Redirect URLs**, save, and redeploy if environment values changed.
4. Open the deployment URL and check product pages and sign-in. Use real test accounts for authenticated flows. Do not place production orders just as a deployment check.
