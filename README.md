# fit-plan

An open-source JSON schema for **planning**, **tracking**, and **logging**
workouts.

## Goals

- Represent workout **plans** — the structure of plans, workouts, and their data.
- **Log** workouts and how they deviate from the plan. Deviation is captured as
  *prescribed* values (in the plan) versus *actual* values (in the log): if the
  plan calls for 10 reps but you complete 8, the log records 8. An actual of `0`
  means the set was completely skipped.
- Handle both **cardio** and **strength** workouts.
- Stay **backwards compatible**. New workout types added in future versions
  validate gracefully against older validators (see [Versioning](#versioning--extensibility)).

## Files

| File | Purpose |
|------|---------|
| `plan.schema.json` | A workout plan. Prescribed values only. |
| `log.schema.json` | A performed session. Actual values + a reference to a plan. |
| `movement.schema.json` | Schema for the movement library. |
| `movements.json` | The movement library — 873 movements; a canonical name catalog with descriptions, body parts, and links. |
| `examples/` | A complete, valid example plan and log. |
| `LLM_GUIDE.md` | How to have an LLM author plans/logs against this schema. |
| `validate.mjs` | Validates the schemas, examples, and library. |

All documents are [JSON Schema 2020-12](https://json-schema.org/).

## Plan structure

A **plan** is an ordered list of **days**. Each day is either `work` or `rest`.
A work day contains **at least one workout**; a rest day contains **no**
workouts.

```jsonc
{
  "schemaVersion": "1.0.0",   // required, "MAJOR.MINOR.PATCH"
  "name": "Push/Pull/Legs",   // required
  "notes": null,              // optional
  "days": [                   // required, >= 1
    { "type": "work", "name": "Push", "workouts": [ /* ... */ ] },
    { "type": "rest", "name": "Recovery" }
  ]
}
```

| Field | Where | Rule |
|-------|-------|------|
| `schemaVersion` | plan | required string, `MAJOR.MINOR.PATCH` |
| `name` | plan | required, non-empty |
| `days` | plan | required array, ≥ 1 |
| `type` | day | `"work"` or `"rest"` |
| `workouts` | day | required on work days (≥ 1); **absent** on rest days |
| `name`, `notes` | day | optional |

## Workouts

Every workout has a `type` and a `name`. Two types are defined — `cardio` and
`strength` — and each has its own set structure.

### Cardio

Required fields: `type` (`"cardio"`), `name`, `activityType`, and at least one
**Set** or **Set Block**.

```jsonc
{
  "type": "cardio",
  "name": "Zone 2 Run with Strides",
  "activityType": "running",
  "sets": [ /* Cardio Set or Set Block, >= 1 */ ]
}
```

`activityType` enum:

| Value | Meaning |
|-------|---------|
| `running`, `cycling`, `swimming`, `rowing` | as named |
| `gym_cardio` | stair master, elliptical, HIIT class, etc. |
| `general_cardio` | catch-all for anything else (e.g. tennis) |

**Cardio Set** — a single unit of work:

| Field | Rule |
|-------|------|
| `type` | required: `"warmup"`, `"main"`, or `"cooldown"` |
| `duration` | required number > 0 (time or distance) |
| `durationUnits` | required: `seconds`, `minutes`, `hours`, `miles`, `kilometers`, `yards`, `meters` |
| `effort` | optional heart-rate zone: `z0`–`z5`, or `null`. `z0` = recovery (below `z1`). |
| `notes` | optional string or `null` |

**Cardio Set Block** — a group of sets performed together:

| Field | Rule |
|-------|------|
| `sets` | required array of Cardio Sets, ≥ 1 |
| `reps` | required integer ≥ 1 — times the block is repeated |
| `notes` | optional string or `null` |

### Strength

Required fields: `type` (`"strength"`), `name`, and at least one **Set** or
**Set Block**.

```jsonc
{
  "type": "strength",
  "name": "Chest & Shoulders",
  "sets": [ /* Strength Set or Set Block, >= 1 */ ]
}
```

**Strength Set** — a single movement repeated:

| Field | Rule |
|-------|------|
| `movement` | required, non-empty movement **name** (see [Movement library](#movement-library)) |
| `reps` | required integer ≥ 0. **`0` = perform to failure.** |
| `rounds` | required integer ≥ 0. `10` reps × `4` rounds = 40 total. |
| `weight` | required integer ≥ 0. **`0` = bodyweight / no added weight.** |
| `weightUnit` | required: `"kg"` or `"lbs"` |

**Strength Set Block** — a group of sets performed together (supersets,
circuits):

| Field | Rule |
|-------|------|
| `sets` | required array of Strength Sets, ≥ 1 |
| `reps` | required integer ≥ 1 — times the block is repeated |

## Logging

A **log** records a performed session in a separate document
(`log.schema.json`) that references a plan by name. It mirrors the plan's
structure but stores **actual** values, so deviation from the prescribed plan is
captured.

```jsonc
{
  "schemaVersion": "1.0.0",
  "planName": "Push/Pull/Legs",   // required — the plan this log corresponds to
  "date": "2026-07-08",           // required — YYYY-MM-DD
  "notes": null,
  "days": [
    {
      "type": "work",
      "planDayIndex": 0,           // optional — index into the plan's `days`
      "workouts": [{
        "type": "strength", "name": "Push",
        "sets": [
          { "movement": "Barbell Bench Press", "actualReps": 8, "actualRounds": 4, "actualWeight": 135, "weightUnit": "lbs" },
          { "movement": "Push-Ups", "actualReps": 0, "actualRounds": 0, "actualWeight": 0, "weightUnit": "lbs", "notes": "skipped" }
        ]
      }]
    }
  ]
}
```

Logged sets use `actual*` fields:

- Strength: `actualReps`, `actualRounds`, `actualWeight` (+ `weightUnit`, and an
  optional `notes` for why it deviated).
- Cardio: `actualDuration` (+ `durationUnits`, optional `actualEffort`, `notes`).

**An `actual*` value of `0` means the set was skipped.** Note this differs from
the plan's `reps: 0` (perform to failure) and `weight: 0` (bodyweight) — those
are prescriptions, `actual*: 0` is an outcome. Use the **same `movement` name**
as the plan so the log lines up with what was prescribed.

## Movement library

`movements.json` is the canonical catalog of movements. Strength sets reference a
movement by its **name** (the `movement` string) — there is no numeric id in the
plan/log. The library is the recommended vocabulary (for consistency across
documents and for UI autocomplete), but a plan is valid with any non-empty name.

Each movement:

| Field | Rule |
|-------|------|
| `id` | required, positive integer, unique within the library (the library's own key) |
| `name` | required, non-empty |
| `description` | required, non-empty |
| `bodyPart` | required enum (below) |
| `notes` | optional string or `null` |
| `link` | optional URI (or `null`) to a demo video/resource |

`bodyPart` enum: `lower_body`, `upper_body`, `core`, `full_body`, `chest`,
`bicep`, `tricep`, `back`, `shoulder`, `glute`, `hamstring`, `calf`, `quad`,
`neck`, `forearm`, `other`.

**Custom movements** are added simply by appending entries to the array (with a
new unique `id`). JSON Schema cannot enforce id uniqueness across the array, so
callers must keep ids unique.

## Versioning & extensibility

- `schemaVersion` on every plan and log tracks the schema version the document
  targets.
- Workout `type` is open: a workout only *must* have `type` and `name`. Known
  types (`cardio`, `strength`) are validated fully; an unknown future type
  (e.g. `"yoga"`) passes base validation instead of being rejected — so a
  validator built for an older version accepts newer documents gracefully.

## Validation

```bash
npm i ajv ajv-formats
node validate.mjs
```

`validate.mjs` checks the schemas against the examples and the movement library,
plus a set of positive/negative cases (rest day with workouts, work day with no
workout, bad enum values, and a future workout type). See
`examples/plan.example.json` and `examples/log.example.json` for complete, valid
documents, and `LLM_GUIDE.md` for generating documents with an LLM.

## Attribution

The movement library (`movements.json`) is derived from
[free-exercise-db](https://github.com/yuhonas/free-exercise-db) by yuhonas,
released into the public domain under the [Unlicense](https://unlicense.org/).
Muscle groups were mapped to fit-plan's `bodyPart` enum, exercise instructions
into `description`, and metadata into `notes`.
