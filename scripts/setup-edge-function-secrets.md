# Setup Edge Function Secrets

The CSV import edge function needs the service role key to bypass RLS policies.

## Steps to Set the Secret

1. **Get your Service Role Key:**
   - Go to: https://supabase.com/dashboard/project/hvjufetqddjxtmuariwr/settings/api
   - Copy the **service_role** key (keep it secret!)

2. **Set the Secret for the Edge Function:**
   ```bash
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
   ```

   Or via Supabase Dashboard:
   - Go to: https://supabase.com/dashboard/project/hvjufetqddjxtmuariwr/functions/import-csv
   - Click on "Secrets" tab
   - Add secret: `SUPABASE_SERVICE_ROLE_KEY` with your service role key value

3. **Redeploy the Function:**
   ```bash
   supabase functions deploy import-csv
   ```

## Alternative: Use Anon Key (Less Secure)

If you don't want to use the service role key, you can:
1. Make sure RLS policies allow public inserts for admin tables
2. Or use the anon key (current fallback in code)

But using the service role key is recommended for admin operations.

