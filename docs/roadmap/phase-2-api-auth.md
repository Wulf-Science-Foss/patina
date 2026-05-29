# Phase 2 — REST API + AuthN/AuthZ

**Status:** TODO
**Prerequisite:** Phase 1 complete

## Scope

HTTP API over the Phase 1 domain. RBAC. JWT. OpenAPI spec generated from code.

---

## Specifications Required

| Spec | Description |
|------|-------------|
| [api.spec.md](../specs/api.spec.md) | Endpoint catalogue, HTTP semantics, error schema |
| [auth.spec.md](../specs/auth.spec.md) | AuthN flow, RBAC roles and permissions matrix |
| [audit-log.spec.md](../specs/audit-log.spec.md) | Immutable audit trail requirements |

## Security Requirements (non-negotiable)

- OWASP API Security Top 10 addressed per endpoint in `THREAT_MODEL.md`
- No secrets in code or logs
- All inputs validated at API boundary
- Rate limiting on auth endpoints
- `cargo-audit` in CI blocking

## Phase Gate Checklist

- [ ] All three specs APPROVED
- [ ] OWASP API Top 10 addressed in THREAT_MODEL.md
- [ ] Threat model updated
- [ ] Tests written and confirmed failing
- [ ] Implementation complete
- [ ] All tests passing
- [ ] `cargo clippy -- -D warnings` clean
- [ ] `cargo audit` clean
- [ ] Rustdoc on all public items
- [ ] CHANGELOG.md updated
