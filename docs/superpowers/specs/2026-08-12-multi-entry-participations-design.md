# Multiple tagged entries per contingent per event

**Date:** 2026-08-12
**Status:** Approved design, pending implementation

## Problem

A contingent can currently appear at most once in a given event. `participations`
holds one row per `(contingent_id, event_id)` pair, and both admin "add" sheets
explicitly exclude pairs that already exist:

- `contingents_participated_page.dart:70` filters out contingents already in the event
- `events_participated_page.dart:104` filters out events the contingent is already in

Some events need a contingent to field more than one team. The admin must be able
to record separate marks for each, distinguished by a tag: `Ruby 1`, `Ruby 2`.

## Decisions

| Question | Decision |
|---|---|
| Tag format | Auto-numbered. No free text, no rename. |
| Display when only one entry exists | Plain `Ruby`. Numbers appear only once a second entry exists. |
| Where the admin adds a repeat entry | Both add-sheets (event side and contingent side). |
| What the contingent sees | Both entries, each labelled `Entry 1` / `Entry 2`. |

## Approach: derive the entry number, do not store it

The entry number is the row's position among all participations sharing the same
`(contingent_id, event_id)`, ordered by `participation_id`.

**No schema change. No migration. No backfill. No RPC changes.**

This matters concretely: the app authenticates with the anon/publishable key
(`main.dart:10`) and the repo contains no service-role key or database password,
so no DDL is possible from the codebase. The project owner has also lost access
to the Supabase dashboard. An approach requiring a migration would be blocked.

### Why not store an `entry_number` column

Storing it would give numbers that survive deletion of an earlier entry, but it
would require a migration, a backfill, and edits to both
`get_all_participations_rpc` and `get_my_participations_rpc` so they return the
new column. It also conflicts with the "plain when single" rule: after deleting
entry 1, a stored `2` still renders as plain `Ruby`, so the migration buys a
guarantee the UI immediately discards.

### Accepted trade-off

Deleting `Ruby 1` renumbers `Ruby 2` to `Ruby 1`. Under the "plain when single"
rule this is the desired behaviour: deleting one of two entries correctly leaves
the survivor displayed as plain `Ruby`, with no stale suffix.

## Risk: a possible UNIQUE constraint

If `participations` carries `UNIQUE (contingent_id, event_id)`, inserting a second
entry fails and this feature cannot ship without database access.

Evidence it likely does **not** exist:

1. Both add-sheets filter duplicates in the UI — the signature of an
   application-layer rule, not a database one.
2. Every write path (`update`, `delete`) keys off `participation_id` alone,
   implying it is the sole primary key.
3. No SQL file in the repo declares such a constraint.

This cannot be verified statically. It is settled empirically: after
implementation, log in as admin, add a second entry to a throwaway
contingent+event, observe whether it saves, delete the test row.

If the constraint does exist, one statement against the ETS project resolves it:

```sql
ALTER TABLE public.participations
  DROP CONSTRAINT IF EXISTS participations_contingent_id_event_id_key;
```

There is no acceptable application-only workaround. Modelling the second entry as
a shadow contingent or a duplicate event would corrupt the contingent list, the
event list, the CSV export, and the audit log. If the constraint exists, database
access must be recovered.

## Components

### `ParticipationController` — numbering

```dart
List<Participation> entriesFor(int contingentId, int eventId);
int entryNumberOf(Participation p);   // 1-based; 0 when it is the only entry
String suffixFor(Participation p);    // "" or " 2"
```

`entriesFor` sorts by `participation_id`. `entryNumberOf` returns `0` as the
sentinel for "sole entry", which drives the plain-label rule. `suffixFor` is the
single place the display convention lives, so changing it later touches one
function.

### Unchanged by design

`EventController.updateHighestMarks` (`event_controller.dart:174`) already takes
the max across all participations for an event regardless of contingent. Each
entry competes for "highest" on its own merit. No change.

`updateMultipleParticipationSameEvent` receives every participation for the event,
so its locally computed max stays correct.

The analytics page renders audit-log strings only and aggregates no marks.

## Changes by file

**Removing the duplicate filters**

- `contingents_participated_page.dart:70` — pass the full contingent list
- `events_participated_page.dart:104` — pass the full event list

**Add-sheets: show existing entry counts**

- `manage_contingents_modal.dart` — `AddContingentSheet` rows show an "N entries"
  badge where a participation already exists. Ticking adds one more.
- `manage_event_modal.dart` — `AddEventSheet`, same treatment.

**Labels**

- `manage_contingents_modal.dart:345` — `UpdateContingentSheet` field label
- `manage_event_modal.dart:298` — `UpdateEventSheet` field label
- `participation_card.dart:102` (admin) — contingent tile subtitle
- `grouped_participation_card.dart:144` — dropdown item text; without this, two
  entries render as identical options

**Contingent-facing**

- `participation_card.dart` (contingent) — new optional `entryNumber`; renders an
  "Entry 2" chip when the value is non-zero
- `scores_page.dart:199` — pass the entry number through

**Export**

- `participation_management_page.dart:136` — CSV gains an `Entry` column, always
  populated (`1` for singles). A separate column rather than a suffixed contingent
  code, so the sheet stays pivotable.

**Shared widgets** (`helpers/widgets.dart`)

- `buildEntryCountBadge(count)` — the "2 entries" pill in both add-sheets
- `buildEntryChip(entryNumber)` — the "Entry 2" label on the contingent's card

**Error handling**

- Both create methods — on Postgres error `23505`, show a plain explanation
  rather than the raw exception. This makes the constraint question answerable
  on first use.
- `23505` is ambiguous here: `participation_id` is generated client-side as
  `max+1`, so two admins saving simultaneously collide on the **primary key**
  and raise the same code. Messages mentioning `pkey` are reported as "another
  admin saved at the same moment, please try again"; only the others are
  reported as the schema constraint. Without this split, a routine race would be
  misdiagnosed as a blocking constraint.

## Implementation note

The two admin cards compute their own suffix via the `ParticipationController`
singleton, since they already depend on controllers. The contingent-facing card
stays presentational and receives `entryNumber` as a parameter from
`scores_page.dart`, so it keeps its lack of controller imports.

## Adjacent fix

`GroupedParticipationCard` tracks the selected entry by object identity
(`grouped_participation_card.dart:52` and `:67`), but `loadParticipations()`
rebuilds every `Participation` object on each refresh, so the dropdown resets to
the first item whenever realtime fires.

Today this is a minor annoyance. With multiple entries per event it becomes a
correctness problem: the admin selects "Ruby 2", a background refresh lands, and
they are silently looking at Ruby 1's marks. Fix by matching on `participationId`.

## Testing

- `entryNumberOf` returns `0` for a sole entry, `1`/`2` for two entries ordered by
  `participation_id`
- `suffixFor` returns `""` for a sole entry and `" 2"` for the second
- Deleting the first of two entries leaves the survivor at `0` (plain label)
- Adding a second entry does not disturb the first entry's marks
- `updateHighestMarks` picks the max across both entries of the same contingent
- CSV emits one row per entry with the correct `Entry` value

## Out of scope

- Renaming or free-text tags
- Reordering entries
- Any aggregate (sum/best) of a contingent's entries within one event
- Contingent-side filtering by entry
