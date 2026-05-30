# Prior Art: FreeCAD PDM Community Needs
Status: COMPLETE

Sources: FreeCAD forum (forum.freecad.org), FreeCAD GitHub issues,
community PDM projects (FreePDM, nanoPLM, Taack PLM)
Analysed: 2026-05-30

---

## Overview

FreeCAD is the dominant open-source 3D parametric CAD application. Its
community is the most accessible early-adopter base for an open-source PLM
system: they already use open-source tooling, they are cost-sensitive, and
they actively discuss the absence of PDM/PLM as a pain point.

This analysis is based on forum threads, GitHub issues, and community PDM
projects rather than interviews. Quotes are paraphrased from forum posts.

---

## Early Adopter Persona

The FreeCAD PLM user is typically:

- A **small manufacturer or machine builder** — often European (particularly
  German/Scandinavian), producing bespoke or low-volume mechanical products
- An **independent mechanical engineer** — freelance or at a company too
  small to justify enterprise PLM licensing
- A **hobbyist doing serious product design** — building something they
  intend to manufacture or sell
- Someone who **migrated from SolidWorks** for cost reasons and misses
  SolidWorks PDM (EPDM/WPDM) or an equivalent

They are comfortable with technical tools and are not afraid of self-hosted
software. They value data privacy and want to avoid vendor lock-in.

---

## User Pain Points

### 1. No native part identity

FreeCAD has no concept of a stable part number separate from the filename.
Parts are identified by their file path. Renaming a file breaks all assembly
references. There is no stable identifier that survives renaming.

### 2. No revision control for CAD files

Git is the go-to tool for version control, but it is poorly suited to CAD:

- FreeCAD files are binary (or quasi-binary); diffs are meaningless
- Even FreeCAD's text-based formats produce diffs with thousands of changed
  lines for minor geometry edits
- Branches and merges are impossible for CAD geometry

Users want a dedicated versioning system that understands CAD file semantics:
check-in / check-out, revision letters, baselines.

### 3. No lifecycle states

There is no way to mark a part as "released" or "approved". Parts exist in a
single undifferentiated state. This makes it impossible to distinguish
in-development parts from parts cleared for manufacturing.

A particularly cited need: a **pre-release state for materials procurement**
— a part is not yet formally released but its design is far enough along to
begin purchasing materials. This state needs to be separate from both "in
development" and "released".

### 4. Unstable BOM part numbers

FreeCAD's assembly BOM assigns sequential numbers to components. When a
component is removed, remaining components are renumbered. This breaks
revision tracking: a "part 7" in one assembly snapshot is not the same as
"part 7" in the next.

FreeCAD issue #16325 explicitly requests persistent BOM part numbering where
removed parts' numbers are retired rather than reused.

### 5. No approval / digital signing workflow

Parts cannot be formally approved by an authorised person. There is no
concept of a Change Control Board review, digital signature, or conditional
release.

### 6. No link between CAD file and change process

When a part changes, there is no mechanism to record why it changed, what
the previous state was, or who authorised the change.

### 7. Metadata management

Engineers need to attach metadata to parts (material, supplier, cost,
weight, surface treatment) and query that metadata without opening the CAD
file. There is no searchable part database.

---

## Desired Features

In order of frequency and urgency from community discussions:

1. **Stable part numbers** — persistent identifiers that survive assembly
   changes and file renames
2. **Check-in / check-out with revision letters** — formal revision tracking
   with user-visible labels (A, B, C…)
3. **Lifecycle states** — at minimum: Draft / Pre-release / Released /
   Obsolete
4. **BOM export with stable part numbers**
5. **File vault** — versioned storage of CAD files linked to item revisions
6. **Approval / sign-off workflow**
7. **Part metadata database** — searchable attributes
8. **ERP integration** — export to SAP or similar (often via BOM export)
9. **Works without internet access** — self-hosted, no cloud dependency

---

## Integration Expectations

- A **FreeCAD plugin** that connects to the PLM server — not embedded in
  FreeCAD core, but a workbench or add-on that syncs local files with the
  vault. OpenPLM already has a working plugin; users know this pattern.
- **File-based attachment**: the PLM system holds the canonical version of
  each file; the CAD tool checks out, edits locally, then checks back in.
- **Not a Git wrapper**: users who have tried Git-for-CAD are aware of its
  limitations; they want something that understands PLM semantics.
- **CAD-agnostic at the PLM level**: the PLM system manages Items and their
  attached files; it should not be coupled to FreeCAD specifically. Files
  from STEP, Inkscape, or a PDF should attach equally well.

---

## Target Persona

**Primary:** Small/medium manufacturer, 1–50 engineers, using FreeCAD as
their primary CAD tool. Has outgrown shared drives and spreadsheet BOMs but
cannot justify Teamcenter or Windchill licensing. Technically capable.
Self-hosts other infrastructure (Gitea, Nextcloud, etc.).

**Secondary:** Independent mechanical engineer or consultant managing
multiple client projects. Needs revision tracking and formal release records
for deliverables.

---

## Community PDM Projects

Several community attempts to fill the gap:

| Project | Language | License | Status | Notes |
|---------|----------|---------|--------|-------|
| **FreePDM** | Go | MIT | Early alpha (v0.1.3, 2025) | Backend only; no GUI yet |
| **nanoPLM** | Python | MIT | Active (Windows-first) | FreeCAD integration; local deployment |
| **Taack PLM** | Groovy/Grails | Unknown | Active | FreeCAD connector exists |
| **OpenPLM** | Python/Django | GPL v3 | Unmaintained | Has FreeCAD plugin; most complete but dead |

The existence of multiple independent attempts confirms strong community
demand. None has achieved significant adoption, largely due to:
- Lack of a usable UI
- Windows-only or single-platform limitations
- Abandonment before feature completion

Patina has an opportunity to be the canonical answer if it ships a working
self-hosted server with a FreeCAD connector early.

---

## Comparisons to Commercial Tools

Users most frequently compare against:

- **SolidWorks PDM (EPDM/WPDM)**: the aspirational benchmark for small
  manufacturers. Users miss it after switching to FreeCAD.
- **Windchill (PTC)** and **Teamcenter (Siemens)**: known but considered
  inaccessible (too expensive, too complex, too enterprise-focused).
- **OpenBOM**: web-based SaaS BOM management. Users appreciate its
  simplicity but dislike the cloud-only, paid model and the lack of CAD
  file integration.

---

## Key Findings for Patina

1. **The target user is real and underserved.** Enterprise PLM is too heavy;
   nothing good exists in the open-source space.
2. **Self-hosted is non-negotiable** for this audience. Cloud-only will not
   be adopted.
3. **A FreeCAD plugin should be a Phase 5 deliverable**, not a post-MVP
   thought. It is the primary route to early adoption.
4. **Lifecycle must include a pre-release procurement state** — not just
   Draft and Released. This is a recurring specific request.
5. **Stable item identity (part number) is the highest-priority feature**
   from this community's perspective. Everything else is secondary.
6. **The PLM must be CAD-agnostic at the data model level**. FreeCAD is the
   entry point but locking the schema to FreeCAD concepts would limit
   adoption.

---

## Notes

- FreeCAD forum blocks direct scraping; this analysis is based on search
  snippets, GitHub issues, and secondary sources. A follow-up with direct
  forum review is recommended before Phase 1 begins.

---

## References

- FreeCAD PDM forum thread: https://forum.freecad.org/viewtopic.php?t=68350
- FreeCAD BOM persistent numbering issue: https://github.com/FreeCAD/FreeCAD/issues/16325
- FreePDM: https://github.com/grd/FreePDM
- nanoPLM: https://github.com/alekssadowski95/nanoPLM
- Taack PLM: https://github.com/Taack/taack-plm-freecad
