# System Requirements Specification Format

## Purpose

A compact, machine-parseable format for expressing system requirements. Designed to guide an LLM in extracting requirements from an existing application's codebase, documentation, or runtime behaviour.

---

## Requirement Schema

Each requirement is expressed as a YAML block:

```yaml
- id: <CATEGORY>-<NUMBER>          # Unique identifier
  type: <functional|non-functional|constraint|interface>
  priority: <must|should|could|wont> # MoSCoW
  summary: <one-line description>
  detail: <expanded description, optional>
  accepts: [<acceptance criteria>]   # Testable conditions
  depends: [<id references>]         # Other requirement IDs
  tags: [<domain tags>]              # For grouping/filtering
```

### Field Rules

| Field     | Required | Notes |
|-----------|----------|-------|
| id        | ✓ | Format: `CATEGORY-NNN`. Categories: `AUTH`, `DATA`, `UI`, `API`, `PERF`, `SEC`, `INT`, `BIZ`, `INF` |
| type      | ✓ | `functional` = what the system does. `non-functional` = quality attribute. `constraint` = imposed limitation. `interface` = integration point. |
| priority  | ✓ | Use MoSCoW. Default `should` if uncertain. |
| summary   | ✓ | Max ~120 chars. Use active voice: "System shall..." or "User can..." |
| detail    |   | Only when summary is insufficient. Keep under 3 sentences. |
| accepts   | ✓ | List of testable pass/fail statements. Min 1. |
| depends   |   | List requirement IDs this depends on. Omit if none. |
| tags      |   | Freeform. Use for domain grouping (e.g., `billing`, `onboarding`). |

---

## Categories Reference

| Code  | Domain                  | Examples |
|-------|-------------------------|----------|
| AUTH  | Authentication & AuthZ  | Login, roles, permissions, SSO |
| DATA  | Data & persistence      | CRUD, validation, schema, migrations |
| UI    | User interface          | Pages, forms, navigation, responsiveness |
| API   | API contracts           | Endpoints, payloads, versioning |
| PERF  | Performance             | Latency, throughput, caching |
| SEC   | Security                | Encryption, audit, input sanitisation |
| INT   | Integrations            | Third-party services, webhooks, imports/exports |
| BIZ   | Business rules          | Workflows, calculations, policies |
| INF   | Infrastructure          | Deployment, scaling, monitoring, config |

---

## Examples

### Functional — Authentication

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
```

### Functional — Data

```yaml
- id: DATA-001
  type: functional
  priority: must
  summary: System shall store employee records with name, email, role, and department
  accepts:
    - Record created with all required fields returns 201
    - Missing required field returns 422 with field-level errors
    - Email must be unique per tenant; duplicate returns 409
  depends: [AUTH-001]
  tags: [employee-management]
```

### Functional — Business Rule

```yaml
- id: BIZ-001
  type: functional
  priority: must
  summary: System calculates performance score as weighted average of competency ratings
  detail: >
    Each competency has a weight (0.0–1.0). Weights per review template must sum to 1.0.
    Score = Σ(rating × weight) rounded to 1 decimal place.
  accepts:
    - Score computed correctly for 1, 5, and 20 competencies
    - Weights not summing to 1.0 produce a validation error before save
    - Null ratings are excluded from calculation; score adjusts denominator
  tags: [reviews, scoring]
```

### Non-Functional — Performance

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
```

### Constraint

```yaml
- id: INF-001
  type: constraint
  priority: must
  summary: System shall run on Google Cloud Platform using managed services
  accepts:
    - All compute runs on Cloud Run or GKE
    - Database is Cloud SQL (PostgreSQL)
    - No vendor-specific features that prevent migration within 6 months
  tags: [infrastructure, cloud]
```

### Interface — Integration

```yaml
- id: INT-001
  type: interface
  priority: should
  summary: System imports employee data from CSV files
  accepts:
    - CSV with headers matching template imports successfully
    - Rows with validation errors are skipped and reported in a summary
    - Import of 10,000 rows completes within 60 seconds
  depends: [DATA-001]
  tags: [import, employee-management]
```

### Security

```yaml
- id: SEC-001
  type: non-functional
  priority: must
  summary: All API endpoints require authentication except health check
  accepts:
    - Unauthenticated request to protected endpoint returns 401
    - Expired token returns 401 with "token_expired" error code
    - Health endpoint (/health) returns 200 without credentials
  depends: [AUTH-001]
  tags: [api, security]
```

---

## LLM Extraction Prompt Template

Use the following prompt (or adapt it) to extract requirements from an existing application:

```
You are a senior systems analyst. Extract system requirements from the provided
application source in the YAML format defined below.

RULES:
1. One requirement per distinct behaviour or quality attribute. Do not combine.
2. Infer priority from usage patterns: error handling + validation = must;
   cosmetic or convenience features = could.
3. Write acceptance criteria as testable pass/fail statements.
4. Use the category codes: AUTH, DATA, UI, API, PERF, SEC, INT, BIZ, INF.
5. Assign sequential IDs per category (AUTH-001, AUTH-002, ...).
6. Add depends references when one requirement clearly relies on another.
7. If uncertain about a detail, state the requirement as observed and add
   a comment: `# UNCERTAIN: <reason>`.
8. Group output by category.

FORMAT:
<paste the requirement schema from above>

APPLICATION SOURCE:
<paste code, docs, or describe the application>
```

---

## Conventions

- **One behaviour = one requirement.** Don't combine "user can create and delete records" into one entry.
- **Observable, not implementation.** Write "System validates email format" not "System uses regex `^[a-z]...`".
- **Tenant-aware by default.** If multi-tenant, state isolation as a requirement (e.g., `SEC-002: Data is isolated per tenant`).
- **Version the spec.** Track changes in git. Use requirement IDs as stable references.
