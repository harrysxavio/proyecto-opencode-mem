---
name: sandbox-data-loader
description: Safely inspect and stage user-provided datasets. Trigger: CSV, XLSX, dataset load, schema detection, duplicates, or PII scan.
---

# sandbox-data-loader

## When to use

Safely inspect and stage user-provided datasets. Trigger: CSV, XLSX, dataset load, schema detection, duplicates, or PII scan.

## Runtime contract

Use this skill to detect columns, types, nulls, duplicates, possible PII, and safe staging steps before loading data.

## Output

Return a compact result with:

- decision or recommendation;
- evidence checked;
- risks and tradeoffs;
- next action.

## Boundaries

- Do not include private local paths in generated artifacts.
- Do not make destructive changes without an explicit user request.
- Prefer small, reviewable outputs over broad audits.