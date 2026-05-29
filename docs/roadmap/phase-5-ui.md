# Phase 5 — UI (htmx)

**Status:** TODO
**Prerequisite:** Phase 2 complete (UI is a client of the Phase 2 API)

## Scope

Minimal, functional web UI. No SPA. Server-side rendering only.
UI is a thin client of the Phase 2 REST API — no business logic in templates.

---

## Constraints

- htmx + minimal CSS — no JS framework
- All data operations go through the REST API
- No business logic in templates or handlers
- Accessible, keyboard-navigable

## Phase Gate Checklist

- [ ] Spec written and APPROVED
- [ ] Threat model updated (XSS, CSRF surface)
- [ ] UI test plan written
- [ ] Implementation complete
- [ ] Manual test of all golden paths
- [ ] `cargo clippy -- -D warnings` clean
- [ ] `cargo audit` clean
- [ ] CHANGELOG.md updated
