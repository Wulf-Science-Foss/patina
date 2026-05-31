# Phase 0 — Prior Art Analysis

**Status:** COMPLETE
**Gate:** Do not proceed to Phase 1 until `docs/prior-art/SUMMARY.md` is reviewed and committed.

Complete all tasks below before writing any code or specs.

---

## 0.1 OpenPLM Schema Analysis

Output: [`docs/prior-art/openplm-schema.md`](../prior-art/openplm-schema.md)

- [x] Clone https://github.com/openplm/openplm
- [x] Extract and document the full database schema
- [x] Identify: part/document model, revision scheme, lifecycle states, BOM structure, ECO/ECR workflow tables
- [x] Classify each element: adopt / discard / improve
- [x] Document findings with rationale

## 0.2 Aras Innovator Data Model

Output: [`docs/prior-art/aras-schema.md`](../prior-art/aras-schema.md)

- [x] Install Aras Community Edition (VM or container)
- [x] Document core ItemType schema
- [x] Focus: relationship model, versioning approach, lifecycle engine
- [x] Note: do NOT copy any Aras code — schema observation only

## 0.3 FreeCAD PDM Community Review

Output: [`docs/prior-art/freecad-community-needs.md`](../prior-art/freecad-community-needs.md)

- [x] Review FreeCAD forum PDM/PLM threads
- [x] Document: user pain points, desired features, integration expectations
- [x] This analysis defines the early adopter target persona

## 0.4 Teamcenter Feature Baseline

Output: [`docs/prior-art/teamcenter-baseline.md`](../prior-art/teamcenter-baseline.md)

- [x] Document core Teamcenter capabilities
- [x] Categorise each: MVP / Post-MVP / Out-of-scope
- [x] Sources: public documentation, ISO 10303 (STEP), IEC 82045

## 0.5 Standards Analysis

Output: [`docs/prior-art/standards.md`](../prior-art/standards.md)

- [x] Document each relevant standard: scope, key requirements, and implications for Patina
- [x] Standards to cover: ISO 10007:2017, IEEE 828-2012, IEC 82045, CMII (ICMM), ISO 10303 AP242 (STEP), ISO 8000
- [x] For each standard, identify: rules that constrain Patina's design, rules we adopt, and intentional deviations with rationale
- [x] Note: ITIL excluded — IT service management, wrong domain

## 0.6 Prior Art Summary

Output: [`docs/prior-art/SUMMARY.md`](../prior-art/SUMMARY.md)

- [x] Synthesise all five analyses above (0.1–0.5)
- [x] Define the initial domain vocabulary (ubiquitous language)
- [x] **Gate:** do not proceed to Phase 1 until this is reviewed and committed

## Phase Gate Checklist

- [x] OpenPLM schema documented (`docs/prior-art/openplm-schema.md`)
- [x] Aras Innovator data model documented (`docs/prior-art/aras-schema.md`)
- [x] FreeCAD community needs documented (`docs/prior-art/freecad-community-needs.md`)
- [x] Teamcenter feature baseline documented (`docs/prior-art/teamcenter-baseline.md`)
- [x] Standards analysis documented (`docs/prior-art/standards.md`)
- [x] Prior art summary written and reviewed (`docs/prior-art/SUMMARY.md`)
