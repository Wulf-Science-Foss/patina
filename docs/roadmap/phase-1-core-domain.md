# Phase 1 — Core Domain Model

**Status:** TODO
**Prerequisite:** Phase 0 complete ([prior art summary](../prior-art/SUMMARY.md) committed)

## Scope

Revision-controlled items with lifecycle states. No UI. No BOM. No workflow engine.

---

## Specifications Required

| Spec | Description |
|------|-------------|
| [item.spec.md](../specs/item.spec.md) | Part and Document item model |
| [revision.spec.md](../specs/revision.spec.md) | Revision scheme (alphabetic/numeric, branching rules) |
| [lifecycle.spec.md](../specs/lifecycle.spec.md) | Lifecycle state machine (states, transitions, guards) |
| [identity.spec.md](../specs/identity.spec.md) | Item numbering and identity rules |

## Implementation Order

1. Domain types (`src/domain/`) — pure Rust, no DB dependency
2. Database migrations (`migrations/`)
3. Repository layer (`src/db/`)
4. Integration tests (`tests/integration/`)

## Phase Gate Checklist

- [ ] Prior art documented
- [ ] All four specs APPROVED
- [ ] ADRs written for architectural decisions
- [ ] Threat model updated
- [ ] Tests written and confirmed failing
- [ ] Implementation complete
- [ ] All tests passing
- [ ] `cargo clippy -- -D warnings` clean
- [ ] `cargo audit` clean
- [ ] Rustdoc on all public items
- [ ] CHANGELOG.md updated
- [ ] Schema documented and stable
