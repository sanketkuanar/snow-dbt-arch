# snow-dbt-arch

Migrating a Snowflake stored-procedure pipeline to **dbt** — bringing version
control, lineage, and automated testing to a payer/claims/sales analytics
warehouse that previously had none.

## Why this project

The original pipeline was built entirely from Snowflake stored procedures with
no version control. Business logic (surrogate-key generation, pill-factor
calculations, formulary rollups) lived invisibly inside procedures — no diffs,
no review, no history, no automated testing.

This project rebuilds that pipeline in dbt so that:

- **Every transformation is versioned** — each model is a `.sql` file tracked in
  git, changed via feature branch → pull request → merge.
- **Lineage is automatic** — `dbt docs` generates the full dependency graph from
  sources through to the final ARD.
- **Data quality is tested** — `dbt test` enforces surrogate-key integrity and
  referential consistency on every run.

## Architecture

Data flows through layered schemas, mirroring the original Bronze/Silver/Gold
design:

```
Raw shares (read-only)        Staging (L1)         DW (L2)              ARD (L3)
─────────────────────         ────────────         ───────              ────────
RAW_SALES_CLAIMS   ─┐         SALES.stg_sales      DW.calendar_dim      ARD_PAYER.
  · XPT_TB          ├──────▶  CLAIMS.stg_claims ─▶ DW.product_dim   ─▶  payer_ard_final
  · LAAD_TB         │         PAYER.stg_payer_*    DW.payer_plan_xref
  · PROD_XREF       │                              DW.laad_fct
RAW_PAYER          ─┘                              DW.xpt_fct
  · MAJORITY_STATUS_TB                             DW.payer_stat_rpt
  · PAYER_HIER_TB
```

- **Staging** — `delete+insert` / `truncate+load` from the raw share databases.
- **DW** — conformed dimensions (product, payer, calendar) with generated
  sequential surrogate keys, plus cleaned fact tables.
- **ARD** — a single wide analytics-ready table aggregating sales, claims, and
  formulary coverage per brand × payer × period, with derived metrics
  (pill factor = TRx / 25, paid-claim %, pills per new Rx).

Snowflake **time travel** backs the truncate/delete-insert loads as the rollback
mechanism, so no custom history logic is needed.

## Environments

A single Snowflake account with two databases simulating a dev/prod split:

| Target | Database   | Used for                          |
|--------|------------|-----------------------------------|
| `dev`  | `CDR_DEV`  | feature-branch development         |
| `prod` | `CDR_PROD` | deployed after merge to `main`     |

Raw share databases (`RAW_SALES_CLAIMS`, `RAW_PAYER`) are shared upstream and
read-only for both targets.

## Project structure

```
snowf_dbt_integration/
├── models/
│   ├── sales/        # staging
│   ├── claims/       # staging
│   ├── payer/        # staging
│   ├── dim_tbls/     # source-aligned product staging
│   ├── dw/           # dimensions + facts (L2)
│   └── ard_payer/    # final ARD (L3)
├── macros/           # generate_schema_name (clean schema naming)
├── dbt_project.yml
└── packages.yml      # dbt_utils
```

## Setup

Requires dbt 1.12 with the Snowflake adapter, authenticated via key-pair auth.

```bash
# install dependencies
pip install dbt-snowflake
dbt deps

# verify connection
dbt debug --target dev
```

Configure `~/.dbt/profiles.yml` with `private_key_path` pointing at your RSA key
(key-pair auth satisfies the account's MFA requirement).

## Usage

```bash
# build the whole pipeline in dev
dbt run --target dev

# build + test a single layer
dbt build --select dw --target dev

# generate and view lineage docs
dbt docs generate --target dev
dbt docs serve --port 8081

# promote to prod (after merge to main)
dbt run --target prod
```

## Workflow

All changes follow: feature branch → pull request → review → merge to `main` →
deploy to prod. `main` is the source of truth for what has been reviewed; prod
is only ever deployed from `main`.
