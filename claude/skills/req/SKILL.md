---
name: req
description: "Query, browse, and manage the requirements database using the specs/req CLI. Use this skill when the user asks to: list, show, search, filter, edit, delete, tag, manage domains, or get statistics about requirements. Also trigger when the user references a requirement ID (like AUTH-001, BIZ-003), asks about requirement status or priority, asks to change a requirement field, asks about domains, or asks what requirements exist for a category, module, or domain. Trigger for req stats, req check, quality check, show requirements, find requirements, domain, or any conversational query about requirements."
---

# Requirements Manager

Interact with the requirements database via the `specs/req` CLI. Map natural-language
queries to CLI commands executed with the Bash tool.

## Invocation

Always invoke as `specs/req <command>` from the project root. The database is at
`specs/requirements.db`. If the database does not exist, run `specs/req restore`
first (the YAML snapshots in `specs/snapshots/` are the git-versioned source of truth).

## Command Mapping

| User intent | Command |
|-------------|---------|
| List/search requirements | `specs/req list [--module M] [--priority P] [--category C] [--tag T] [--type T] [--status S]` |
| Show one requirement | `specs/req show <ID> [--module M]` |
| Show as YAML (for update) | `specs/req show <ID> --format yaml [--module M]` |
| Update from YAML | `specs/req update <ID> [--module M] <<'EOF'` ... `EOF` |
| Edit a single field | `specs/req edit <ID> <field> <value> [--module M]` |
| Add/remove a tag | `specs/req tag <ID> add\|rm <tag> [--module M]` |
| Add/remove a dependency | `specs/req depend <ID> add\|rm <target_id> [--module M]` |
| Create a domain | `specs/req domain add <ref> <name> [desc] [--module M]` |
| List domains | `specs/req domain list [--module M]` |
| Remove a domain | `specs/req domain rm <ref> [--module M]` |
| Assign/unassign domain | `specs/req domain <ID> add\|rm <ref> [--module M]` |
| Soft-delete a requirement | `specs/req rm <ID> [--module M]` |
| Permanently purge old deletes | `specs/req purge <days>` |
| Get statistics | `specs/req stats [--module M]` |
| Run quality checks | `specs/req check [--module M]` |
| Export requirements | `specs/req export [filters...] [--format yaml\|csv]` |
| List modules | `specs/req module list` |
| Add (interactive or YAML stdin) | `specs/req add [module]` |
| Import from YAML file | `specs/req import [module] <file.yaml>` |
| Approve a requirement | `specs/req approve <ID> [--module M]` |
| Revert revised to approved | `specs/req revert <ID> [--module M]` |
| Withdraw approval | `specs/req withdraw <ID> [--module M]` |
| Diff approved vs revised | `specs/req diff <ID> [--module M]` |
| Show approved version | `specs/req show <ID> --approved [--module M]` |
| List by approval status | `specs/req list --approval <proposed\|approved\|revised>` |
| Snapshot for git | `specs/req snapshot` (runs automatically via git pre-commit hook — do not run manually) |
| Restore from snapshots | `specs/req restore` |

## Creating Requirements

The `add` command supports two modes:

1. **Interactive** — prompts for each field when run in a terminal.
2. **YAML via stdin** — when stdin is piped, parses a single requirement YAML block.

To create a requirement non-interactively, pipe YAML to `add`:

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

The `id` field provides the category; the sequence number is auto-assigned.

To import multiple requirements at once, use `import` with a YAML file:

```bash
specs/req import /tmp/new-reqs.yaml
```

Both `add` (stdin) and `import` (file) support the `domains:` field to create
domain associations on import.

## Conversational Examples

| User says | Maps to |
|-----------|---------|
| "show me all auth requirements" | `specs/req list --category AUTH` |
| "show me AUTH-001" | `specs/req show AUTH-001` |
| "change the summary of AUTH-001 to XYZ" | `specs/req edit AUTH-001 summary "XYZ"` |
| "set AUTH-001 priority to must" | `specs/req edit AUTH-001 priority must` |
| "what are the must-have requirements?" | `specs/req list --priority must` |
| "tag AUTH-001 with security" | `specs/req tag AUTH-001 add security` |
| "remove the onboarding tag from BIZ-003" | `specs/req tag BIZ-003 rm onboarding` |
| "how many requirements do we have?" | `specs/req stats` |
| "are there any quality issues?" | `specs/req check` |
| "list all security requirements" | `specs/req list --category SEC` |
| "show deleted requirements" | `specs/req list --status deleted` |
| "export everything as CSV" | `specs/req export --format csv` |
| "make AUTH-001 depend on SEC-001" | `specs/req depend AUTH-001 add SEC-001` |
| "delete BIZ-002" | `specs/req rm BIZ-002` |
| "show AUTH-005 as yaml" | `specs/req show AUTH-005 --format yaml` |
| "change the acceptance criteria on AUTH-005" | `specs/req show AUTH-005 --format yaml`, edit, pipe to `specs/req update AUTH-005` |
| "create a domain for email" | `specs/req domain add email-service "Email Service" "Email delivery and templating"` |
| "list all domains" | `specs/req domain list` |
| "assign BIZ-007 to the org domain" | `specs/req domain BIZ-007 add org` |
| "remove BIZ-007 from the org domain" | `specs/req domain BIZ-007 rm org` |
| "show requirements in the org domain" | `specs/req list --domain org` |
| "export org domain as yaml" | `specs/req export --domain org` |
| "delete the email-service domain" | `specs/req domain rm email-service` |
| "approve AUTH-001" | `specs/req approve AUTH-001` |
| "revert AUTH-005 to approved" | `specs/req revert AUTH-005` |
| "withdraw approval on BIZ-003" | `specs/req withdraw BIZ-003` |
| "show diff for AUTH-001" | `specs/req diff AUTH-001` |
| "show the approved version of AUTH-001" | `specs/req show AUTH-001 --approved` |
| "list all proposed requirements" | `specs/req list --approval proposed` |
| "which requirements need re-approval?" | `specs/req list --approval revised` |

### Category name mapping

When the user refers to a category by its domain name, map to the code:

| User says | Category code |
|-----------|---------------|
| authentication, login, auth | `AUTH` |
| data, validation, persistence | `DATA` |
| user interface, UI, forms, pages | `UI` |
| API, endpoints, REST | `API` |
| performance, latency, speed | `PERF` |
| security, encryption, CSRF | `SEC` |
| integration, SSO, third-party | `INT` |
| business rules, workflow, policy | `BIZ` |
| infrastructure, deployment, config | `INF` |

## Filter Values

| Flag | Valid values | Default |
|------|-------------|---------|
| `--module` | module name | `default` |
| `--priority` | `must`, `should`, `could`, `wont` | all |
| `--category` | `AUTH`, `DATA`, `UI`, `API`, `PERF`, `SEC`, `INT`, `BIZ`, `INF` | all |
| `--type` | `functional`, `non-functional`, `constraint`, `interface` | all |
| `--status` | `active`, `deprecated`, `deleted` | `active` |
| `--approval` | `proposed`, `approved`, `revised` | all |
| `--tag` | any tag string | all |
| `--domain` | domain reference | all |
| `--format` | `yaml`, `csv` (export only) | `yaml` |

## Editable Fields

The `edit` command supports scalar fields: `type`, `priority`, `summary`, `detail`, `status`.

To update acceptance criteria (or any combination of fields), use the `update` command
with YAML on stdin. Workflow: `show --format yaml` → edit the YAML → pipe to `update`.

Tags, dependencies, and domains can also be managed via `tag`, `depend`, and `domain` commands.

**Auto-transition**: Editing `summary`, `detail`, or acceptance criteria on an `approved`
requirement automatically transitions it to `revised`. The previously-approved content is
saved as mirror fields so it can be compared (`diff`) or restored (`revert`).

## Display IDs

Format: `CATEGORY-NNN` (e.g., `AUTH-001`, `BIZ-012`). The `--module` flag is only
needed when the same display ID exists in multiple modules. The default module is
`default`.

## Response Formatting

After running a CLI command, present the output clearly:
- For `list`: summarise the count and show the table output
- For `show`: present all fields including acceptance criteria, tags, and dependencies
- For `edit`/`update`/`tag`/`rm`: confirm the action taken
- For `stats`/`check`: present the output directly

## Schema Reference

@../spec-writer/system-requirements-spec.md
