# Prior Art Summary
Status: COMPLETE

Synthesises findings from:
- [OpenPLM schema analysis](openplm-schema.md)
- [Aras Innovator data model](aras-schema.md)
- [FreeCAD community needs](freecad-community-needs.md)
- [Teamcenter feature baseline](teamcenter-baseline.md)
- [Standards analysis](standards.md)

**Gate:** Phase 1 does not begin until this document is reviewed and
committed.

---

## Domain Vocabulary (Ubiquitous Language)

These terms are used consistently across all Patina specifications, code,
and documentation. Where a term differs from a prior-art system's usage,
the prior-art system's term is noted in parentheses.

| Term | Definition |
|------|------------|
| **Item** | A managed object representing a product, component, or document. An Item has a stable identity across all revisions. Equivalent to Teamcenter *Item*, Aras *Item* (with a part or document ItemType). |
| **ItemRevision** | A formally versioned snapshot of an Item. Created when an Item is released. Identified by `item_number/revision` (e.g. `000123/A`). Equivalent to Teamcenter *ItemRevision*, openPLM *PLMObject at a given revision*. |
| **item_number** | The stable, unique identifier for an Item. Never changes. Operator-configurable format; enforced by schema constraint. Equivalent to Teamcenter *Item ID*, Aras *config_id* (the stable cross-generation anchor). |
| **revision** | The user-visible label for an ItemRevision. Alphabetic by default (A → B → C). Increments only on lifecycle release. Distinct from internal *version*. |
| **version** | An internal, ever-incrementing counter on an ItemRevision that increments on every saved change. Not user-visible by default. Equivalent to Aras *generation*, Teamcenter *iteration/sequence*. |
| **lifecycle** | A named, ordered sequence of states that an ItemRevision passes through. Configurable per item type. |
| **state** | A named position in a lifecycle (e.g. In Work, Under Review, Released, Obsolete). An ItemRevision is always in exactly one state. |
| **release** | The act of transitioning an ItemRevision to the `Released` state. Triggers: revision letter increment on the successor, BOM reference locking. |
| **BOM** | Bill of Materials. A set of BOM lines describing the child components of an assembly ItemRevision. |
| **BOM line** | One entry in a BOM: a reference to a child ItemRevision, with quantity, unit, and find number. |
| **float reference** | A BOM line whose child reference resolves to the latest pre-release version of the child Item. Used during development. |
| **fixed reference** | A BOM line whose child reference is locked to a specific ItemRevision. Applied when the parent is released. |
| **ECR** | Engineering Change Request. A formal request to change one or more Items. Initiates the change process. |
| **ECO** | Engineering Change Order. The authorisation to implement a change. Produced after CCB approval of an ECR. Equivalent to Teamcenter *Engineering Order*, CMII *Change Notice*. |
| **CCB** | Change Control Board. The group of people authorised to approve or reject an ECR. |
| **baseline** | A named, approved snapshot of a set of ItemRevisions at a point in time. Equivalent to IEEE 828 *baseline*. Post-MVP. |
| **Part** | An Item subtype representing a physical or logical component. |
| **Document** | An Item subtype representing a technical document (drawing, specification, report). |
| **vault** | The file storage component. Stores files attached to ItemRevisions. |
| **dataset** | A file or set of files attached to an ItemRevision. Equivalent to Teamcenter *Dataset*. |
| **check-out / check-in** | The act of locking an ItemRevision for editing (check-out) and committing a new version (check-in). |

---

## Cross-System Findings

### Common patterns to adopt

**1. Item / ItemRevision split**
Every system studied (Teamcenter, Aras, openPLM) separates the stable entity
(Item, with a permanent identifier) from the versioned snapshot (ItemRevision,
with a revision label). This is the right abstraction. The Item ID never
changes; revision letters change on release. ISO 10003 AP242 (`product` /
`product_definition`) and IEEE 828 (CI / baseline) confirm the same split.

**2. Revision label increments on lifecycle release, not on every save**
Aras's `generation` / `major_rev` split, openPLM's check-in revision vs.
PLMObject revision, and Teamcenter's iteration vs. revision letter all
implement the same principle: there are two distinct version concepts —
internal fine-grained history and user-visible formal revision. Standards
(CMII, ISO 10007) agree: revision is a business event at the release gate.

**3. Configurable lifecycle as an ordered sequence of named states**
openPLM's `Lifecycle` + `LifecycleStates` model, Teamcenter's configurable
lifecycle, and Aras's per-ItemType lifecycle all provide a configurable,
ordered state machine. The IEC 82045 reference lifecycle (Draft / Review /
Approved / Obsolete) and the CMII release gate align with a four-state
default. Patina will ship a configurable lifecycle with a sensible default.

**4. BOM float / fix on release**
Aras's `behavior: float/fixed` on relationships, and Teamcenter's precise vs
imprecise assembly concept, both implement the same rule: during development,
BOM references float to the latest version of child items; after the parent
is released, references lock to specific child revisions. This is also what
CMII requires (released baselines must reference released CIs). Patina must
implement this.

**5. Permanent, queryable audit trail**
IEEE 828's status accounting, ISO 8000's provenance requirement, ISO 10007's
change records, and IEC 82045's document history all require the same thing:
a complete, non-deletable history of who changed what, when, and why. This
is not optional.

**6. Change request and change order are distinct records**
IEEE 828 (CR / CN), CMII (change request / Change Notice), and Teamcenter
(CR / EO) all distinguish between the *request* to change and the
*authorisation* to implement. Patina models these as ECR (request) and ECO
(order/authorisation). They are different objects with different lifecycles.

**7. Stable item number with enforced format**
ISO 8000, ISO 10007, IEEE 828, and all practical systems require that CI
identifiers are unique, stable, and syntactically controlled. Patina: the
`item_number` format is operator-configurable with regex validation, enforced
at the database level.

### Common patterns to discard

**Dynamic schema (Aras's "everything is an ItemType")**
The fully metadata-driven approach is powerful but extremely complex to
build, test, and audit. For Patina's domain (engineering PLM, not arbitrary
enterprise data), a fixed domain schema is simpler, more type-safe, and more
auditable. Extension is handled via JSONB attributes where needed.

**Free-form revision strings (openPLM)**
openPLM allows any string as a revision label. This prevents sorting,
automated sequence validation, and reliable interoperability. Patina uses a
configurable but constrained scheme (default: alphabetic; see ADR-003).

**ECR as just a lifecycle type (openPLM)**
Making ECR a lifecycle type on an arbitrary PLMObject, rather than a
first-class domain object, is insufficient. Change management needs
structured relationships (which items are affected), a CCB workflow, and
a formal authorization record. openPLM's approach cannot support this.

**GPL licensing**
openPLM is GPL v3. Patina is MIT. No code can be taken from openPLM.

### Gaps and improvements

**No open-source PLM has implemented float/fix BOM references**
Both openPLM and the community projects (FreePDM, nanoPLM) lack this. It is
an Aras and Teamcenter concept. Patina will be the first open-source PLM to
implement it.

**No open-source PLM has a standards-aligned change process**
openPLM's ECR is too minimal; community projects have none. The ECR / CCB /
ECO flow aligned with IEEE 828 and CMII is a significant differentiator.

**The FreeCAD community has no good option**
Multiple abandoned open-source PDM projects confirm demand but lack of
supply. A self-hosted, MIT-licensed PLM with a FreeCAD plugin would fill a
real gap. Patina's Phase 5 FreeCAD integration must be a first-class
deliverable.

---

## Recommended Scope for Phase 1

Phase 1 implements the **core domain model** only — no API, no UI, no
database. Pure Rust domain types with comprehensive tests.

The minimum domain model to implement, based on this prior art review:

| Domain type | Key fields | Notes |
|-------------|-----------|-------|
| `Item` | item_number, name, item_type | Stable entity |
| `ItemRevision` | item FK, revision, state, version | Versioned snapshot |
| `Lifecycle` | name, states (ordered) | Configurable state machine |
| `State` | name | Named lifecycle position |
| `Part` | extends Item | Physical/logical component |
| `Document` | extends Item | Technical document |

BOM (ParentChildLink), ECR/ECO, and vault are Phase 3/4 scope.

---

## Open Questions

1. **Revision scheme configurability**: should operators be able to define
   a numeric scheme (1, 2, 3…) as well as alphabetic (A, B, C…)? ADR-003
   must decide this.

2. **Baseline scope for Phase 3**: should Baseline be a first-class object
   in Phase 3 (BOM), or deferred to Phase 4? IEEE 828 requires it; the
   question is when.

3. **ECR visibility**: should ECRs be visible to all users with read access,
   or only to CCB members and the submitter? This affects the access control
   model in Phase 4.

4. **Item number format**: should the default format be operator-configurable
   from day one, or start with a fixed scheme (e.g. sequential numeric)?
   ADR to be written.

5. **Document vs. Part lifecycle**: should Part and Document share one
   configurable lifecycle, or should each have its own default? IEC 82045
   implies a document-specific lifecycle; Teamcenter has per-type lifecycles.
