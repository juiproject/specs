---
name: spec-writer
description: "Extract, write, and manage system requirements in a structured YAML format, and synchronize them with the requirements database. Use this skill when the user asks to: extract requirements from code or documentation, write or draft system requirements, review or audit an existing requirements spec, reverse-engineer what an application does into formal requirements, or create a requirements document from a codebase, API, UI, or conversation. Also trigger when the user mentions extract requirements, system spec, functional spec, or asks what does this system do about a codebase. For querying, browsing, or editing existing requirements in the database, use the req skill instead."
---

# Spec Writer

Extract system requirements from application source code, documentation, APIs, or runtime
behaviour and express them in a compact, structured YAML format.

## Requirement Schema

Every requirement is a YAML block with these fields:

```yaml
- id: <CATEGORY>-<NNN>              # Unique identifier
  type: <functional|non-functional|constraint|interface>
  priority: <must|should|could|wont> # MoSCoW
  summary: <one-line, max ~120 chars, active voice>
  detail: <optional, max 3 sentences>
  accepts: [<testable pass/fail statements>]  # Min 1
  depends: [<requirement IDs>]       # Optional
  tags: [<freeform labels>]          # Optional
  domains: [<domain references>]     # Optional
```

### Field Rules

| Field    | Req? | Rule |
|----------|------|------|
| id       | ✓    | `CATEGORY-NNN`. Sequential per category. |
| type     | ✓    | `functional` = behaviour. `non-functional` = quality. `constraint` = limitation. `interface` = integration. |
| priority | ✓    | MoSCoW. Default `should` if uncertain. |
| summary  | ✓    | Active voice: "System shall..." or "User can...". Max ~120 chars. |
| detail   |      | Only when summary is insufficient. |
| accepts  | ✓    | Testable pass/fail. Min 1 criterion. |
| depends  |      | IDs this requirement relies on. |
| tags     |      | Freeform labels for grouping. |
| domains  |      | Domain references (must exist in DB). See `req domain list`. |

### Categories

| Code | Domain | Examples |
|------|--------|----------|
| AUTH | Authentication & authorization | Login, roles, permissions, SSO |
| DATA | Data & persistence | CRUD, validation, schema, migrations |
| UI   | User interface | Pages, forms, navigation, responsiveness |
| API  | API contracts | Endpoints, payloads, versioning |
| PERF | Performance | Latency, throughput, caching |
| SEC  | Security | Encryption, audit, input sanitisation |
| INT  | Integrations | Third-party services, webhooks, imports/exports |
| BIZ  | Business rules | Workflows, calculations, policies |
| INF  | Infrastructure | Deployment, scaling, monitoring, config |

Add custom categories if the domain demands it (e.g., `SKL` for skills, `REV` for reviews).
Document any custom categories at the top of the output.

## Extraction Workflow

When extracting requirements from an existing application:

1. **Scope** — Ask the user what to extract from (whole app, module, API layer, etc.)
   and what format the source is in (code files, docs, running app, conversation).
2. **Ingest** — Read the source material. For code, focus on:
   - Controllers/routes → API requirements
   - Validation logic → DATA requirements
   - Auth middleware/guards → AUTH and SEC requirements
   - Config/env vars → INF constraints
   - External service calls → INT requirements
   - Business logic/services → BIZ requirements
   - UI components/templates → UI requirements
   - Tests → acceptance criteria (often the best source)
3. **Draft** — Produce requirements grouped by category, sequentially numbered.
4. **Flag uncertainty** — Add `# UNCERTAIN: <reason>` comments for anything inferred
   rather than directly observed.
5. **Review** — Present to the user for validation. Expect iteration.

## Extraction Rules

1. **One behaviour = one requirement.** Never combine (e.g., "create and delete" → two reqs).
2. **Observable, not implementation.** Write "System validates email format" not
   "System uses regex `^[a-z]...`".
3. **Infer priority from evidence:**
   - Error handling + validation + tests = `must`
   - Happy-path feature with no edge-case handling = `should`
   - Cosmetic / convenience / TODO comments = `could`
4. **Acceptance criteria must be testable** — a person or machine can determine pass/fail
   without ambiguity.
5. **Add `depends`** when one requirement clearly cannot exist without another.
6. **Tenant-aware** — If multi-tenant, state isolation explicitly (e.g., `SEC-002`).

## Output Format

Output requirements as a single YAML document grouped by category with category headers:

```yaml
# === AUTH: Authentication & Authorization ===

- id: AUTH-001
  type: functional
  priority: must
  summary: User can sign in with email and password
  accepts:
    - Valid credentials return a session token with 200 OK
    - Invalid credentials return 401 with generic error message
    - Account locked after 5 consecutive failed attempts within 15 minutes
  tags: [onboarding, security]

# === BIZ: Business Rules ===

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
    - Null ratings are excluded; score adjusts denominator
  tags: [reviews, scoring]
  domains: [reviews]
```

Save the output as a `.yaml` file (not `.md`) so it remains machine-parseable.

## Database Synchronization

When extracting requirements and the user wants them saved to the database (or by
default after extraction), follow this sync workflow using the `specs/req` CLI.

### Pre-extraction: Check existing state

1. Run `specs/req list` to see what already exists in the database.
   If the database does not exist, run `specs/req restore` first.
2. Run `specs/req list --category <CAT>` for each category you expect to extract,
   to get specific existing IDs and summaries.

### Post-extraction: Diff and sync

After drafting extracted requirements in YAML:

1. **Compare with existing** — For each extracted requirement, check if a semantically
   equivalent requirement already exists (same category, similar summary). Use
   `specs/req show <ID>` to inspect candidates.

2. **Classify each requirement** as one of:
   - **New**: No equivalent exists. Will be added.
   - **Update**: An equivalent exists but fields differ (priority, detail, etc.).
     Will be edited.
   - **Unchanged**: An equivalent exists with matching content. Will be skipped.

3. **Present the diff** to the user before making changes:
   ```
   New requirements (will add):
     - AUTH-024: <summary>
     - BIZ-007: <summary>

   Updates (will edit):
     - AUTH-005: priority should -> must
     - AUTH-005: summary updated

   Unchanged (will skip):
     - AUTH-001, AUTH-002, AUTH-003
   ```

4. **Apply changes** after user approval:
   - **New**: Pipe the YAML block to `specs/req add` for each new requirement:
     ```bash
     specs/req add <<'YAML'
     - id: AUTH-024
       type: constraint
       priority: must
       summary: Account status cannot revert to PENDING
       accepts:
         - Calling changeStatus(PENDING) on a non-PENDING account has no effect
       tags: [status]
       domains: [auth]
     YAML
     ```
     For multiple requirements at once, write a YAML file and run `specs/req import <file.yaml>`.
   - **Updates**: Pipe updated YAML to `specs/req update <ID>` (supports all fields
     including acceptance criteria, tags, and domains):
     ```bash
     specs/req show AUTH-005 --format yaml | sed 's/should/must/' | specs/req update AUTH-005
     ```
     For single scalar fields, use `specs/req edit <ID> <field> <value>`.
   - Run `specs/req snapshot` after all changes to update the git-versioned files.

### Standalone mode

If the user explicitly asks for YAML output only (no database sync), follow the
original extraction workflow and save as a `.yaml` file without importing.

## Writing Requirements From Scratch

When the user wants to *write* requirements (not extract):

1. Ask about the domain, users, and high-level capabilities.
2. Draft requirements using the schema above.
3. Start with `must` priorities — the minimum viable system.
4. Layer in `should` and `could` after the core is agreed.
5. Cross-reference with `depends` to show requirement relationships.

## Reviewing an Existing Spec

When reviewing a requirements document:

- Check each requirement against the field rules above.
- Flag missing acceptance criteria.
- Flag combined requirements that should be split.
- Flag implementation-leaking summaries.
- Flag orphan dependencies (referenced IDs that don't exist).
- Suggest missing categories (e.g., no SEC requirements = red flag).

## Reference

For detailed examples of each category and edge cases, see `examples.md`.
