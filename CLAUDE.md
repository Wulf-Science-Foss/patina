# CLAUDE.md — Patina Project

## Project Vision

A MIT-licensed, FOSS PLM/CMS system built in Rust. No open-core. No vendor lock-in.
Revenue model: support, consulting, hosting only.

Reference standard for process discipline: DO-178C (adapted for software tooling context).

---

## Instructions for Claude

- **Do not use the auto-memory system.** Do not write to `~/.claude/` or any path outside this repository. CLAUDE.md and files in this repo are the only source of truth. Context contamination via hidden memory files is not acceptable.
- **Always create the correct branch structure before committing.** Create `<type>/<name>` feature branch and `<type>/<name>--<change>` sub-branches. Never commit directly to `main`.

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
**Mirrors (read-only, auto-mirrored, for discoverability):**
- GitHub: `github.com/Wulf-Science-Foss/patina`
- GitLab: `gitlab.com/wulf-science-foss/patina`

Forgejo mirroring to GitHub is built-in (Settings → Mirror). Set push interval to 1h.

All issues, PRs, and CI live on Forgejo. GitHub is a read-only consumer surface only.
GitHub issues disabled to avoid split community.

---

## Repository Structure

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
│   └── images/             # Logos and other images
├── docs/
│   ├── roadmap/            # Phase-by-phase plans and gate checklists
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
PRIOR ART → SPEC → THREAT MODEL → TESTS (failing) → IMPLEMENTATION → TESTS (passing) → DOCS → REVIEW → PR
```

### Phase Gate Checklist (per feature)

These boxes are **checked off automatically** when the PR merges to `main`
(see [CI / Actions](#ci--actions)). Do not tick them manually during
development — an unchecked checklist on an open branch is the correct,
expected state.

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
- [ ] Review agent run on feature branch; all findings addressed (see [Review Policy](#review-policy))

---

## Roadmap

See `docs/roadmap/` for phase-by-phase plans, scope, and gate checklists.

| Phase | File | Status |
|-------|------|--------|
| Phase 0 — Prior Art Analysis | [phase-0-prior-art.md](docs/roadmap/phase-0-prior-art.md) | TODO |
| Phase 1 — Core Domain Model | [phase-1-core-domain.md](docs/roadmap/phase-1-core-domain.md) | TODO |
| Phase 2 — REST API + AuthN/AuthZ | [phase-2-api-auth.md](docs/roadmap/phase-2-api-auth.md) | TODO |
| Phase 3 — BOM Management | [phase-3-bom.md](docs/roadmap/phase-3-bom.md) | TODO |
| Phase 4 — ECO/ECR Workflow Engine | [phase-4-eco-ecr.md](docs/roadmap/phase-4-eco-ecr.md) | TODO |
| Phase 5 — UI (htmx) | [phase-5-ui.md](docs/roadmap/phase-5-ui.md) | TODO |

**Start with Phase 0.** Do not write code or specs before Phase 0 is complete.

---

## Specifications

Master index: [`SPEC.md`](SPEC.md)
Template: [`docs/specs/TEMPLATE.spec.md`](docs/specs/TEMPLATE.spec.md)

All specs use the mandatory format defined in the template. Acceptance criteria IDs in specs
map 1:1 to test function names.

---

## Architecture Decision Records

All significant decisions are documented in `docs/adr/`.
Template: [`docs/adr/TEMPLATE.adr.md`](docs/adr/TEMPLATE.adr.md)

First ADRs to write (Phase 0 output):

| ADR | File |
|-----|------|
| ADR-001: Choice of Rust | [ADR-001-rust.md](docs/adr/ADR-001-rust.md) |
| ADR-002: Choice of sqlx over Diesel | [ADR-002-sqlx.md](docs/adr/ADR-002-sqlx.md) |
| ADR-003: Revision scheme design | [ADR-003-revision-scheme.md](docs/adr/ADR-003-revision-scheme.md) |
| ADR-004: Lifecycle state machine approach | [ADR-004-lifecycle-state-machine.md](docs/adr/ADR-004-lifecycle-state-machine.md) |
| ADR-005: MIT license rationale | [ADR-005-mit-license.md](docs/adr/ADR-005-mit-license.md) |
| ADR-006: melange + apko over Dockerfile | [ADR-006-melange-apko.md](docs/adr/ADR-006-melange-apko.md) |

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
| `milestone-sync.yaml` | PR merged to main | parse roadmap markdown, sync Forgejo milestones via API |
| `gate-checkoff.yaml` | PR merged to main | tick the phase gate checklist and flip phase/spec status flags for the merged feature |

`milestone-sync.yaml` spec: [`docs/specs/ci-milestone-sync.spec.md`](docs/specs/ci-milestone-sync.spec.md)

`gate-checkoff.yaml` is the single authority for marking work done: phase
gate checkboxes, the roadmap Status column, and spec Status flags are
flipped by this workflow on merge to `main` — never by hand. Spec to be
written (`docs/specs/ci-gate-checkoff.spec.md`).

---

## Git / Branching Conventions

### Branch hierarchy

```
main                           # stable; never broken
└── <type>/<name>              # one branch per unit of work
    └── <type>/<name>--<change># one sub-branch per discrete change
```

`<type>` is any Conventional Commits prefix: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `spec`. The discipline applies equally to all of them — not just features.

Note: Git does not allow a branch and its own path-prefix to coexist, so sub-branches use `--` as separator rather than `/` (e.g. `feat/phase-0--openplm-analysis`, not `feat/phase-0/openplm-analysis`).

### Commit discipline

- **One commit per logical change.** A logical change is a single file, a single concept, or a single reason to change. Batching unrelated edits into one commit is not acceptable.
- Commits on sub-branches may leave the project in a broken state — that is fine.
- Before merging a sub-branch back to its feature branch, all tests must pass.
- Before merging a feature branch to `main`, the feature must be complete and all tests must pass.

### Context isolation

Each feature is started with a fresh context. Do not carry assumptions or state from a previous feature session. Rely on CLAUDE.md, specs, ADRs, and test output — not on memory of prior conversations.

### Opening pull requests

Always use `scripts/pr.sh` to open PRs — never `gh` or direct `curl`. The script reads
credentials from `.env` and posts to the Forgejo API.

```
bash scripts/pr.sh --title "<title>" [--head <branch>] [--base <branch>] [--body <text>]
```

Defaults: `--head` = current branch, `--base` = `main`.

The `--body` must summarise **all** changes being merged (one bullet per logical change).
Inspect `git log main..<head>` to ensure nothing is omitted before opening the PR.

### Commit format

```
Branches:   main (stable), feat/<name>, fix/<name>, spec/<name>, chore/<name>
Commits:    Conventional Commits (feat, fix, docs, test, refactor, chore)
PRs:        Phase gate checklist must be complete before merge to main
Tags:       Semver (v0.1.0), signed
```

Commit message example:
```
feat(domain): add lifecycle state machine for Item

REQ-LIFECYCLE-001, REQ-LIFECYCLE-002
ACC-LIFECYCLE-001 through ACC-LIFECYCLE-004 now passing
```

---

## Review Policy

Before a PR is opened, the feature branch must be reviewed by a review agent
running from a **fresh context with no knowledge of the current session**.
The purpose is independent verification: the reviewer should be able to
identify gaps, inconsistencies, and mistakes that the author cannot see.

### The review loop

The review is an iterative loop between two models. The reviewing model
**must differ from the model that authored the work** — independent
perspective is the point.

1. **Author (model A)** completes the work on the feature branch.
2. **Switch model**: `/model opus` (if Sonnet authored) or `/model sonnet`
   (if Opus authored).
3. **Review (model B)** runs `/code-review high` on the feature branch.
4. **Record, do not fix.** Model B writes every finding to a review document
   at `docs/reviews/<feature>-NNN.md`, where `NNN` is the review round
   (`001`, `002`, …). The reviewer never fixes findings — recording and
   fixing must be done by different models for the independence to hold.
5. **Switch back** to the authoring model (model A).
6. **Fix (model A)** resolves each finding and fills in its **Resolution**
   field in the review doc (commit reference or deferral rationale).
7. **Repeat** from step 2 with a new round (`NNN+1`) until a review round
   produces no HIGH or MEDIUM findings.

Only when a round is clean may the PR be opened. The latest review doc must
be referenced in the PR description.

### Severity handling

`/code-review` ranks findings by severity. Disposition:

| Severity | Disposition |
|----------|-------------|
| **High / Critical** | Must fix before PR. |
| **Medium** | Must fix, or explicitly defer with rationale recorded in the review doc. |
| **Low** | May defer; record as an open question or note. |

### Review scope

The review agent must check:

- **Correctness**: do the changes do what they claim? Are there factual
  errors, contradictions, or gaps?
- **Completeness**: does the work satisfy the phase gate checklist? Are any
  required documents missing or left as stubs?
- **Consistency**: do the documents agree with each other? Do specs, ADRs,
  and prior art findings align?
- **Standards compliance**: does the work respect the standards documented
  in `docs/prior-art/standards.md`?
- **Scope**: does anything in the diff violate the Definition of Done or
  reach into a phase that has not yet been gated?

### Review documents

Review findings live in `docs/reviews/`, one document per review round,
named `<feature>-NNN.md`. Each finding records location, severity,
description, and a Resolution field the author fills in. Dismissed findings
are recorded too (with rationale) so later rounds do not re-raise them.
Review documents are committed — they are the audit trail for the review
gate, as required by the standards in `docs/prior-art/standards.md`.

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
8. Review agent run (`/code-review high`) with a different model than the author; high findings addressed
9. PR reviewed and merged to main

---

## What This Is Not (Explicit Scope Exclusions for MVP)

- Not a CAD integration (post-MVP)
- Not an ERP/financial module
- Not a cloud-only product (self-hostable is a requirement)
- Not an open-core product — ever
