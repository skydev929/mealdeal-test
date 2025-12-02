<!--
Guidance for AI coding agents working on the MealDeal (vite_react_shadcn_ts) repo.
Keep this file concise (~20-50 lines). Only include discoverable, actionable patterns.
-->

# Copilot instructions — MealDeal

Quick context
- Frontend: Vite + React + TypeScript + shadcn-ui + Tailwind.
- Backend: Supabase (database + Auth + Edge Functions). Repo includes one edge function: `supabase/functions/import-csv`.
- Purpose: Recipe discovery using supermarket offers; admin UI for CSV import and DB viewing.

What to change and why
- Frontend edits usually touch `src/` (pages, components, hooks). Keep types in sync with `src/integrations/supabase/types.ts` when changing DB-shaped data.
- Admin features rely on `useAdminAuth` (`src/hooks/useAdminAuth.ts`) — preserve role checks and redirects when editing admin pages.

Key files to reference (examples)
- Supabase client & keys: `src/integrations/supabase/client.ts` (contains VITE-style publishable key; do not publish service-role keys here).
- Admin auth hook: `src/hooks/useAdminAuth.ts` (checks `user_profiles` and `user_roles`).
- Admin pages: `src/pages/AdminDashboard.tsx`, `src/pages/AdminLogin.tsx`.
- CSV import edge function: `supabase/functions/import-csv/index.ts` — important for bulk imports and dry-run flow.
- Migrations: `supabase/migrations/*` and DB helper functions referenced in `ADMIN_SETUP.md` and `DEPLOYMENT.md`.

Build / dev / test commands
- Install and dev: `npm i` then `npm run dev` (runs Vite). Built artifacts: `npm run build` and `npm run preview`.
- Lint: `npm run lint` (eslint configured).
- Supabase functions: use Supabase CLI externally; see `DEPLOYMENT.md` for `supabase functions deploy` and `supabase db push` commands.

Conventions & patterns
- Data flow: frontend calls Supabase directly via `supabase` client instance. Keep network logic in `src/integrations/supabase/*` or `src/hooks/*`.
- Auth: uses Supabase Auth; admin gating is done by checking `user_profiles` + `user_roles` in `useAdminAuth`. Changing auth behavior requires updating both hook and any RLS policies in Supabase.
- CSV import: edge function expects multipart form with `file`, `type`, `dryRun`; it maps `type` to DB tables via `getTableName`/`getConflictColumn`.
- IDs: CSV import maps external ids (e.g., `chain_id`, `store_id`) into internal `id` columns. Preserve that mapping when changing schemas.

Safety & secrets
- The repo contains a publishable anon key in `src/integrations/supabase/client.ts`. Never add service-role keys or other secrets to source. For edge functions and deployment set secrets in Supabase dashboard or environment variables.

Small examples (use when editing code)
- Add a new admin-only page: import `useAdminAuth` and follow `AdminDashboard.tsx` pattern (show loader while `loading`, redirect if not admin).
- To call the import function from code or tests, POST multipart to the function endpoint; include `dryRun=true` to test.

What NOT to do
- Don't store long-lived service keys in repo files. Don't bypass `useAdminAuth` checks for admin UI.

When in doubt
- Read `ADMIN_SETUP.md` and `DEPLOYMENT.md` before changing admin/auth or deployment behavior. Check migrations in `supabase/migrations` and edge function in `supabase/functions/import-csv`.

If you need more context
- Ask for the Supabase schema (`src/integrations/supabase/types.ts` is the first place to look) or for RLS policies in the Supabase Dashboard.

Please review this draft and tell me any missing details to add or any section you want expanded.
