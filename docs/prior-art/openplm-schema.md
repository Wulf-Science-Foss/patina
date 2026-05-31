# Prior Art: OpenPLM Schema Analysis
Status: COMPLETE

Source: https://github.com/amarh/openPLM (GPL v3)
Analysed: 2026-05-30

> **License note:** openPLM is GPL v3. No code may be copied into Patina
> (MIT). This analysis is schema observation only.

---

## Overview

openPLM is a Django/Python PLM system developed primarily by Antoine Martin.
It is the only fully open-source PLM with a FreeCAD plugin. The codebase is
largely unmaintained since ~2017 but the data model is well-structured and
worth analysing in full.

---

## Database Schema

### Core Hierarchy

```
PLMObject (abstract base)
├── Part
└── Document
    ├── Design
    │   ├── Drawing
    │   │   ├── CustomerDrawing
    │   │   └── SupplierDrawing
    │   ├── FMEA
    │   ├── Sketch
    │   ├── FreeCAD
    │   └── Patent
    └── (other document subtypes)
```

### PLMObject

The root model for all managed objects. Identified by a three-part natural
key: `(reference, type, revision)`.

| Field | Type | Notes |
|-------|------|-------|
| `reference` | CharField(50) | Object reference code (e.g. `PART_1759`) |
| `type` | CharField(50) | Python class name (e.g. `Part`, `Drawing`) |
| `revision` | CharField(50) | Free-form string (e.g. `a`, `b`, `1.0`, `A.a.1`) |
| `reference_number` | IntegerField | Numeric form of reference for sorting |
| `name` | CharField(100) | Human-readable name |
| `description` | TextField | Rich text description |
| `creator` | FK → User | |
| `owner` | FK → User | |
| `ctime` | DateTimeField | Creation timestamp |
| `mtime` | DateTimeField | Auto-updated on change |
| `group` | FK → GroupInfo | Owning group |
| `lifecycle` | FK → Lifecycle | default: `get_default_lifecycle()` |
| `state` | FK → State | default: `get_default_state()` |
| `published` | BooleanField | Whether publicly visible |

**Unique constraint:** `(reference, type, revision)`

**Computed state properties:** `is_draft`, `is_official`, `is_deprecated`,
`is_cancelled`, `is_proposed` — all cached properties.

**Promotion logic:** `is_promotable()` / `_is_promotable()` validate whether
the object can advance to the next lifecycle state.

### Part

Inherits all PLMObject fields. Adds no fields of its own. The model carries:

- `PartManager` with `with_children_counts()` / `with_parents_counts()`
  annotations via SQL subquery
- `TopAssemblyManager` filtering parts that have children but no parents
  (i.e. root assemblies)
- `is_promotable()` override: a Part cannot be promoted if any of its
  children are not in their official state

### Document

Inherits all PLMObject fields. Adds:

| Field | Type | Notes |
|-------|------|-------|
| `template` | FK → Document (nullable) | Document used as template |

`ACCEPT_FILES = True` class attribute — signals that this type can have files
attached.

### DocumentFile

The file attachment record. Separate from Document (one Document can have
many files, each with its own revision chain).

| Field | Type | Notes |
|-------|------|-------|
| `filename` | CharField(200) | |
| `file` | FileField | Stored in document file storage |
| `size` | PositiveIntegerField | Bytes |
| `thumbnail` | ImageField | Auto-generated preview |
| `locked` | BooleanField | Checked-out lock |
| `locker` | FK → User (nullable) | Who has it locked |
| `document` | FK → Document | Owning document |
| `deprecated` | BooleanField | Superseded by newer file revision |
| `ctime` | DateTimeField | |
| `end_time` | DateTimeField (nullable) | Set when deleted |
| `deleted` | BooleanField | Soft delete |
| `revision` | IntegerField | Integer sequence (file-level, not PLMObject revision) |
| `previous_revision` | OneToOneField → self (nullable) | Prior file revision |
| `last_revision` | FK → self (nullable) | Current tip of the file revision chain |

---

## Lifecycle Model

### State

Single field: `name` (CharField(50), unique). States are just named tokens.

### Lifecycle

| Field | Type | Notes |
|-------|------|-------|
| `name` | CharField(50) unique | |
| `official_state` | FK → State | The "released" state for this lifecycle |
| `type` | PositiveSmallIntegerField | STANDARD / CANCELLED / ECR / TEMPLATE |

Lifecycle types:
- `STANDARD` (1) — normal item lifecycle
- `CANCELLED` (2) — represents the cancelled terminal state
- `ECR` (3) — used by Engineering Change Request objects
- `TEMPLATE` (4) — lifecycle used for template documents

### LifecycleStates (join table)

Ordered list of states in a lifecycle.

| Field | Type |
|-------|------|
| `lifecycle` | FK → Lifecycle |
| `state` | FK → State |
| `rank` | PositiveSmallIntegerField |

Unique constraint: `(lifecycle, state)`.

`first_state` and `last_state` are cached properties. The default lifecycle
is named `"draft_official_deprecated"` with states ordered: draft → official
→ deprecated.

### Promotion Rules

- Reaching `official_state` pushes the prior official revision of the same
  object to deprecated.
- All other non-official revisions of the same object are cancelled.
- A Part cannot be promoted unless all its BOM children are in official state.

---

## Revision Scheme

- Revision is a **free-form string** — no enforced naming convention in the
  data model. Examples used in documentation: `a`, `b`, `1.0`, `A.a.1`.
- Objects are named as `type // reference // revision // name`.
- `RevisionLink` records the old → new succession when a new revision is
  created from an existing one.

---

## BOM Structure

### ParentChildLink

Soft-deletable link between two Parts. The `end_time` field preserves history
(a null `end_time` means the link is current).

| Field | Type | Notes |
|-------|------|-------|
| `parent` | FK → Part | |
| `child` | FK → Part | |
| `quantity` | FloatField | Default 1 |
| `unit` | CharField | From UNITS choices |
| `order` | PositiveSmallIntegerField | Display order |
| `end_time` | DateTimeField (nullable) | Set when link is removed |

Unique constraint: `(parent, child, end_time)` — allows the same pair to be
added, removed, and re-added over time while preserving history.

`ParentChildLinkExtension` — abstract extension system allowing pluggable
extra attributes on BOM lines (e.g. CAD-specific metadata).

---

## Change Management (ECO/ECR)

openPLM does not have a dedicated ECO/ECR data model. Change requests are
implemented as PLMObjects with `lifecycle.type = ECR`. The wiki indicates a
more complete ECR workflow was planned but never fully implemented. This is
a significant gap.

---

## Other Link Types

| Model | Purpose |
|-------|---------|
| `RevisionLink` | Tracks old → new PLMObject supersession |
| `DocumentPartLink` | Associates a Document with a Part |
| `DelegationLink` | User-to-user role delegation |
| `PLMObjectUserLink` | User ↔ PLMObject with role assignment |
| `PromotionApproval` | Records sign-off on lifecycle state promotions |
| `AlternatePartSet` | Group of interchangeable parts |

---

## Key Findings

### Adopt

- **Configurable lifecycle as an ordered sequence of named states.** The
  `official_state` designator cleanly separates "what is released" from "what
  states exist." Patina should adopt this pattern.
- **BOM parent-child link with `end_time` for temporal history.** Preserving
  deleted BOM lines with a timestamp rather than hard-deleting them is the
  correct approach for a system that must maintain audit trails.
- **RevisionLink for succession tracking.** Explicit old→new links make the
  revision graph queryable.
- **Promotion guards on Part children.** Preventing a parent from being
  released while its children are still in draft is a sound invariant.
- **Separate file revision chain (`DocumentFile.revision`).** Distinguishing
  file-level revisions (check-in/check-out) from PLMObject revisions (formal
  revision letter) is correct; they serve different purposes.

### Improve

- **Free-form revision string.** openPLM allows any string as a revision
  label, which hinders sorting and automation. Patina should define an
  explicit revision scheme (see ADR-003).
- **`(reference, type, revision)` as natural key.** The concept is right —
  identity should be stable and human-readable — but storing the Python class
  name as `type` couples the data model to implementation. Patina should use
  a proper item type registry.
- **ECR as just a lifecycle type.** This is too minimal; change requests need
  their own data model with affected-items relationships, impact analysis, and
  approval workflow.

### Discard

- **GPL v3 license.** No code can be copied.
- **Extension via monkey-patching** (`ParentChildLinkExtension` registry,
  dynamic module loading in `import_models()`). Fragile and hard to test.
  Patina should use explicit extension points or JSONB attributes.
- **`type` field as Python class name.** Tight coupling between data and code.
  Type should be an enum or registry entry, not a raw string reflecting
  implementation internals.

---

## References

- Source: https://github.com/amarh/openPLM
- Lifecycle spec: https://wiki.openplm.org/specs/lifecycle.html
- openPLM docs: https://openplm.org/docs/2.0/en/index.html
