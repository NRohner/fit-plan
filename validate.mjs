import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import { readFileSync } from "node:fs";

const DIR = ".";
const load = (p) => JSON.parse(readFileSync(`${DIR}/${p}`, "utf8"));

const ajv = new Ajv2020({ allErrors: true, strict: false });
addFormats(ajv);

const plan = load("plan.schema.json");
const log = load("log.schema.json");
const movement = load("movement.schema.json");
ajv.addSchema(plan).addSchema(log).addSchema(movement);

const cases = [
  // [schema $id, instance file, shouldPass]
  ["https://fit-plan.dev/plan.schema.json", "examples/plan.example.json", true],
  ["https://fit-plan.dev/log.schema.json", "examples/log.example.json", true],
  ["https://fit-plan.dev/movement.schema.json", "movements.json", true],
];

// Negative cases (inline) — the logic that must fail should fail.
const neg = [
  ["https://fit-plan.dev/plan.schema.json", { schemaVersion: "1.0.0", name: "x", days: [{ type: "rest", workouts: [{ type: "cardio", name: "c", activityType: "running", sets: [{ type: "main", duration: 1, durationUnits: "miles" }] }] }] }, "rest day with workouts"],
  ["https://fit-plan.dev/plan.schema.json", { schemaVersion: "1.0.0", name: "x", days: [{ type: "work" }] }, "work day with no workouts"],
  ["https://fit-plan.dev/plan.schema.json", { schemaVersion: "1.0.0", name: "x", days: [{ type: "work", workouts: [{ type: "strength", name: "s", sets: [{ movement: "", reps: 5, rounds: 1, weight: 10, weightUnit: "lbs" }] }] }] }, "empty movement name"],
  ["https://fit-plan.dev/plan.schema.json", { schemaVersion: "1.0.0", name: "x", days: [{ type: "work", workouts: [{ type: "cardio", name: "c", activityType: "flying", sets: [{ type: "main", duration: 1, durationUnits: "miles" }] }] }] }, "bad activityType"],
  ["https://fit-plan.dev/movement.schema.json", [{ id: 1, name: "x", description: "d", bodyPart: "elbow" }], "bad bodyPart"],
];

let fail = 0;
for (const [id, file, shouldPass] of cases) {
  const v = ajv.getSchema(id);
  const ok = v(load(file));
  const good = ok === shouldPass;
  if (!good) { fail++; console.log(`FAIL ${file}:`, v.errors); }
  else console.log(`ok   ${file} (valid=${ok})`);
}
for (const [id, data, label] of neg) {
  const v = ajv.getSchema(id);
  const ok = v(data);
  if (ok) { fail++; console.log(`FAIL (should reject) ${label}`); }
  else console.log(`ok   rejected: ${label}`);
}

// Graceful extensibility: an unknown future workout type validates against base only.
const future = { schemaVersion: "2.0.0", name: "x", days: [{ type: "work", workouts: [{ type: "yoga", name: "Vinyasa Flow", duration: 45 }] }] };
const pv = ajv.getSchema("https://fit-plan.dev/plan.schema.json");
if (!pv(future)) { fail++; console.log("FAIL future workout type rejected:", pv.errors); }
else console.log("ok   future 'yoga' workout accepted (base-only validation)");

console.log(fail === 0 ? "\nALL CHECKS PASSED" : `\n${fail} CHECK(S) FAILED`);
process.exit(fail === 0 ? 0 : 1);
