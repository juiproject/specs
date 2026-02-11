---
name: trace
description: "Inspect, manage, and verify requirements traceability between Java source code and the requirements database. Use this skill when the user asks to: check which requirements a class or method implements, mark requirements on code, verify requirement coverage, find untested requirements, confirm code meets requirements, add or remove @requirements javadoc tags, or asks about traceability between code and requirements. Also trigger when the user mentions @requirements, trace, coverage, which requirements, mark the requirements, confirm requirements, or asks does this code meet requirements or what requirements does this test."
---

# Requirements Traceability

Link Java source code to requirements using `@requirements` javadoc tags and cross-reference
with the requirements database via the `specs/trace` CLI.

## The `@requirements` tag

A javadoc tag that associates a class, method, or test with one or more requirement IDs:

```java
/**
 * @requirements AUTH-001, AUTH-003, AUTH-010
 */
```

### Scope rules

- **Implementation code** (files in `src/main/`): the tag means "implements or is constrained by" these requirements.
- **Test code** (files in `src/test/` or `src/it/`): the tag means "tests or validates" these requirements.

### Placement

Place `@requirements` after all standard javadoc tags (`@author`, `@param`, `@return`, `@throws`)
but before the closing `*/`:

```java
/**
 * Authenticates a user with email and password.
 *
 * @param email    the user's email address.
 * @param password the user's password.
 * @return the authenticated session.
 * @throws AuthException if credentials are invalid.
 * @requirements AUTH-001, AUTH-005
 */
public Session authenticate(String email, String password) throws AuthException {
```

When no existing javadoc is present, create a minimal block:

```java
/** @requirements AUTH-001 */
public void lockAccount(long userId) {
```

Or multi-line if the list is long:

```java
/**
 * @requirements AUTH-001, AUTH-003, AUTH-005, AUTH-010
 */
public class AuthenticationService {
```

## Invocation

Always invoke as `specs/trace <command>` from the project root. The database at
`specs/requirements.db` must exist for cross-reference commands. If it does not exist,
run `specs/req restore` first.

## Command Mapping

| User intent | Command |
|-------------|---------|
| Scan codebase for all tags | `specs/trace scan` |
| Show code for a requirement | `specs/trace map --req AUTH-001` |
| Show all requirement-to-code mappings | `specs/trace map` |
| Check requirements coverage | `specs/trace coverage` |
| Find orphaned tag references | `specs/trace orphans` |
| Full traceability report | `specs/trace summary` |

## Workflows

### A: Mark requirements on a class or method

When the user asks "mark the requirements this class is constrained to" or similar:

1. Read the class or method the user is referring to (from selection or file path).
2. Understand what the code does — its domain, behaviour, and constraints.
3. Run `specs/req list` (with appropriate category filters) to get active requirements.
4. For each requirement that is relevant, run `specs/req show <ID>` to confirm the match
   against the acceptance criteria.
5. Add a `@requirements` tag to the javadoc listing the matched IDs.
6. Present the mapping to the user for confirmation.

### B: Mark requirements on a test

When the user asks "mark the requirements this test tests" or similar:

1. Read the test class or method.
2. Understand what behaviour is being tested.
3. Run `specs/req list` to find matching requirements.
4. For each candidate, run `specs/req show <ID>` and compare acceptance criteria against
   what the test asserts.
5. Add a `@requirements` tag to the test method or class javadoc.
6. Present the mapping to the user for confirmation.

### C: Verify requirements are being met

When the user asks "confirm the requirements are being met by this method" or similar:

1. Read the method and its `@requirements` tag. If no tag exists, inform the user.
2. For each referenced requirement ID, run `specs/req show <ID>` to retrieve the
   acceptance criteria.
3. Analyse the code against each acceptance criterion.
4. Report which criteria are:
   - **Met** — the code clearly implements the criterion.
   - **Partially met** — some aspects are present but incomplete.
   - **Not addressed** — no evidence in this code (may be handled elsewhere).

### D: Coverage and reporting

When the user asks about coverage or traceability:

- `specs/trace coverage` — shows which requirements have code and/or tests linked.
- `specs/trace orphans` — finds tags pointing to non-existent requirements.
- `specs/trace summary` — combined report.
- `specs/trace map --req <ID>` — shows all code locations for a specific requirement.

## Conversational Examples

| User says | Action |
|-----------|--------|
| "mark the requirements this class is constrained to" | Workflow A |
| "mark the requirements this test tests" | Workflow B |
| "confirm the requirements are being met by this method" | Workflow C |
| "what requirements does this class implement?" | Read the file, look for `@requirements` tags, show them with `specs/req show` for each |
| "show requirements coverage" | Run `specs/trace coverage` |
| "what code implements AUTH-001?" | Run `specs/trace map --req AUTH-001` |
| "are there any orphaned requirement references?" | Run `specs/trace orphans` |
| "show me a traceability summary" | Run `specs/trace summary` |
| "add @requirements AUTH-001 to this class" | Verify ID exists via `specs/req show AUTH-001`, then edit the javadoc |
| "remove @requirements SEC-002 from this method" | Edit the javadoc to remove the ID |
| "which requirements have no tests?" | Run `specs/trace coverage`, report the "Not covered" and "Implementation only" sections |
| "scan for all requirement tags" | Run `specs/trace scan` |

## Tag Management Rules

When adding `@requirements` tags to code:

1. **Verify first** — run `specs/req show <ID>` for each ID to confirm it exists and is active.
2. **Preserve formatting** — do not alter existing javadoc content. Append the tag in the
   correct position.
3. **Placement** — after standard tags (`@author`, `@param`, `@return`, `@throws`), before `*/`.
4. **Minimal javadoc** — if no javadoc exists, create a minimal block with just the tag.
5. **One tag per block** — use a single `@requirements` tag with comma-separated IDs rather
   than multiple `@requirements` tags.

## Cross-references

This skill delegates to:
- `specs/trace` for code scanning and traceability reports.
- `specs/req` for database queries on specific requirements (see `.claude/skills/req/SKILL.md`).
- Direct file reading for inspecting code against requirement criteria.
