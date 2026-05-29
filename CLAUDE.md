# CLAUDE.md — Patina Project

## Project Vision

A MIT-licensed, FOSS PLM/CMS system built in Rust. No open-core. No vendor lock-in.
Revenue model: support, consulting, hosting only.

Reference standard for process discipline: DO-178C (adapted for software tooling context).

---

## Core Principles

- **MIT License** — permissive, no exceptions
- **Spec-driven** — no code without a specification
- **Test-driven** — no spec without tests; tests are the executable spec
- **Security-first** — threat model before implementation
- **Incremental** — working software at every phase boundary

---

## Technology Stack

```
Language:     Rust (stable toolchain, MSRV pinned in rust-toolchain.toml)
Database:     PostgreSQL 15+
ORM:          sqlx (async, compile-time query verification)
API:          Axum
Auth:         JWT + RBAC (no external IdP dependency for core)
Frontend:     htmx + minimal CSS (no JS framework)
Testing:      cargo test + cargo-nextest
Linting:      clippy (deny warnings), rustfmt
SBOM:         cargo-cyclonedx
Audit:        cargo-audit (run in CI)
Docs:         rustdoc + mdBook
Packaging:    melange (build APK packages) + apko (assemble OCI images)
Images:       distroless/undistro only — no shell, no package manager in runtime image
```

---

## Repository Hosting

**Canonical:** `forgejo.wulf.science/WulfScience-FOSS/patina`
**Mirror:** GitHub (`github.com/Wulf-Science/patina`) — read-only, auto-mirrored, for discoverability

Forgejo mirroring to GitHub is built-in (Settings → Mirror). Set push interval to 1h.

All issues, PRs, and CI live on Forgejo. GitHub is a read-only consumer surface only.
GitHub issues disabled to avoid split community.

---



```
patina/
├── CLAUDE.md               # This file
├── SPEC.md                 # Master specification index
├── THREAT_MODEL.md         # Security threat model
├── CHANGELOG.md            # Semver changelog
├── rust-toolchain.toml     # Pinned Rust version
├── Cargo.toml
├── Cargo.lock              # Committed (binary crate)
├── assets/
│   ├── images/             # Logos and other images
├── docs/
│   ├── specs/              # Per-feature specifications (*.spec.md)
│   ├── adr/                # Architecture Decision Records
│   └── prior-art/          # Prior art analysis documents
├── migrations/             # sqlx migrations (numbered, immutable)
├── packaging/
│   ├── melange.yaml        # APK build definition
│   └── apko.yaml           # OCI image assembly definition
├── src/
│   ├── domain/             # Pure domain types, no I/O
│   ├── db/                 # Repository layer
│   ├── api/                # Axum handlers
│   ├── auth/               # AuthN/AuthZ
│   └── main.rs
└── tests/
    ├── integration/        # Black-box API tests
    └── fixtures/           # Test data
```

---

## Development Workflow (Mandatory)

Every feature MUST follow this sequence. No exceptions.

```
PRIOR ART → SPEC → THREAT MODEL → TESTS (failing) → IMPLEMENTATION → TESTS (passing) → DOCS
```

### Phase Gate Checklist (per feature)

- [ ] Prior art documented in `docs/prior-art/<feature>.md`
- [ ] Specification written in `docs/specs/<feature>.spec.md`
- [ ] ADR written if architectural decision was made
- [ ] Threat model updated in `THREAT_MODEL.md`
- [ ] Tests written and confirmed failing (`cargo nextest run`)
- [ ] Implementation written
- [ ] All tests passing
- [ ] `cargo clippy -- -D warnings` clean
- [ ] `cargo audit` clean
- [ ] Rustdoc on all public items
- [ ] CHANGELOG.md updated

---

## Phase 0 — Prior Art Analysis (START HERE)

Complete before writing any code or specs.

### 0.1 OpenPLM Schema Analysis

- [ ] Clone https://github.com/openplm/openplm
- [ ] Extract and document full database schema to `docs/prior-art/openplm-schema.md`
- [ ] Identify: part/document model, revision scheme, lifecycle states, BOM structure, ECO/ECR workflow tables
- [ ] Identify: what to adopt, what to discard, what to improve
- [ ] Document findings with rationale

### 0.2 Aras Innovator Data Model

- [ ] Install Aras Community Edition (VM/container)
- [ ] Document core ItemType schema to `docs/prior-art/aras-schema.md`
- [ ] Focus: relationship model, versioning approach, lifecycle engine
- [ ] Note: do NOT copy any Aras code — schema observation only

### 0.3 FreeCAD PDM Discussion Review

- [ ] Review FreeCAD forum PDM/PLM threads
- [ ] Document: user pain points, desired features, integration expectations
- [ ] File: `docs/prior-art/freecad-community-needs.md`
- [ ] This defines the early adopter target persona

### 0.4 Teamcenter Feature Baseline

- [ ] Document core Teamcenter capabilities to `docs/prior-art/teamcenter-baseline.md`
- [ ] Categorise each: MVP / Post-MVP / Out-of-scope
- [ ] Sources: public documentation, ISO 10303 (STEP), IEC 82045

### 0.5 Prior Art Summary

- [ ] Write `docs/prior-art/SUMMARY.md` synthesising all above
- [ ] Define the initial domain vocabulary (ubiquitous language)
- [ ] Gate: do not proceed to Phase 1 until summary is reviewed and committed

---

## Phase 1 — Core Domain Model

### Scope

Revision-controlled items with lifecycle states. No UI. No BOM. No workflow engine yet.

### Specifications Required

- `docs/specs/item.spec.md` — Part and Document item model
- `docs/specs/revision.spec.md` — Revision scheme (alphabetic/numeric, branching rules)
- `docs/specs/lifecycle.spec.md` — Lifecycle state machine (states, transitions, guards)
- `docs/specs/identity.spec.md` — Item numbering and identity rules

### Spec Format (mandatory for every spec)

```markdown
# Specification: <Feature Name>
Version: 0.1.0
Status: DRAFT | REVIEW | APPROVED | SUPERSEDED

## Purpose
One paragraph.

## Requirements
REQ-XXX-001: <shall statement>
REQ-XXX-002: <shall statement>

## Data Model
(ERD or field table)

## Behaviour
(State machine, sequence diagram, or invariant table)

## Acceptance Criteria
ACC-XXX-001: Given / When / Then
ACC-XXX-002: Given / When / Then

## Out of Scope
Explicit exclusions.

## References
- Prior art docs
- Standards (ISO, IEC, IEEE)
```

### Implementation Order

1. Domain types (`src/domain/`) — pure Rust, no DB dependency
2. Database migrations (`migrations/`)
3. Repository layer (`src/db/`)
4. Integration tests (`tests/integration/`)

### Phase 1 Exit Criteria

- All acceptance criteria tests passing
- `cargo audit` clean
- No clippy warnings
- Schema documented and stable

---

## Phase 2 — REST API + AuthN/AuthZ

### Scope

HTTP API over Phase 1 domain. RBAC. JWT. OpenAPI spec generated from code.

### Specifications Required

- `docs/specs/api.spec.md` — Endpoint catalogue, HTTP semantics, error schema
- `docs/specs/auth.spec.md` — AuthN flow, RBAC roles and permissions matrix
- `docs/specs/audit-log.spec.md` — Immutable audit trail requirements

### Security Requirements (non-negotiable)

- OWASP API Security Top 10 addressed per endpoint in `THREAT_MODEL.md`
- No secrets in code or logs
- All inputs validated at API boundary
- Rate limiting on auth endpoints
- `cargo-audit` in CI blocking

---

## Phase 3 — BOM Management

### Scope

Single-level and multi-level BOM. Where-used. BOM comparison across revisions.

### Specifications Required

- `docs/specs/bom.spec.md`
- `docs/specs/where-used.spec.md`
- `docs/specs/bom-compare.spec.md`

---

## Phase 4 — ECO/ECR Workflow Engine

### Scope

Engineering Change Order / Request lifecycle. Approvals. Affected item tracking.

### Specifications Required

- `docs/specs/eco.spec.md`
- `docs/specs/ecr.spec.md`
- `docs/specs/approval-workflow.spec.md`

---

## Phase 5 — UI (htmx)

### Scope

Minimal, functional web UI. No SPA. Server-side rendering.
UI is a client of the Phase 2 API — no business logic in templates.

---

## Testing Policy

Derived from DO-178C principles, adapted for tooling software.

| Test Type | Location | Requirement |
|-----------|----------|-------------|
| Unit | `src/**/tests` | Every domain invariant |
| Integration | `tests/integration/` | Every acceptance criterion |
| Regression | CI on every PR | All of the above |
| Security | `cargo-audit` + manual | Every phase boundary |

- Tests are written **before** implementation (TDD, not test-after)
- Acceptance criteria IDs in spec map 1:1 to test names
- No `#[allow(dead_code)]` without documented justification
- Coverage tracked but not used as sole quality gate — coverage of wrong behaviour is worthless

---

## Architecture Decision Records

All significant decisions documented in `docs/adr/` using this format:

```markdown
# ADR-NNN: <Title>
Date: YYYY-MM-DD
Status: PROPOSED | ACCEPTED | SUPERSEDED by ADR-NNN

## Context
## Decision
## Consequences
## Alternatives Considered
```

First ADRs to write (Phase 0 output):
- ADR-001: Choice of Rust
- ADR-002: Choice of sqlx over Diesel
- ADR-003: Revision scheme design
- ADR-004: Lifecycle state machine approach
- ADR-005: MIT license rationale
- ADR-006: melange + apko over Dockerfile for container images

---

## Security Policy

- `THREAT_MODEL.md` updated at every phase boundary
- Threat model format: STRIDE per component
- `cargo-audit` blocks CI on any RUSTSEC advisory
- Dependency updates reviewed weekly
- No `unsafe` without documented justification and review
- **Container images built exclusively with melange + apko**
  - melange builds reproducible APKs from source
  - apko assembles OCI image from APK set — no Dockerfile, no shell in runtime image
  - Zero unknown binaries in image; every component has a declared APK origin
  - apko generates image SBOM on every build
  - grype CVE scan against produced image in CI, blocking on HIGH/CRITICAL

---

## CI / Actions

**Runners:** Self-hosted on Forgejo, AMD64 + ARM64.
Builds are run on both architectures. Multi-arch OCI images produced via apko on every merge to main.

**Actions defined in `.forgejo/workflows/`:**

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yaml` | PR, push to main | cargo test, clippy, audit |
| `image.yaml` | push to main | melange + apko build + grype scan |
| `mirror.yaml` | push to main | push to GitHub read-only mirror |
| `milestone-sync.yaml` | PR merged to main | parse roadmap markdown, sync Forgejo milestones via API |

`milestone-sync.yaml` spec: `docs/specs/ci-milestone-sync.spec.md`
- Parses phase gate checklist from merged PR body
- Calls Forgejo REST API (`/api/v1/repos/{owner}/{repo}/milestones`) to update progress
- Auto-closes milestone when all phase gate items checked
- Auto-creates next phase milestone on closure
- Posts milestone progress summary as PR comment

---



```
Branches:   main (stable), feat/<name>, fix/<name>, spec/<name>
Commits:    Conventional Commits (feat, fix, docs, test, refactor, chore)
PRs:        Phase gate checklist must be complete before merge
Tags:       Semver (v0.1.0), signed
```

Commit message example:
```
feat(domain): add lifecycle state machine for Item

REQ-LIFECYCLE-001, REQ-LIFECYCLE-002
ACC-LIFECYCLE-001 through ACC-LIFECYCLE-004 now passing
```

---

## Definition of Done

A feature is done when:

1. Specification APPROVED in `docs/specs/`
2. All acceptance criteria tests passing
3. `cargo clippy -- -D warnings` clean
4. `cargo audit` clean
5. `cargo doc` generates without warnings
6. CHANGELOG.md entry written
7. THREAT_MODEL.md updated if attack surface changed
8. PR reviewed and merged to main

---

## What This Is Not (Explicit Scope Exclusions for MVP)

- Not a CAD integration (post-MVP)
- Not a ERP/financial module
- Not a cloud-only product (self-hostable is a requirement)
- Not an open-core product — ever