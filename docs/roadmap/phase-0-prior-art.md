# Phase 0 — Prior Art Analysis

**Status:** TODO
**Gate:** Do not proceed to Phase 1 until `docs/prior-art/SUMMARY.md` is reviewed and committed.

Complete all tasks below before writing any code or specs.

---

## 0.1 OpenPLM Schema Analysis

Output: [`docs/prior-art/openplm-schema.md`](../prior-art/openplm-schema.md)

- [ ] Clone https://github.com/openplm/openplm
- [ ] Extract and document the full database schema
- [ ] Identify: part/document model, revision scheme, lifecycle states, BOM structure, ECO/ECR workflow tables
- [ ] Classify each element: adopt / discard / improve
- [ ] Document findings with rationale

## 0.2 Aras Innovator Data Model

Output: [`docs/prior-art/aras-schema.md`](../prior-art/aras-schema.md)

- [ ] Install Aras Community Edition (VM or container)
- [ ] Document core ItemType schema
- [ ] Focus: relationship model, versioning approach, lifecycle engine
- [ ] Note: do NOT copy any Aras code — schema observation only

## 0.3 FreeCAD PDM Community Review

Output: [`docs/prior-art/freecad-community-needs.md`](../prior-art/freecad-community-needs.md)

- [ ] Review FreeCAD forum PDM/PLM threads
- [ ] Document: user pain points, desired features, integration expectations
- [ ] This analysis defines the early adopter target persona

## 0.4 Teamcenter Feature Baseline

Output: [`docs/prior-art/teamcenter-baseline.md`](../prior-art/teamcenter-baseline.md)

- [ ] Document core Teamcenter capabilities
- [ ] Categorise each: MVP / Post-MVP / Out-of-scope
- [ ] Sources: public documentation, ISO 10303 (STEP), IEC 82045

## 0.5 Prior Art Summary

Output: [`docs/prior-art/SUMMARY.md`](../prior-art/SUMMARY.md)

- [ ] Synthesise all four analyses above
- [ ] Define the initial domain vocabulary (ubiquitous language)
- [ ] **Gate:** do not proceed to Phase 1 until this is reviewed and committed
