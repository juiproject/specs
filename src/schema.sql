-- Requirements Database Schema
-- Version: 1.0
-- Engine: SQLite 3
--
-- This schema supports a requirements management system with optional modules.
-- A 'default' module is auto-created on init and used when no module is specified.
-- Requirements follow a YAML-compatible model with categories (AUTH, DATA, UI,
-- API, PERF, SEC, INT, BIZ, INF), MoSCoW priorities, and testable acceptance
-- criteria.
--
-- Display IDs (e.g., AUTH-001) are derived from category + seq, not stored as
-- a composite string. This keeps renumbering clean when requirements are removed.
--
-- All deletes are soft-deletes (status = 'deleted'). Nothing is permanently
-- removed by default. Use `req purge <days>` to physically remove
-- soft-deleted requirements older than the given number of days.
--
-- Usage:
--   sqlite3 requirements.db < schema.sql
--   Or via the req CLI: req init

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

-- ============================================================================
-- MODULES
-- Represents a Maven module or logical grouping of requirements.
-- ============================================================================
CREATE TABLE IF NOT EXISTS modules (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL UNIQUE,
    description TEXT,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================================
-- REQUIREMENTS
-- One row per requirement. The display ID is derived as: category || '-' || seq
-- formatted to 3 digits (e.g., AUTH-001).
--
-- type:            functional | non-functional | constraint | interface
-- priority:        must | should | could | wont
-- status:          active | deprecated | deleted
-- approval_status: proposed | approved | revised
-- ============================================================================
CREATE TABLE IF NOT EXISTS requirements (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id   INTEGER NOT NULL REFERENCES modules(id),
    category    TEXT    NOT NULL CHECK (category IN ('AUTH','DATA','UI','API','PERF','SEC','INT','BIZ','INF')),
    seq         INTEGER NOT NULL,
    type        TEXT    NOT NULL CHECK (type IN ('functional','non-functional','constraint','interface')),
    priority    TEXT    NOT NULL DEFAULT 'should' CHECK (priority IN ('must','should','could','wont')),
    summary     TEXT    NOT NULL,
    detail      TEXT,
    status           TEXT    NOT NULL DEFAULT 'active' CHECK (status IN ('active','deprecated','deleted')),
    approval_status  TEXT    NOT NULL DEFAULT 'proposed' CHECK (approval_status IN ('proposed','approved','revised')),
    approved_at      TEXT,
    revised_at       TEXT,
    approved_summary TEXT,
    approved_detail  TEXT,
    created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE(module_id, category, seq)
);

-- ============================================================================
-- ACCEPTANCE CRITERIA
-- One row per testable pass/fail criterion. Every requirement should have at
-- least one, enforced by convention (not constraint) to allow drafts.
-- ============================================================================
CREATE TABLE IF NOT EXISTS acceptance (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    requirement_id  INTEGER NOT NULL REFERENCES requirements(id) ON DELETE CASCADE,
    criterion       TEXT    NOT NULL,
    sort_order      INTEGER NOT NULL DEFAULT 0
);

-- ============================================================================
-- APPROVED ACCEPTANCE CRITERIA (MIRROR)
-- Stores the previously-approved version of acceptance criteria when a
-- requirement transitions from APPROVED to REVISED. Cleared when approved
-- or withdrawn.
-- ============================================================================
CREATE TABLE IF NOT EXISTS approved_acceptance (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    requirement_id  INTEGER NOT NULL REFERENCES requirements(id) ON DELETE CASCADE,
    criterion       TEXT    NOT NULL,
    sort_order      INTEGER NOT NULL DEFAULT 0
);

-- ============================================================================
-- TAGS
-- Freeform labels for grouping and filtering (e.g., onboarding, security).
-- ============================================================================
CREATE TABLE IF NOT EXISTS requirement_tags (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    requirement_id  INTEGER NOT NULL REFERENCES requirements(id) ON DELETE CASCADE,
    tag             TEXT    NOT NULL,
    UNIQUE(requirement_id, tag)
);

-- ============================================================================
-- DEPENDENCIES
-- Directed edges: requirement_id depends on depends_on_id.
-- Display IDs are resolved at query time.
-- ============================================================================
CREATE TABLE IF NOT EXISTS requirement_depends (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    requirement_id  INTEGER NOT NULL REFERENCES requirements(id) ON DELETE CASCADE,
    depends_on_id   INTEGER NOT NULL REFERENCES requirements(id),
    UNIQUE(requirement_id, depends_on_id),
    CHECK(requirement_id != depends_on_id)
);

-- ============================================================================
-- DOMAINS
-- Scoped within a module. Provides a grouping of requirements by area of
-- applicability (e.g., email service, review mechanism, organisation).
-- A requirement can belong to multiple domains (many-to-many).
-- ============================================================================
CREATE TABLE IF NOT EXISTS domains (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id   INTEGER NOT NULL REFERENCES modules(id),
    reference   TEXT    NOT NULL,
    name        TEXT    NOT NULL,
    description TEXT,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE(module_id, reference)
);

CREATE TABLE IF NOT EXISTS requirement_domains (
    requirement_id INTEGER NOT NULL REFERENCES requirements(id) ON DELETE CASCADE,
    domain_id      INTEGER NOT NULL REFERENCES domains(id) ON DELETE CASCADE,
    PRIMARY KEY (requirement_id, domain_id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_req_module      ON requirements(module_id);
CREATE INDEX IF NOT EXISTS idx_req_category    ON requirements(category);
CREATE INDEX IF NOT EXISTS idx_req_priority    ON requirements(priority);
CREATE INDEX IF NOT EXISTS idx_req_status      ON requirements(status);
CREATE INDEX IF NOT EXISTS idx_accept_req      ON acceptance(requirement_id);
CREATE INDEX IF NOT EXISTS idx_approved_accept_req ON approved_acceptance(requirement_id);
CREATE INDEX IF NOT EXISTS idx_tags_req        ON requirement_tags(requirement_id);
CREATE INDEX IF NOT EXISTS idx_tags_tag        ON requirement_tags(tag);
CREATE INDEX IF NOT EXISTS idx_depends_req     ON requirement_depends(requirement_id);
CREATE INDEX IF NOT EXISTS idx_depends_target  ON requirement_depends(depends_on_id);
CREATE INDEX IF NOT EXISTS idx_domains_module  ON domains(module_id);
CREATE INDEX IF NOT EXISTS idx_reqdom_req      ON requirement_domains(requirement_id);
CREATE INDEX IF NOT EXISTS idx_reqdom_domain   ON requirement_domains(domain_id);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Full requirement with display ID and module name
CREATE VIEW IF NOT EXISTS v_requirements AS
SELECT
    r.id AS internal_id,
    r.category || '-' || printf('%03d', r.seq) AS display_id,
    m.name AS module,
    r.category,
    r.seq,
    r.type,
    r.priority,
    r.summary,
    r.detail,
    r.status,
    r.approval_status,
    r.approved_at,
    r.revised_at,
    r.created_at,
    r.updated_at
FROM requirements r
JOIN modules m ON m.id = r.module_id;

-- Requirements missing acceptance criteria (quality check)
CREATE VIEW IF NOT EXISTS v_missing_acceptance AS
SELECT
    r.category || '-' || printf('%03d', r.seq) AS display_id,
    m.name AS module,
    r.summary
FROM requirements r
JOIN modules m ON m.id = r.module_id
LEFT JOIN acceptance a ON a.requirement_id = r.id
WHERE a.id IS NULL
  AND r.status = 'active';
