---
name: bigquery-table-cleaning
description: Plan BigQuery table cleaning and validation. Trigger: BigQuery cleaning, nulls, schema, types, or clean table.
---

# bigquery-table-cleaning

## When to use

Plan BigQuery table cleaning and validation. Trigger: BigQuery cleaning, nulls, schema, types, or clean table.

## Runtime contract

Use this skill to profile data, detect schema issues, propose safe transforms, and validate cleaned outputs before writing tables.

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