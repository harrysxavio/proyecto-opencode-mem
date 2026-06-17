#!/usr/bin/env node
if (!process.argv.includes("--plan")) {
  console.error("Rollback execution is blocked in Phase 0. Use --plan.");
  process.exit(1);
}

console.log("ROLLBACK PLAN ONLY");
console.log("- Future rollback will restore files from an approved backup manifest.");
console.log("- Phase 0 has no runtime changes to roll back.");
