# PropertyWorks Supabase backend

This folder contains the production database design for PropertyWorks.

Planned live stack:
- GitHub Pages: web/PWA hosting
- Supabase Auth: owner, tenant, contractor accounts
- Supabase Postgres: portfolio, accounting, marketplace, notifications
- Supabase Storage: private maintenance photos and property documents
- Supabase Realtime / Edge Functions: event-driven notifications and workflow automation

## Security
Every public data table has Row Level Security enabled. Tenant rows are scoped to the tenant's assigned property; contractor bids are scoped to the contractor and the owner of the job; owner financial tables are owner-only.

## Next deployment step
Create the live Supabase project, apply the schema, create private storage buckets, configure redirect URLs for PropertyWorks, and connect the public/publishable client key to the frontend. Never expose a service-role key in the browser.
