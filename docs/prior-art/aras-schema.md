# Prior Art: Aras Innovator Data Model
Status: COMPLETE

Source: Aras public documentation, community wiki, PLM alpha blog
Analysed: 2026-05-30

> **License note:** Schema observation from public documentation only.
> No Aras source code copied.

---

## Overview

Aras Innovator is a commercial, open-architecture PLM system. Its defining
characteristic is a **metadata-driven, model-based architecture**: all
business objects — Parts, Documents, BOMs, Change Requests — are defined as
XML-described ItemTypes stored *in the database itself*, not hard-coded in
application source. This makes the system highly customisable but adds
significant complexity.

---

## Core ItemType Schema

Every business object in Aras is an **Item**. The following properties are
present on *every* Item regardless of type:

### Identity and Lookup

| Property | DB Type | Description |
|----------|---------|-------------|
| `id` | char(32) | Primary key — 32-character GUID |
| `keyed_name` | nvarchar(128) | Human-readable name |
| `classification` | nvarchar(512) | Class path within ItemType taxonomy |

### Audit / Ownership

| Property | DB Type | Description |
|----------|---------|-------------|
| `created_on` | datetime | UTC creation timestamp |
| `created_by_id` | char(32) | FK to creating user |
| `modified_on` | datetime | UTC last-modified timestamp |
| `modified_by_id` | char(32) | FK to last modifying user |
| `owned_by_id` | char(32) | FK to owning identity |
| `managed_by_id` | char(32) | FK to managing identity |
| `team_id` | char(32) | FK to team (for permission delegation) |

### Locking and Permissions

| Property | DB Type | Description |
|----------|---------|-------------|
| `locked_by_id` | char(32) nullable | FK to user holding the lock; null = unlocked |
| `not_lockable` | char(1) | Item is in a non-lockable lifecycle state |
| `permission_id` | char(32) | FK to the permission set controlling access |

### Lifecycle

| Property | DB Type | Description |
|----------|---------|-------------|
| `current_state` | char(32) nullable | FK to the current lifecycle state record |
| `state` | nvarchar(32) | Denormalised state name (avoids join on common queries) |
| `is_released` | char(1) | '1' if currently in a released lifecycle state |

### Versioning

| Property | DB Type | Description |
|----------|---------|-------------|
| `config_id` | char(32) | ID of the *first* generation in this item's history; constant across all generations |
| `generation` | int | Ever-increasing counter; starts at 1, increments on every committed change |
| `is_current` | char(1) | '1' if this is the most recent generation for `config_id` |
| `major_rev` | nvarchar(8) | Revision letter (A, B, C…); increments on release lifecycle transition |
| `minor_rev` | nvarchar(8) | Reserved; not used out-of-the-box |
| `new_version` | char(1) | Signals version creation behaviour on save |
| `effective_date` | datetime | UTC date this revision first becomes valid |
| `release_date` | datetime | UTC timestamp of release |
| `superseded_date` | datetime | UTC date this revision was superseded |

---

## Versioning in Depth

Aras implements **three levels of versioning** on all versionable ItemTypes:

```
config_id (constant)
  └── major_rev A     ← first formal revision
      ├── generation 1  (initial creation)
      ├── generation 2  (saved edits, not yet released)
      └── generation 3  (saved edits, not yet released)
  └── major_rev B     ← incremented on Release lifecycle transition
      ├── generation 4
      └── generation 5  ← is_current = '1'
```

- **`generation`**: increments on every save. Internal, fine-grained. All
  edits are tracked. Users can control which generations are visible via
  permission rules.
- **`major_rev`**: business-meaningful revision label. Increments only when
  the item passes through the designated "Released" lifecycle state. Follows
  the alphabetic sequence defined in the ItemType's revision sequence
  (A → B → C … → AA → AB …).
- **`minor_rev`**: reserved field; not used in any out-of-the-box ItemType.
- **`config_id`**: the immutable anchor. All generations and revisions of the
  same logical item share the same `config_id`, making it possible to query
  the full history of an item with a single predicate.

The standard methodology is: **lifecycle engine triggers revision changes**.
ItemTypes are linked to a defined revision sequence (e.g. alphabetic), and
reaching the "Released" state triggers `major_rev` increment. This is
aligned with CMII (Configuration Management II) processes.

---

## Relationship Model

Relationships in Aras are **ItemTypes themselves**. Every relationship has:

| Property | Description |
|----------|-------------|
| `source_id` | FK to the owning (parent) item |
| `related_id` | FK to the linked item |
| `sort_order` | Numeric ordering |
| `behavior` | `"float"` or `"fixed"` (see below) |

### Float vs. Fixed Relationships

This is one of Aras's most important design decisions:

- **Float**: `related_id` always resolves to the *latest pre-release*
  generation of the related item. When an item is being worked on, references
  to it automatically follow the latest state.
- **Fixed**: After a lifecycle transition (e.g. the source item is released),
  `related_id` is locked to a specific generation. The reference becomes
  revision-sensitive.

Example: a Part-to-Document relationship starts floating (it follows the
latest document during development), then becomes fixed when the Part is
released to production.

Aras ships with 200+ built-in relationship types covering all PLM domains.

---

## Lifecycle Engine

- Each ItemType is linked to a **lifecycle definition** (a directed graph of
  states and allowed transitions).
- Lifecycle state controls three things simultaneously:
  1. **Permissions**: what roles can read/write in each state
  2. **Attribute visibility**: a 3-axis matrix of Role × LifecycleState ×
     Classification determines which properties are displayed (and which are
     required)
  3. **Revision transitions**: reaching a designated state triggers
     `major_rev` increment
- Promote and demote actions move items through the lifecycle.

---

## Key Architectural Decisions

1. **Everything is an ItemType.** There is no special treatment for "Part"
   vs "Document" vs "Change Request" at the schema level. All share the same
   base schema and the same services. This enables deep customisation but
   means the system's concept of "a Part" is entirely defined by metadata.

2. **AML (Adaptive Markup Language).** Aras uses XML as its canonical data
   format for all API interactions. Items, relationships, and queries are all
   expressed in AML. This is powerful but verbose.

3. **Model-based customisation.** Customers modify ItemTypes through a
   browser-based GUI (or by editing AML). Customisations survive upgrades
   because they are data, not code. Aras explicitly advertises this as a
   differentiator from hard-coded PLM systems.

---

## Key Findings

### Adopt

- **`config_id` pattern.** Grouping all generations of a logical item under
  a single immutable identifier is elegant and correct. Patina should adopt
  an equivalent concept: a stable item UUID that persists across all revisions.
- **`generation` as internal ever-incrementing counter.** Fine-grained audit
  trail without exposing internal noise to users. Patina should track internal
  versions separately from user-visible revision labels.
- **`major_rev` tied to lifecycle release.** Revision label increments only
  on release — not on every save. This is the right semantic: revision letters
  are business-meaningful, not technical artefacts.
- **Float / fixed relationship behaviour.** During development, BOM references
  float to the latest version; after release, they lock. Patina should
  implement this as a property of BOM line items.
- **Denormalised `state` name alongside `current_state` FK.** Avoids a join
  on the most common read pattern. Worth doing in Patina's schema.
- **`effective_date` / `release_date` / `superseded_date`.** Explicit date
  columns enable time-based queries ("what was the BOM on date X?") without
  complex joins.

### Improve

- **Metadata-driven ItemType system.** Powerful but introduces a whole layer
  of runtime schema management. For Patina, a fixed Rust domain type system
  with PostgreSQL JSONB for extensible attributes is simpler, more
  performant, and more auditable. The domain types should be first-class Rust
  types, not runtime metadata.
- **Three versioning levels (major/minor/generation).** `minor_rev` is
  unused and adds confusion. Patina: `revision` (user-visible letter/number,
  increments on release) + internal `version` (increments on every
  committed change).

### Discard

- **AML / XML as canonical data format.** JSON + a clean REST API is simpler
  and more widely supported.
- **200+ built-in relationship types.** For an MVP, define only the
  relationships actually needed. Adding more is cheap; removing wrong ones
  is not.
- **"Everything is an ItemType" dynamic schema.** Complexity cost is too
  high for a greenfield system without an existing customer base requiring
  that flexibility. Fixed domain schema is better for Patina MVP.

---

## References

- Aras architecture blog: https://aras.com/en/blog/25-years-of-aras-innovator-architecture-built-for-ai
- Standard properties reference: https://github.com/erdomke/Innovator.Client/wiki/Standard-Properties
- Versioning levels: https://plmalpha.wordpress.com/2012/04/17/version-revision-release-levels-in-aras/
- Float on release: https://youssefafech.dk/2026/04/28/float-on-release-in-aras-innovator-when-released-data-should-move-forward/
