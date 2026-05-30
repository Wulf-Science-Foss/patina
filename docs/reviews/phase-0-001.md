# Review: Phase 0 Prior Art — Round 001

**Branch:** `docs/phase-0`
**Authoring model:** Claude Sonnet 4.6
**Reviewing model:** Claude Opus 4.8
**Command:** `/code-review high`
**Date:** 2026-05-30
**Status:** CLOSED — fixes confirmed by round 002 ([`phase-0-002.md`](phase-0-002.md))

---

## How to use this document

The reviewing model records findings here. It does **not** fix them. The
authoring model then switches back in, fixes each finding, and fills in the
**Resolution** field with the commit or rationale. A finding is closed only
when its Resolution is filled and a subsequent review round confirms it.

Severity: **high** = must fix before PR; **medium** = must fix or explicitly
defer with recorded rationale; **low** = may defer.

---

## Findings

### F-001 — `item_number` mapped to the wrong Aras field [HIGH]

**Location:** `docs/prior-art/SUMMARY.md:26`

The vocabulary entry says `item_number` (the stable, never-changes
identifier) is "Equivalent to … Aras *keyed_name*." But `aras-schema.md:33`
defines `keyed_name` as the human-readable name, and the stable
cross-generation anchor in Aras is `config_id`. The summary contradicts its
own source document. The correct equivalent is `config_id`.

**Resolution:** Fixed in branch `docs/phase-0--fix-f001`. Changed "Aras
*keyed_name*" to "Aras *config_id* (the stable cross-generation anchor)" in
the vocabulary table.

---

### F-002 — "ItemRevision created when an Item is released" is wrong and self-contradictory [HIGH]

**Location:** `docs/prior-art/SUMMARY.md:25`

The `ItemRevision` definition states it is "Created when an Item is
released." This conflicts with, in the same corpus:

- The `state` vocabulary entry (line 30) listing *In Work* as a state an
  ItemRevision occupies.
- The `release` definition (line 31), which transitions an *existing*
  ItemRevision to Released.
- `teamcenter-baseline.md:64`, where revisions are created on the "Revise"
  action during work.
- The Phase 1 domain model (line 150), which gives ItemRevision a `state`
  field, implying it exists pre-release.

Revisions are created during work and *released* later. The definition
should reflect that an ItemRevision exists from creation in a draft/In Work
state and is released by a later state transition.

**Resolution:** Fixed in branch `docs/phase-0--fix-f002`. Rewrote the
vocabulary definition: ItemRevision is now described as created during
development (starting in the first lifecycle state, typically In Work), with
reaching Released being a state transition on the existing object, not the
creation event.

---

### F-003 — "ISO 10003 AP242" is a typo for ISO 10303 [MEDIUM]

**Location:** `docs/prior-art/SUMMARY.md:56`

The cross-system findings reference "ISO 10003 AP242". The correct standard
is **ISO 10303** (STEP). ISO 10003 is an unrelated standard (quality
management — customer satisfaction / complaints handling), so this is a
substantive factual error in a standards claim, not a cosmetic slip. Every
other reference in the corpus correctly says 10303.

**Resolution:** Fixed in branch `docs/phase-0--fix-f003`. "ISO 10003" →
"ISO 10303" in the cross-system findings section.

---

### F-004 — Lifecycle configurability stated as settled, then asked as open [LOW]

**Location:** `docs/prior-art/SUMMARY.md:29` vs `178–180`

The `lifecycle` vocabulary entry asserts "Configurable per item type" as
established fact, but Open Question 5 treats per-type-vs-shared lifecycle as
unresolved. Either soften the vocabulary entry to not pre-empt the open
question, or close the open question.

**Resolution:** Fixed in branch `docs/phase-0--fix-f004`. The distinction
is that the *mechanism* (configurable per item type) is settled, while the
*default configuration* for Part vs Document is the open question. Vocabulary
entry now states both halves explicitly. OQ-5 reworded to clarify it asks
only about the default, not the mechanism.

---

### F-005 — `item_number` enforcement layer conflicts with Phase 1 scope [LOW]

**Location:** `docs/prior-art/SUMMARY.md:26,97` vs `142–143`

`item_number` format is described as "enforced by schema constraint" /
"enforced at the database level," but the Phase 1 scope (where Item and
`item_number` are first implemented) states "no database. Pure Rust domain
types." Clarify that format validation lives in the domain layer, with the
database constraint as a later defence-in-depth layer — or adjust the scope
statement.

**Resolution:** Fixed in branch `docs/phase-0--fix-f005`. Both occurrences
updated: validation is "in the domain layer (Phase 1), with a database-level
constraint as defence-in-depth (Phase 2+)".

---

### F-006 — Review-severity policy has an undefined-severity gap [LOW]

**Location:** `CLAUDE.md:304–306` (as written in round 001)

The review-findings policy covered "high or above" (must fix) and "low" (may
defer) but left **medium** undefined and did not state the severity scale.
This is being addressed directly in the CLAUDE.md Review Policy update that
accompanies this review.

**Resolution:** Fixed by the reviewing model (Opus) as part of the same
review pass: a severity disposition table (High/Critical, Medium, Low) was
added to the Review Policy section in `CLAUDE.md` in branch
`docs/phase-0--review-loop`. No further author action required.

---

## Considered and dismissed

### D-001 — Phase 0 status still "TODO" / checklist boxes unchecked

**Location:** `docs/roadmap/phase-0-prior-art.md:3`, CLAUDE.md roadmap table

Initially raised as a completeness gap. **Dismissed:** this review runs
*before* the PR, so unchecked boxes and a TODO status are the correct,
expected state. Check-off is deferred to the automated merge-to-main flow
(see CLAUDE.md Phase Gate Checklist and CI / Actions). Re-reviews should not
re-raise this.

---

## Sign-off

- [x] All HIGH findings resolved
- [x] All MEDIUM findings resolved or deferred with rationale
- [x] Re-review round opened to confirm fixes (round 002 — CLEAN)
