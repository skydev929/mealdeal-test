# Technical Architecture

## System Overview

MealDeal is built as a modern single-page application (SPA) with a serverless backend architecture. The application uses React for the frontend and Supabase (PostgreSQL) for the backend, providing a scalable and cost-effective solution.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    User Browser                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │         React Application (Vite)                  │   │
│  │  - React Router (Client-side routing)             │   │
│  │  - TanStack Query (Data fetching/caching)        │   │
│  │  - React Hooks (State management)                 │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTPS
                       │ REST API / WebSocket
┌──────────────────────┴──────────────────────────────────┐
│                    Supabase Platform                     │
│  ┌──────────────────────────────────────────────────┐   │
│  │         PostgreSQL Database                       │   │
│  │  - Tables: dishes, ingredients, offers, etc.      │   │
│  │  - Functions: calculate_dish_price()             │   │
│  │  - RLS Policies: Row-level security              │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │         Authentication Service                    │   │
│  │  - Email/Password auth                           │   │
│  │  - Session management                            │   │
│  │  - User profiles                                │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │         Edge Functions (Deno)                    │   │
│  │  - import-csv: CSV processing                   │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

## Frontend Architecture

### Component Hierarchy

```
App
├── QueryClientProvider (TanStack Query)
├── TooltipProvider
├── BrowserRouter
│   ├── Routes
│   │   ├── /login → Login
│   │   ├── / → Index (RequireAuth)
│   │   ├── /dish/:dishId → DishDetail (RequireAuth)
│   │   ├── /admin/dashboard → AdminDashboard (RequireAuth, adminOnly)
│   │   ├── /privacy → Privacy
│   │   └── /terms → Terms
│   └── PrivacyBanner
└── Toaster (Notifications)
```

### State Management

**Local State (React Hooks):**
- Component-level state: `useState`
- Side effects: `useEffect`
- Form state: `react-hook-form`

**Server State (TanStack Query):**
- Data fetching and caching
- Automatic refetching
- Optimistic updates

**Authentication State:**
- Custom hook: `useAuth`
- Session management via Supabase
- Profile synchronization

### Data Flow

1. **User Action** → Component event handler
2. **API Call** → `api.ts` service method
3. **Supabase Query** → Database query via Supabase client
4. **Response** → TanStack Query cache
5. **UI Update** → React re-render

### Key Frontend Patterns

**Service Layer Pattern:**
- `src/services/api.ts` abstracts Supabase calls
- Provides type-safe API interface
- Handles error transformation

**Custom Hooks Pattern:**
- `useAuth` - Authentication logic
- `useAdminAuth` - Admin-specific auth
- `useDishPricing` - Dish pricing calculations

**Component Composition:**
- Reusable UI components (shadcn/ui)
- Page components compose smaller components
- Props drilling minimized

## Backend Architecture

### Database Architecture

**PostgreSQL (via Supabase):**
- Relational database with foreign keys
- Stored procedures for complex calculations
- Triggers for automatic updates
- Indexes for performance

**Key Design Decisions:**
- Normalized schema (3NF)
- Composite primary keys where appropriate
- Cascade deletes for data integrity
- Timestamps for audit trails

### Database Functions

**`calculate_dish_price(dish_id, user_plz)`:**
- Calculates base price from ingredient baselines
- Calculates offer price from current offers
- Handles unit conversions
- Returns pricing summary

**`convert_unit(qty, from_unit, to_unit)`:**
- Converts between compatible units
- Returns NULL for non-convertible units
- Supports: g↔kg, ml↔l, stück↔st

**Validation Functions:**
- `check_email_exists(email)`
- `check_username_exists(username)`

### Edge Functions

**`import-csv`:**
- Deno runtime
- CSV parsing and validation
- Database insertion with error handling
- Returns detailed validation results

**Function Flow:**
1. Receive FormData with CSV file
2. Parse CSV (handle quoted fields)
3. Validate each row
4. Transform data types
5. Insert/upsert into database
6. Return results and errors

### Security Architecture

**Row Level Security (RLS):**
- Policies defined per table
- User-specific data isolation
- Admin override capabilities

**Authentication:**
- Supabase Auth handles sessions
- JWT tokens for API requests
- Automatic token refresh

**Authorization:**
- Role-based access control (RBAC)
- `user_roles` table stores permissions
- Admin role for elevated access

## API Design

### RESTful Patterns

**Supabase Client:**
- Uses PostgREST for REST API
- Automatic OpenAPI generation
- Type-safe queries

**Query Patterns:**
```typescript
// Select with filters
supabase
  .from('dishes')
  .select('*')
  .eq('category', 'Main Course')
  .limit(50)

// RPC calls
supabase.rpc('calculate_dish_price', {
  _dish_id: 'D001',
  _user_plz: '10115'
})
```

### Error Handling

**Client-Side:**
- Try-catch blocks in service methods
- User-friendly error messages
- Toast notifications for errors

**Server-Side:**
- Database constraints for data integrity
- RLS policies for access control
- Edge function error responses

## Performance Optimization

### Frontend Optimizations

1. **Code Splitting:**
   - Route-based code splitting
   - Lazy loading for admin pages

2. **Caching:**
   - TanStack Query caching
   - Stale-while-revalidate pattern
   - Optimistic updates

3. **Bundle Size:**
   - Tree shaking
   - Dynamic imports
   - Vite build optimizations

### Backend Optimizations

1. **Database Indexes:**
   - Indexes on foreign keys
   - Indexes on frequently queried columns
   - Composite indexes for common queries

2. **Query Optimization:**
   - Efficient JOINs
   - Limit clauses
   - Select only needed columns

3. **Function Optimization:**
   - Stored procedures for complex calculations
   - Batch operations where possible
   - Connection pooling (Supabase handles)

## Scalability Considerations

### Current Limitations

- **Database:** Supabase free tier limits
- **Edge Functions:** Execution time limits
- **File Upload:** CSV size limits

### Scaling Strategies

1. **Database:**
   - Upgrade Supabase plan
   - Read replicas for heavy queries
   - Partition large tables

2. **Application:**
   - CDN for static assets
   - Service worker for offline support
   - Progressive Web App (PWA)

3. **Data Processing:**
   - Background jobs for price calculations
   - Queue system for CSV imports
   - Caching layer (Redis)

## Deployment Architecture

### Development Environment

- **Local:** Vite dev server (port 8080)
- **Database:** Supabase cloud (development project)
- **Hot Reload:** Fast Refresh enabled

### Production Environment

- **Frontend:** Static site hosting (Vercel, Netlify, etc.)
- **Backend:** Supabase cloud (production project)
- **CDN:** Static asset delivery
- **Environment Variables:** Secure key management

### CI/CD Pipeline (Future)

1. **Code Push** → GitHub
2. **Tests Run** → Automated testing
3. **Build** → Production build
4. **Deploy** → Hosting platform
5. **Database Migrations** → Supabase CLI

## Monitoring & Logging

### Current Monitoring

- **Supabase Dashboard:** Database metrics
- **Browser Console:** Client-side errors
- **Edge Function Logs:** Server-side errors

### Recommended Monitoring

1. **Application Performance:**
   - Response time tracking
   - Error rate monitoring
   - User session tracking

2. **Database Performance:**
   - Query execution times
   - Connection pool usage
   - Index usage statistics

3. **User Analytics:**
   - Page views
   - Feature usage
   - Conversion funnels

## Security Best Practices

### Implemented

- ✅ Row Level Security (RLS)
- ✅ Input validation (client and server)
- ✅ SQL injection prevention (parameterized queries)
- ✅ XSS prevention (React auto-escaping)
- ✅ HTTPS only (Supabase enforces)
- ✅ Secure password storage (Supabase handles)

### Recommendations

- [ ] Rate limiting for API calls
- [ ] CSRF protection
- [ ] Content Security Policy (CSP)
- [ ] Regular security audits
- [ ] Dependency vulnerability scanning

## Technology Choices Rationale

### Why React?

- **Popular:** Large ecosystem, community support
- **Component-Based:** Reusable, maintainable code
- **TypeScript Support:** Type safety
- **Performance:** Virtual DOM, efficient updates

### Why Supabase?

- **PostgreSQL:** Robust, feature-rich database
- **Built-in Auth:** Saves development time
- **Real-time:** WebSocket support (future)
- **Edge Functions:** Serverless compute
- **Free Tier:** Good for MVP

### Why Vite?

- **Fast:** Instant server start
- **HMR:** Fast hot module replacement
- **Modern:** ES modules, native ESM
- **Simple:** Minimal configuration

### Why TanStack Query?

- **Caching:** Automatic cache management
- **Background Updates:** Stale-while-revalidate
- **Optimistic Updates:** Better UX
- **Error Handling:** Built-in retry logic

## Future Architecture Improvements

1. **Microservices:** Split admin functions into separate service
2. **GraphQL:** More flexible API queries
3. **Redis Cache:** Faster price calculations
4. **Message Queue:** Async CSV processing
5. **Search Engine:** Elasticsearch for dish search
6. **CDN:** Global content delivery
7. **Monitoring:** APM tools (Sentry, Datadog)

