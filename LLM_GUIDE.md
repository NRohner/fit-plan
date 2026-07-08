# FitPlan LLM Authoring Guide

How to have an LLM generate workout **plans** and **logs** that validate against
this schema.

## Movements are named, not ID'd
A strength set names its movement directly with the **`movement`** string —
there is no ID lookup, and the library never needs to be in the prompt:
```jsonc
{ "movement": "Barbell Bench Press", "reps": 8, "rounds": 4, "weight": 135, "weightUnit": "lbs" }
```
Any non-empty name is valid. For consistency across documents (so analytics can
group the same movement), prefer **canonical names from `movements.json`** — the
873-entry catalog that also carries each movement's description, target
`bodyPart`, and demo link. A UI can use it for autocomplete; it is not required
for a plan to be valid.

## Output rules for the model
- Output **only** the JSON document — no prose, no markdown fences.
- Always include `schemaVersion`, and top-level `name` (plan) or
  `planName` + `date` (log).
- Rest days have **no** `workouts` key. Work days have **≥ 1** workout.
- Name movements with standard, specific names (e.g. "Romanian Deadlift",
  "Standing Dumbbell Curl"); prefer library names when you know them.
- Use Set Blocks for supersets/circuits/intervals rather than flattening.

## Document structure

### Plan (`plan.schema.json`)
```jsonc
{
  "schemaVersion": "1.0.0",           // required, "MAJOR.MINOR.PATCH"
  "name": "Push/Pull/Legs",           // required
  "days": [                           // required, >= 1
    { "type": "rest", "name": "..." },          // rest day: NO "workouts"
    {
      "type": "work",                            // work day: >= 1 workout
      "name": "Push",
      "workouts": [ /* Workout, see below */ ]
    }
  ]
}
```

### Workout — two types (extensible)
Every workout needs `type` and `name`. Known types are validated fully; unknown
future types (e.g. `"yoga"`) pass base validation so old validators don't reject
new documents.

**Strength workout:**
```jsonc
{
  "type": "strength",
  "name": "Chest & Shoulders",
  "sets": [ /* strength Set or Set Block, >= 1 */ ]
}
```

**Cardio workout:**
```jsonc
{
  "type": "cardio",
  "name": "Zone 2 Run",
  "activityType": "running",          // required for cardio
  "sets": [ /* cardio Set or Set Block, >= 1 */ ]
}
```

### Sets and Set Blocks
A `sets` array holds **Sets** and/or **Set Blocks** (a group of sets repeated N
times — supersets, circuits, intervals).

**Strength Set:**
```jsonc
{ "movement": "Barbell Bench Press", "reps": 8, "rounds": 4, "weight": 135, "weightUnit": "lbs" }
```
| Field | Rule |
|-------|------|
| `movement` | non-empty movement name. |
| `reps` | integer ≥ 0. **0 = perform to failure.** |
| `rounds` | integer ≥ 0. 10 reps × 4 rounds = 40 total. |
| `weight` | integer ≥ 0. **0 = bodyweight / no added weight.** |
| `weightUnit` | `"kg"` or `"lbs"`. |

**Strength Set Block:**
```jsonc
{ "sets": [ /* strength Sets, >= 1 */ ], "reps": 3 }   // reps = times to repeat the block, >= 1
```

**Cardio Set:**
```jsonc
{ "type": "main", "duration": 5, "durationUnits": "miles", "effort": "z2", "notes": null }
```
| Field | Rule |
|-------|------|
| `type` | `"warmup"`, `"main"`, or `"cooldown"`. |
| `duration` | number > 0 (time or distance). |
| `durationUnits` | `seconds`, `minutes`, `hours`, `miles`, `kilometers`, `yards`, `meters`. |
| `effort` | optional heart-rate zone: `z0`–`z5` or `null`. `z0` = recovery. |
| `notes` | optional string or `null`. |

**Cardio Set Block:** `{ "sets": [ /* cardio Sets */ ], "reps": 6, "notes": null }`

## Log (`log.schema.json`)
A log records a **performed** session and references a plan by name. Fields hold
**actual** values so deviation is captured.
```jsonc
{
  "schemaVersion": "1.0.0",
  "planName": "Push/Pull/Legs",       // the plan this logs (the reference)
  "date": "2026-07-08",               // YYYY-MM-DD
  "days": [
    {
      "type": "work",
      "planDayIndex": 0,               // optional: which plan day this maps to
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
Key difference from the plan: `actualReps` / `actualRounds` / `actualWeight` /
`actualDuration`, and **`actual*` of 0 means the set was SKIPPED** (distinct from
a plan's `reps: 0` = to-failure). Logged strength sets accept an optional
`notes` for why a set deviated. Use the **same `movement` name** as the plan so
the log lines up with what was prescribed.

## Validate
```bash
npm i ajv ajv-formats
node validate.mjs
```
See `examples/plan.example.json` and `examples/log.example.json` for complete,
valid documents.
