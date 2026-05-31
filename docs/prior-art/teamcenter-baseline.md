# Prior Art: Teamcenter Feature Baseline
Status: COMPLETE

Sources: Siemens public documentation, PLM Coach, PLM Handbook blog,
Swoosh Technologies, ISO 10303 AP242 summaries, IEC 82045 overview
Analysed: 2026-05-30

---

## Overview

Siemens Teamcenter is the market-leading commercial PLM system (CIMdata
consistently ranks it #1 by revenue and deployments). It is the de facto
standard for large manufacturers. This analysis documents its core
capabilities and data model to establish what "full PLM" looks like, then
classifies each capability against Patina's MVP scope.

---

## Core Data Model

### Object Hierarchy

```
Item
├── ItemMaster (form — attributes global to all revisions)
└── ItemRevision /A
    ├── ItemRevisionMaster (form — attributes specific to this revision)
    ├── BOMView
    │   └── BOMViewRevision
    │       └── BOMLine → ItemRevision (child)
    └── Dataset (file container)
        └── NamedReference (actual file)
```

### Item

The stable entity representing a product, component, or managed object.
Holds data that is **consistent across all revisions**.

| Field | Description |
|-------|-------------|
| Item ID | Auto-generated numeric (e.g. `000123`). Stable forever. |
| Name | Human-readable name |
| Type | Item subtype (Part, Document, etc.) — extensible via BMIDE |
| ItemMaster form | Extended attributes global to all revisions |

An Item is created once. Subsequent changes produce new ItemRevisions; the
Item itself never changes identity.

### ItemRevision

Holds data **specific to one revision** of an Item.

| Field | Description |
|-------|-------------|
| Revision ID | Single or double letter (A, B … AA, AB …) |
| Full ID | `ItemID/RevID` e.g. `000123/A` |
| ItemRevisionMaster form | Extended attributes for this revision |
| Release status | Current lifecycle state |
| Datasets | Attached files (drawings, CAD, specs, etc.) |
| BOM Views | Product structure views |

On creation of a new ItemRevision ("Revise" action), the system copies
attributes from the prior revision as a starting point.

### Dataset

Container for one or more files attached to an ItemRevision. Each Dataset
has a type (e.g. `UGMASTER` for NX geometry, `DirectModel` for JT,
`MSWord` for documents). Patina does not need CAD-specific Dataset types;
a generic file vault Dataset type is sufficient for MVP.

### BOM View and BOM View Revision

- **BOMView**: a named view of the product structure (e.g. "Engineering BOM",
  "Manufacturing BOM", "Service BOM"). One ItemRevision can have multiple
  BOM Views.
- **BOMViewRevision**: the actual structure for a specific BOMView at a
  specific ItemRevision. Contains BOMLines.
- **BOMLine**: one line in the structure — links to a child ItemRevision,
  carrying quantity, find number, and effectivity.

---

## Revision Scheme

- **Item ID**: auto-generated, numeric, globally unique. Users can optionally
  assign a meaningful number during creation.
- **Revision ID**: alphabetic sequence. Default: A → B → C … Z → AA → AB …
  Configurable per item type.
- **Combined key**: `000123/A` — the canonical reference in documentation and
  manufacturing orders.
- **First revision**: automatically created as `A` when the Item is created.
- **Revise action**: user selects an existing ItemRevision and invokes
  "Revise". Creates the next revision letter (e.g. B from A). Prior revision
  remains visible and queryable.
- **Iteration (Sequence)**: internal counter on ItemRevision, increments on
  check-in. Not user-visible by default; analogous to Aras's `generation`.

---

## Lifecycle States

Default lifecycle (configurable per installation):

| State | Access | Notes |
|-------|--------|-------|
| **In Work** | Editable by owner/team | Default state on creation |
| **Under Review** | Read-only; routing for approval | Workflow assigns reviewers |
| **Released** (TCM Released) | Read-only; visible to all with read access | Triggers revision letter lock |
| **Obsolete** | Read-only; typically filtered from BOM queries | Historical record only |

State transitions are driven by **workflow processes** (task routing,
electronic signatures). Access rules are enforced per state:
- In Work: only team can edit
- Released: everyone with read access can see; no one can edit without Revise
- Obsolete: visible but filtered from default queries

---

## Change Management

Teamcenter models the change process with four objects:

| Object | Purpose |
|--------|---------|
| **Problem Report (PR)** | Documents a specific problem or deficiency |
| **Change Request (CR)** | Proposes a solution; references the PR and affected items |
| **Engineering Order (EO)** | Container document; consolidates the full change |
| **Change Notification (CN)** | Notifies vendors/manufacturing/marketing of implemented change |

Workflow:
1. PR created → reviewed → accepted
2. CR created referencing PR → CCB review → approved
3. EO created → engineering executes change (creates new ItemRevisions) → sign-off
4. CN issued to relevant parties
5. Old ItemRevisions marked obsolete; new revisions become active in assemblies

---

## Revision Rules

Revision rules control which ItemRevision is loaded when opening an assembly:

| Rule | Behaviour |
|------|-----------|
| Latest Working | Opens newest working revision (used during development) |
| Latest Released | Opens newest released revision (used for manufacturing) |
| Any Status; Working | Mixed: released or working, most current |
| Precise (date-effective) | Loads the revision valid on a specific date |

This is how Teamcenter handles the problem of "which BOM was in effect on
a given date" — a requirement for traceability and change impact analysis.

---

## Assembly Types

- **Precise assembly**: all components pinned to specific ItemRevisions.
  Used when the assembly is released — it represents a specific, immutable
  configuration.
- **Imprecise assembly**: components resolved dynamically by revision rule.
  Used during development — the BOM structure is stable but components
  follow the latest working versions.

---

## Feature Classification for Patina

### MVP

| Feature | Notes |
|---------|-------|
| Item model (ID + Name) | Core concept; stable identity |
| ItemRevision (alphabetic revision letters) | A → B → C sequence |
| Four lifecycle states (In Work / Under Review / Released / Obsolete) | Sufficient for MVP |
| Simple BOM (single view, flat or multi-level) | Engineering BOM only |
| Precise assembly references | Lock to specific revision after release |
| File attachment (generic vault, no CAD-specific types) | Attach any file to a revision |
| Access control: owner/group + state-based read/write | RBAC per CLAUDE.md |
| Audit log | Required by IEEE 828 and IEC 82045 |
| Change Request + Engineering Order (basic) | Basic CR→EO flow; no CN for MVP |

### Post-MVP

| Feature | Notes |
|---------|-------|
| Multiple BOM views (Eng/Mfg/Service) | Useful; not day-one |
| Imprecise assemblies + revision rules | Adds complexity; revisit for Phase 3 |
| Full ECO/CR/PR/CN workflow with CCB routing | Phase 4 scope |
| Classification (taxonomy, attribute inheritance) | Useful for part libraries |
| Baselines (named snapshot of a product structure) | Important for DO-178C contexts |
| Date-effective revision queries ("what was the BOM on date X?") | Phase 3+ |
| Variant/configuration management (150% BOM) | Post-MVP |

### Out-of-scope

| Feature | Reason |
|---------|--------|
| CAD tool-specific Dataset types (NX, CATIA, ProE) | CAD-agnostic; not Patina's domain |
| ERP integration (SAP, Oracle) | Out of MVP scope per CLAUDE.md |
| Supplier portal | Not MVP |
| Program/project management | Not a PLM core concern |
| Simulation/analysis data management | Post-MVP at earliest |

---

## Standards Alignment

### ISO 10303 AP242 (STEP)

STEP AP242 ("Managed Model-Based 3D Engineering") is the successor to AP203
and AP214. It covers:
- Product structure (BOM) and configurations
- 3D geometry exchange
- PDM metadata (items, revisions, documents)

Teamcenter can import/export STEP AP242 files. For Patina, STEP AP242 is
relevant as an **export format** for interoperability with CAD tools and
other PLM systems — not as a primary data format. MVP: not required.
Post-MVP: STEP AP242 export of item + BOM data is a target.

### IEC 82045

Document management standard. Covers:
- Document identification and metadata
- Document lifecycle (draft, review, approved, obsolete)
- Version and revision management
- Document vault and access control

Teamcenter's document management implements IEC 82045 principles. Patina's
Document item type and file vault should align with IEC 82045's metadata
requirements (see standards.md for full analysis).

---

## Key Findings for Patina

1. **The Item / ItemRevision split is correct.** Stable entity (Item) +
   versioned snapshot (ItemRevision) is the right abstraction. Patina adopts
   this.
2. **Alphabetic revision letters tied to lifecycle release** are the industry
   norm. Patina adopts this (see ADR-003).
3. **Four lifecycle states are sufficient for MVP.** In Work / Under Review
   / Released / Obsolete covers the essential workflow.
4. **BOM precision (precise vs imprecise) matters.** Patina should support
   both from Phase 3, with precise assembly as the primary mode.
5. **Revision rules are important for BOM queries** but add complexity.
   Implement "latest released" and "specific revision" for Phase 3; defer
   full rule engine.
6. **Change management needs its own object model** (not just a lifecycle
   type). PR/CR/EO is the minimum viable change process.

---

## References

- PLM Coach Teamcenter guide: https://plmcoach.com/siemens-teamcenter-plm-guide/
- Teamcenter Item data model: https://plmhandbook.blogspot.com/2020/08/teamcenter-item-business-object-item.html
- Teamcenter DB design: https://medium.com/@mjvibhute/plm-teamcenter-database-design-a5a92a06fb6e
- Revision rules: https://www.swooshtech.com/2022/07/22/revision-rules-in-teamcenter/
- Change management: https://www.swooshtech.com/2021/10/29/teamcenter-engineering-change-process-and-workflows/
- STEP AP242: https://www.prostep.org/en/medialibrary/fact-sheets/iso-10303-242-step-ap242
