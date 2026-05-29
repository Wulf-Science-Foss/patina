# Phase 4 — ECO/ECR Workflow Engine

**Status:** TODO
**Prerequisite:** Phase 3 complete

## Scope

Engineering Change Order / Request lifecycle. Approvals. Affected item tracking.

---

## Specifications Required

| Spec | Description |
|------|-------------|
| [eco.spec.md](../specs/eco.spec.md) | Engineering Change Order lifecycle |
| [ecr.spec.md](../specs/ecr.spec.md) | Engineering Change Request lifecycle |
| [approval-workflow.spec.md](../specs/approval-workflow.spec.md) | Approval routing, delegation, escalation |

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
