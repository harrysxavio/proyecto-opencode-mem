#!/usr/bin/env node
if (!process.argv.includes("--plan")) {
  console.error("Backup execution is blocked in Phase 0. Use --plan.");
  process.exit(1);
}

console.log("BACKUP PLAN ONLY");
console.log("- Future installer will inventory target files.");
console.log("- Future installer will copy backups to an explicit user-approved location.");
console.log("- Phase 0 does not modify runtime or create backups.");
