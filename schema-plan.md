# FitPlan
## Goal: To create a JSON schema that is capable of containing workout plans, tracking those workouts, and logging workouts.

## Core Concepts
- This schema should be capable of representing workout plans, including the structure of plans, workouts, and their associated data.
- This schema should also be capable of logging workouts and how they deviate from the plan. I.E. if the plan calls for 10 reps of a lift but you can only complete 8 reps, the schema should be able to log that deviation. I personally think the best way to handle that is with a prescribed and an actual count of reps with 0 reps meaning that activity or set was completely skipped.
- The schema should be able to handle both cardio and strength workouts.
- The schema should be backwards compatible with previous versions. If new workout types are added in future versions, the schema should be able to handle them gracefully.

## Plan Structure

A plan is comprised of days. Each day can be categorized as either work or rest. Work days contain at least one workout, rest days do not contain any workouts.

## Workout Structure - Cardio
A cardio workout is comprised of the following mandatory fields:
- Workout Name
- Activity Type - this should be an enum with the values of either `running`, `cycling`, `swimming`, `rowing`, `gym_cardio`, or `general_cardio`.
  - Gym Cardio is for things like stair master, eliptical, HIIT class, that sort of thing.
  - General Cardio is really just a catch all for anythinig else not mentioned. Perhaps sports like tennis would fit here.
- At least one "Set" or "Set Block"

### Set - Cardio
A set is a single unit of a workout. Sets for cardio must have the following mandatory fields:
- Type - an enum of `warmup`, `main`, or `cooldown`.
- Duration - the duration of the set in either time or distance. 
- Duration Units - an enum of `seconds`, `minutes`, `hours`, `miles`, `kilometers`, `yards`, `meters`.

Sets for cardio may have the following optional fields:
- Effort - a nullable field that holds an enum for the heart rate zone for the set. The enum values should be `z0`, `z1`, `z2`, `z3`, `z4`, and `z5` wich each one corresponding zone 1 - zone 5. z0 here means recovery, basically a very low heart rate below z1.
- Notes - a nullable field that holds any additional notes for the set.

### Set Block - Cardio
A set block is a group of sets that are performed together. Set blocks for cardio must have the following mandatory fields:
- Sets - a list of sets that are performed together. There must be at least one set in the list.
- Reps - the number of reps for the set block. Must be a positive integer.

Set Blocks for cardio may have the following optional fields:
- Notes - a nullable field that holds any additional notes for the set block.

## Workout Structure - Strength
A workout structure for strength must have the following mandatory fields:
- Workout Name - a string that holds the name of the workout.
- Sets - A list of sets or set blocks that are performed together. There must be at least one set or set block in the list.


### Set - Strength
A set is a single movement that is repeated a certain number of times. Sets for strength must have the following mandatory fields:
- Movement ID - a positive integer that holds the ID of the movement. Movements can be found in the movements-library file (we will need to create this). Custom movements can be added by the user and are simply appended to the library file.
- Reps - the number of reps for the set. Must be a non-negative integer. A 0 in this field indicates it should be performed until failure.
- Rounds - the number of times the Reps should be performed. Must be a non-negative integer. For example, 10 reps and 4 rounds means the 10 reps should be performed 4 times for a total of 40 reps.
- Weight - the weight to be used for the set. Must be a non-negative integer. A 0 in this field indicates it should be performed without a weight.
- Weight Unit - the unit of weight to be used for the set. Must be an enum with the following options: "kg", "lbs"

### Set Block - Strength
A set block is a group of sets that are performed together. Set blocks for strength must have the following optional fields:
- Sets - a list of sets to be performed as part of the block. There must be at least one set in the list.
- Reps - The number of times to repeat the sets in the block. Must be a positive integer.

## Movement Library
A movement library is a file that holds a list of all the movements that can be performed in a workout. The library file is a JSON file that contains a list of movements, each with a unique ID and a name. Custom movements can be added by the user and are simply appended to the library file. The following fields are required for each movement:
- ID - a positive integer that holds the unique ID of the movement.
- Name - a string that holds the name of the movement.
- Description - a string that holds a description of the movement.
- Body Part - an enum that holds the body part that the movement targets with the following values: `lower_body`, `upper_body`, `core`, `full_body`, `chest`, `bicep`, `tricep`, `back`, `shoulder`, `glute`, `hamstring`, `calf`, `quad`, `neck`, `forearm`, `other`

The following are optional fields for each movement:
- Notes - a string that holds any notes about the movement.
- Link - a string that holds a link to a video or other resource that demonstrates the movement.
