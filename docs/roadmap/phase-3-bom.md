# Phase 3 — BOM Management

**Status:** TODO
**Prerequisite:** Phase 2 complete

## Scope

Single-level and multi-level Bill of Materials. Where-used queries. BOM comparison across revisions.

---

## Specifications Required

| Spec | Description |
|------|-------------|
| [bom.spec.md](../specs/bom.spec.md) | BOM structure, single-level and multi-level |
| [where-used.spec.md](../specs/where-used.spec.md) | Where-used query semantics |
| [bom-compare.spec.md](../specs/bom-compare.spec.md) | BOM diff across revision pairs |

## Phase Gate Checklist

- [ ] All three specs APPROVED
- [ ] Threat model updated
- [ ] Tests written and confirmed failing
- [ ] Implementation complete
- [ ] All tests passing
- [ ] `cargo clippy -- -D warnings` clean
- [ ] `cargo audit` clean
- [ ] Rustdoc on all public items
- [ ] CHANGELOG.md updated
