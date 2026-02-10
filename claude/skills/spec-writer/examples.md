# Requirements Examples Reference

Detailed examples for each category. Read this file when you need more examples
or when handling edge cases during extraction.

## AUTH — Authentication & Authorization

```yaml
- id: AUTH-001
  type: functional
  priority: must
  summary: User can sign in with email and password
  accepts:
    - Valid credentials return a session token with 200 OK
    - Invalid credentials return 401 with generic error message
    - Account locked after 5 consecutive failed attempts within 15 minutes
  tags: [onboarding, security]

- id: AUTH-002
  type: functional
  priority: must
  summary: System enforces role-based access control with admin, manager, and member roles
  accepts:
    - Admin can access all tenant resources
    - Manager can access team-scoped resources only
    - Member can access own resources only
    - Accessing a forbidden resource returns 403
  tags: [authorization]

- id: AUTH-003
  type: functional
  priority: should
  summary: User can authenticate via SSO using SAML 2.0
  detail: Enterprise tenants can configure a SAML IdP. SSO users skip local password auth.
  accepts:
    - SAML assertion with valid signature creates a session
    - Invalid or expired assertion returns 401
    - SSO-enabled tenant disables password login for non-admin users
  depends: [AUTH-001]
  tags: [enterprise, sso]
```

## DATA — Data & Persistence

```yaml
- id: DATA-001
  type: functional
  priority: must
  summary: System stores employee records with name, email, role, and department
  accepts:
    - Record created with all required fields returns 201
    - Missing required field returns 422 with field-level errors
    - Email must be unique per tenant; duplicate returns 409
  depends: [AUTH-001]
  tags: [employee-management]

- id: DATA-002
  type: functional
  priority: must
  summary: System supports soft-delete for all core entities
  detail: Deleted records are marked inactive, excluded from queries by default, and recoverable within 30 days.
  accepts:
    - Deleted record not returned in standard list queries
    - Deleted record retrievable via admin restore endpoint
    - Records older than 30 days are permanently purged by scheduled job
  tags: [data-lifecycle]

- id: DATA-003
  type: functional
  priority: should
  summary: System validates email format on all email fields
  accepts:
    - Well-formed email accepted (user@domain.tld)
    - Malformed email rejected with 422 and descriptive message
    - Empty string rejected; null accepted only if field is optional
  tags: [validation]
```

## UI — User Interface

```yaml
- id: UI-001
  type: functional
  priority: must
  summary: Dashboard displays summary metrics for current review cycle
  accepts:
    - Shows completion rate, average score, and outstanding reviews
    - Metrics update within 5 seconds of underlying data change
    - Empty state shown when no review cycle is active
  tags: [dashboard, reviews]

- id: UI-002
  type: non-functional
  priority: should
  summary: Application is responsive across desktop, tablet, and mobile breakpoints
  accepts:
    - Usable at 320px, 768px, and 1280px viewport widths
    - No horizontal scroll at any breakpoint
    - Touch targets are at least 44x44px on mobile
  tags: [responsive, accessibility]
```

## API — API Contracts

```yaml
- id: API-001
  type: interface
  priority: must
  summary: REST API uses JSON request/response bodies with consistent error format
  detail: >
    Errors return {code, message, details[]} where details contains field-level errors
    for validation failures.
  accepts:
    - All endpoints return Content-Type application/json
    - 4xx errors include code and message fields
    - 422 errors include details array with field, message pairs
  tags: [api-design]

- id: API-002
  type: interface
  priority: should
  summary: API supports cursor-based pagination on all list endpoints
  accepts:
    - Response includes next_cursor and has_more fields
    - Passing cursor parameter returns next page
    - Default page size is 25; max is 100
    - Invalid cursor returns 400
  tags: [api-design, pagination]
```

## PERF — Performance

```yaml
- id: PERF-001
  type: non-functional
  priority: should
  summary: API responses complete within 500ms at p95 under normal load
  detail: Normal load defined as ≤100 concurrent users per tenant.
  accepts:
    - p95 latency ≤ 500ms measured over 5-minute window
    - No endpoint exceeds 2s at p99
  tags: [api, sla]

- id: PERF-002
  type: non-functional
  priority: could
  summary: Dashboard page loads within 2 seconds on 4G connection
  accepts:
    - First contentful paint ≤ 1.5s
    - Time to interactive ≤ 2s
    - Lighthouse performance score ≥ 80
  tags: [frontend, sla]
```

## SEC — Security

```yaml
- id: SEC-001
  type: non-functional
  priority: must
  summary: All API endpoints require authentication except health check
  accepts:
    - Unauthenticated request to protected endpoint returns 401
    - Expired token returns 401 with "token_expired" error code
    - /health returns 200 without credentials
  depends: [AUTH-001]
  tags: [api, security]

- id: SEC-002
  type: non-functional
  priority: must
  summary: Data is isolated per tenant; no cross-tenant data leakage
  accepts:
    - Query with tenant A token returns zero records from tenant B
    - Direct ID access to tenant B resource returns 403
    - Database queries include tenant_id filter at repository layer
  tags: [multi-tenancy, security]

- id: SEC-003
  type: non-functional
  priority: must
  summary: All data in transit encrypted via TLS 1.2+
  accepts:
    - HTTP requests redirected to HTTPS
    - TLS 1.0 and 1.1 connections rejected
    - Certificate valid and not self-signed in production
  tags: [encryption, compliance]
```

## INT — Integrations

```yaml
- id: INT-001
  type: interface
  priority: should
  summary: System imports employee data from CSV files
  accepts:
    - CSV with headers matching template imports successfully
    - Rows with validation errors are skipped and reported in summary
    - Import of 10,000 rows completes within 60 seconds
  depends: [DATA-001]
  tags: [import, employee-management]

- id: INT-002
  type: interface
  priority: could
  summary: System sends webhook notifications on review completion events
  detail: Webhook URL configured per tenant. Payloads signed with HMAC-SHA256.
  accepts:
    - POST sent to configured URL within 30 seconds of event
    - Payload includes event type, timestamp, and resource ID
    - Failed deliveries retried 3 times with exponential backoff
  tags: [webhooks, events]
```

## BIZ — Business Rules

```yaml
- id: BIZ-001
  type: functional
  priority: must
  summary: System calculates performance score as weighted average of competency ratings
  detail: >
    Each competency has a weight (0.0–1.0). Weights per template must sum to 1.0.
    Score = Σ(rating × weight) rounded to 1 decimal place.
  accepts:
    - Score computed correctly for 1, 5, and 20 competencies
    - Weights not summing to 1.0 produce a validation error before save
    - Null ratings excluded from calculation; score adjusts denominator
  tags: [reviews, scoring]

- id: BIZ-002
  type: functional
  priority: must
  summary: Review cycle transitions through draft → active → closed states
  accepts:
    - New cycle starts in draft state
    - Activating a cycle sends notifications to all participants
    - Closing a cycle locks all reviews from further editing
    - Cannot revert from closed to active
  tags: [reviews, lifecycle]
```

## INF — Infrastructure

```yaml
- id: INF-001
  type: constraint
  priority: must
  summary: System runs on Google Cloud Platform using managed services
  accepts:
    - All compute runs on Cloud Run or GKE
    - Database is Cloud SQL (PostgreSQL)
    - No vendor lock-in features preventing migration within 6 months
  tags: [infrastructure, cloud]

- id: INF-002
  type: non-functional
  priority: should
  summary: System achieves 99.9% uptime measured monthly
  accepts:
    - Monthly downtime does not exceed 43 minutes
    - Planned maintenance windows excluded from SLA
    - Uptime measured via external synthetic monitoring
  tags: [sla, reliability]
```

## Edge Cases & Patterns

### UNCERTAIN flag
When inferring a requirement from indirect evidence (e.g., a config value with no documentation):
```yaml
- id: PERF-003
  type: non-functional
  priority: should
  summary: System caches API responses for 60 seconds
  accepts:
    - Repeated identical request within 60s returns cached response
    - Cache invalidated on write operations to the same resource
  tags: [caching]
  # UNCERTAIN: TTL inferred from config value `CACHE_TTL=60`; may be environment-specific
```

### Negative requirements
Sometimes it's important to state what the system must NOT do:
```yaml
- id: SEC-004
  type: constraint
  priority: must
  summary: System shall not log or persist raw passwords or authentication tokens
  accepts:
    - Password fields masked in all log output
    - Token values truncated to last 4 characters in audit logs
    - No plaintext credentials in database or file storage
  tags: [security, compliance]
```

### Derived requirements
When one business rule implies technical requirements:
```yaml
- id: BIZ-003
  type: functional
  priority: must
  summary: System enforces that only one review cycle per team can be active at a time
  accepts:
    - Activating a second cycle for the same team returns 409
    - Different teams can have concurrent active cycles
  depends: [BIZ-002]
  tags: [reviews, constraints]
```
