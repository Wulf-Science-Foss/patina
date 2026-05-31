# Prior Art: Standards Analysis
Status: COMPLETE

Analysed: 2026-05-30

Standards covered: ISO 10007:2017, IEEE 828-2012, IEC 82045, CMII (ICMM),
ISO 10303 AP242 (STEP), ISO 8000

> ITIL excluded: IT service management framework, wrong domain. ITIL manages
> IT infrastructure assets (servers, services); Patina manages engineering
> configuration items (parts, documents, BOMs). The terminology overlap
> (change management, CIs) is superficial.

---

## ISO 10007:2017 — Configuration Management

### Scope

International standard for configuration management (CM) in product
development and production. Defines CM as a management discipline for
establishing and maintaining consistency between a product's functional and
physical attributes and its product information.

### Key Requirements

CM is defined as four activities:

1. **Configuration identification**: assign unique identifiers to each
   configuration item (CI); define what constitutes a CI; establish
   baselines.
2. **Configuration control**: process for requesting, evaluating, and
   approving or rejecting changes to a CI; change documentation.
3. **Configuration status accounting**: recording and reporting the status
   of CIs and changes throughout the product lifecycle.
4. **Configuration audit**: verify that a CI conforms to its specifications
   and that changes have been properly incorporated.

A **baseline** is a formally approved configuration of a CI, established at
a specific point in time. Changes to a baseline require authorised change
control.

### Implications for Patina

- Every managed item must have a **unique identifier that persists across its
  lifetime** (Item ID in Teamcenter terminology; `item_number` in Patina).
- Revision letters are the mechanism for recording baseline snapshots.
- The change process (ECR/ECO) must produce a **change record** that is
  retained and queryable.
- Audit log must capture all state transitions and change events.

### Adopt / Deviate

| Requirement | Patina decision |
|-------------|----------------|
| Unique CI identifier | **Adopt**: stable `item_number` + revision letter |
| Baseline at each release | **Adopt**: ItemRevision represents a baseline |
| Change control process | **Adopt**: ECR→ECO flow (Phase 4) |
| Status accounting | **Adopt**: audit log on all state changes (Phase 2) |
| Configuration audit | **Defer**: formal audit trail in Phase 2; audit functions in post-MVP |

---

## IEEE 828-2012 — CM in Systems and Software Engineering

### Scope

IEEE standard prescribing the minimum required activities for configuration
management in systems and software engineering projects. More prescriptive
than ISO 10007; defines specific activities, records, and roles.

### Key Requirements

IEEE 828 defines CM as five activities:

1. **CM Planning**: define the CM process, tools, and responsibilities for a
   project. Produce a Software Configuration Management Plan (SCMP).
2. **Configuration identification**: select CIs; assign identifiers; define
   the baselines that the CIs must satisfy.
3. **Configuration control**: evaluate change requests via a **Change Control
   Board (CCB)**; track the disposition of each change request; produce
   Change Requests (CR) and Change Notices (CN).
4. **Configuration status accounting**: produce status reports on the state
   of CIs, open change requests, and baseline status.
5. **Configuration audits**: Functional Configuration Audit (FCA) — verifies
   the CI meets its functional requirements; Physical Configuration Audit
   (PCA) — verifies the CI as-built matches its documentation.

Defines standard records:
- **Configuration Item (CI)**: anything placed under CM control
- **Baseline**: a set of CIs at a point in time, formally approved
- **Change Request (CR)**: a proposal to change a CI
- **Change Notice (CN)**: approved change, authorising implementation
- **Configuration Status Accounting Report**: periodic report of CI states

### Implications for Patina

- The **CCB concept** must be supported: approval workflows with named
  approvers and a formal decision record.
- **CR and CN are distinct records** — the request to change and the
  authority to implement are separate objects. Patina's change management
  must model this distinction.
- **Baselines** are explicitly named, approved snapshots. Patina needs a
  Baseline object (a named set of ItemRevisions) — not just individual
  revision letters.
- **Status accounting** implies queryable reports: "all CIs in state X",
  "all open CRs", "change history for item Y". These must be API endpoints.

### Adopt / Deviate

| Requirement | Patina decision |
|-------------|----------------|
| CCB approval flow | **Adopt**: approval workflow in Phase 4 |
| CR and CN as separate records | **Adopt**: ECR (request) and ECO (order/authority) are distinct objects |
| Named baselines | **Adopt post-MVP**: Baseline object in Phase 3/4 |
| Status accounting reports | **Adopt**: API endpoints for CM status queries |
| FCA/PCA audits | **Deviate intentionally**: formal audit ceremonies are out of scope for a software tool; the audit log provides the data, but the audit *process* is the operator's responsibility |

---

## IEC 82045 — Document Management

### Scope

Two-part standard for document management in engineering and technical
documentation:
- **Part 1**: Principles and methods
- **Part 2**: Metadata elements and information reference model

Covers the lifecycle, metadata, identification, and management of technical
documents.

### Key Requirements

**Document identification**: every document must have a unique identifier.
Documents and their revisions are distinct records.

**Metadata requirements** (Part 2 defines a reference model):
- Document number (unique identifier)
- Document title
- Document type/class
- Revision identifier
- Lifecycle status
- Author / creator
- Date of creation, revision, approval
- Language
- Security classification
- Referenced standards

**Document lifecycle**: Draft → Review → Approved → Obsolete (names vary
by organisation, but these four phases are the reference model).

**Version vs. revision**: IEC 82045 distinguishes between:
- **Version**: an interim change during document development (often
  incremental, e.g. 1.1, 1.2)
- **Revision**: a formally released update (A, B, C…)

### Implications for Patina

- The `Document` item type must carry the full metadata set defined in
  Part 2.
- The lifecycle for Document items should align with the IEC 82045
  reference model.
- File attachments (vault) are an integral part of document management —
  not an optional add-on.
- Document-to-Part relationships (a drawing attached to a Part) must be
  first-class.

### Adopt / Deviate

| Requirement | Patina decision |
|-------------|----------------|
| Unique document number | **Adopt**: `item_number` on Document items |
| Part 2 metadata fields | **Adopt**: required fields on Document item type |
| Draft/Review/Approved/Obsolete lifecycle | **Adopt**: maps to Patina's four lifecycle states |
| Version vs. revision distinction | **Adopt**: internal `version` (every save) + user-visible `revision` (on release) |
| Document-to-Part link | **Adopt**: `DocumentPartLink` equivalent in Phase 1/2 |

---

## CMII (ICMM) — Configuration Management II

### Scope

CMII is a process standard published by the Institute of Configuration
Management (ICMM). It extends CM beyond engineering into a business process
for managing all controlled information. It is the process foundation behind
Aras Innovator's out-of-the-box revision and change behaviour.

### Key Requirements

CMII defines the **Change Process** as the central discipline:

1. **Identify the need**: problem report or engineering change request
2. **Evaluate impact**: which items are affected; what is the cost/risk
3. **Authorise**: CCB approval
4. **Implement**: create new revisions; update affected assemblies
5. **Verify**: confirm implementation is correct
6. **Record**: update all documentation and status accounting records

CMII also defines the **release process**: no item may be manufactured or
procured against an unreleased revision. Formal release is a gate, not a
state.

The standard distinguishes between:
- **Configuration Item (CI)**: a work product placed under CM control
- **Baselined CI**: a CI at a specific revision, formally released
- **Change Notice (CN)**: the authorisation to change a CI; CN is the gate
  to implementation, not the request

### Implications for Patina

- The change process must model all five CMII phases, even if the UI
  simplifies them.
- The "release gate" principle: items in Draft/Review cannot be used in
  released assemblies. BOM float/fix behaviour must enforce this.
- CN (or Patina's equivalent ECO) is the authorisation record, not just a
  notification. It must capture: what was approved, by whom, and when.

### Adopt / Deviate

| Requirement | Patina decision |
|-------------|----------------|
| Five-phase change process | **Adopt**: ECR→CCB→ECO→implementation→verify flow |
| Release gate | **Adopt**: BOM lines in released assemblies must reference released revisions |
| CN as authorisation record | **Adopt**: ECO is the authorisation object with sign-off records |
| CMII revision sequence (alphabetic, lifecycle-triggered) | **Adopt**: A→B→C on release transition (see ADR-003) |

---

## ISO 10303 AP242 — PLM Data Exchange (STEP)

### Scope

ISO 10303 ("STEP") is the international standard for product data exchange.
AP242 ("Managed Model-Based 3D Engineering") is the current application
protocol, merging the automotive AP214 and aerospace AP203 standards.

AP242 covers:
- Product structure and BOM (with configuration management)
- 3D geometry (B-Rep, faceted, tessellated)
- PDM metadata (items, revisions, documents, changes)
- Kinematic and FEA data

### Key Requirements (relevant to Patina)

For Patina, the relevant subset of AP242 is the **PDM schema** (not the
geometry exchange). This covers:
- `product` entity: equivalent to an Item
- `product_definition` entity: equivalent to an ItemRevision
- `product_definition_relationship`: BOM line
- `configuration_item`: CI with baseline
- `action_request` / `action`: CR and CN equivalents
- `document` and `document_revision`: document and its revisions

### Implications for Patina

STEP AP242 is not a system design constraint for Patina's MVP — it is a
future **interoperability target**. Patina's data model should be designed
so that export to STEP AP242 PDM format is possible post-MVP, but we do not
need to follow the STEP schema internally.

The key mapping to ensure is:
- Patina Item → STEP `product`
- Patina ItemRevision → STEP `product_definition`
- Patina BOM line → STEP `product_definition_relationship`

### Adopt / Deviate

| Requirement | Patina decision |
|-------------|----------------|
| STEP as internal format | **Deviate**: too verbose; Patina uses PostgreSQL + REST JSON |
| STEP AP242 export | **Defer to post-MVP**: design the domain model to be mappable |
| Product/ProductDefinition split | **Adopt by analogy**: Item / ItemRevision mirrors this split |

---

## ISO 8000 — Data Quality

### Scope

International standard for data quality in master data management. Relevant
parts for Patina:
- **Part 8**: Vocabulary (definitions of data quality concepts)
- **Part 61**: Requirements for quality of master data — syntax, semantic
  encoding, conformance to authoritative sources

### Key Requirements

- **Syntactic quality**: data must conform to a defined format or schema
  (e.g. item numbers must match a defined pattern)
- **Semantic quality**: data must accurately represent the real-world entity
  (e.g. a part number must uniquely identify one physical part)
- **Provenance**: the origin and history of data must be traceable

### Implications for Patina

- Item numbers must have **enforced syntax** — not free-form strings. The
  numbering scheme must be configurable but validated on input.
- Every item must have a clear **provenance record**: created by, created at,
  and a full history of changes.
- **No orphaned revisions**: every ItemRevision must have a valid parent Item.
  Referential integrity must be enforced at the database level.

### Adopt / Deviate

| Requirement | Patina decision |
|-------------|----------------|
| Enforced item number syntax | **Adopt**: configurable regex/pattern with DB constraint |
| Provenance (creator, timestamps, history) | **Adopt**: audit log + created_by/created_at on all entities |
| Referential integrity | **Adopt**: foreign key constraints enforced, no soft-delete orphaning |
| Full ISO 8000 certification | **Deviate intentionally**: compliance in spirit; formal certification out of scope |

---

## Cross-Standard Findings

### Consistent patterns across all standards

1. **Every CI needs a stable unique identifier.** All six standards require
   this. Patina: `item_number` (stable) + `revision` (changes on release).

2. **Revision happens on formal release, not on every save.** ISO 10007,
   IEEE 828, CMII, and Aras's implementation all agree: revision letters
   are business events tied to lifecycle state transitions. Internal save
   history is separate.

3. **Change must be authorised before implementation.** IEEE 828's CCB,
   CMII's CN gate, and ISO 10007's change control all require that a change
   is approved before it is implemented in the released baseline.

4. **Audit trail is mandatory.** Status accounting (IEEE 828), provenance
   (ISO 8000), and change records (all standards) require a complete,
   queryable history of what changed, when, and by whom.

5. **Baselines are explicit records.** A released ItemRevision is a baseline.
   Patina must be able to reproduce the exact state of any BOM at any point
   in its history.

### Tensions and design decisions

- **ISO 8000 enforced syntax vs. flexibility**: Patina will enforce item
  number format via configuration, but must allow operators to define their
  own scheme. Hard-coded format would break ISO 8000 for operators with an
  existing numbering standard.
- **STEP AP242 interoperability vs. simplicity**: Patina's internal schema
  should be STEP-mappable but not STEP-shaped. The Item/ItemRevision split
  already achieves this.
- **IEEE 828 baselines vs. MVP scope**: Named baselines (a snapshot of a
  full product structure) are an IEEE 828 requirement but are Phase 3/4
  scope for Patina. The audit log provides the data needed to reconstruct
  any historical state even without explicit Baseline objects.

---

## References

- ISO 10007:2017: https://www.iso.org/standard/70400.html
- IEEE 828-2012: https://standards.ieee.org/ieee/828/4578/
- IEC 82045-1 / IEC 82045-2: https://www.iec.ch/
- CMII / ICMM: https://www.icmhq.com/
- ISO 10303 AP242: https://www.prostep.org/en/medialibrary/fact-sheets/iso-10303-242-step-ap242
- ISO 8000-61: https://www.iso.org/standard/57797.html
