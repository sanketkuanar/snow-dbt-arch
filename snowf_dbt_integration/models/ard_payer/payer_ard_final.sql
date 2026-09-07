{{ config(materialized='table', schema='ARD_PAYER') }}

with sales as (
    select * from {{ ref('xpt_fct') }}
),
claims as (
    select * from {{ ref('laad_fct') }}
),
formulary as (
    select * from {{ ref('payer_stat_rpt') }}
),
prod as (
    select prod_sk, prod_sk_nat, brand_nm, mkt_cd, mkt_nm from {{ ref('product_dim') }}
),
payer as (
    select payer_sk, payer_entity, enterprise, pbm_vendor from {{ ref('payer_plan_xref') }}
),
cal as (
    select cal_sk, cal_dt, cal_year, cal_month, cal_week from {{ ref('calendar_dim') }}
),

-- ---- aggregate sales (XPT) to brand x payer x period, apply pill factor ----
sales_agg as (
    select
        p.prod_sk,
        p.brand_nm,
        p.mkt_cd,
        pay.payer_sk,
        pay.payer_entity,
        pay.enterprise,
        pay.pbm_vendor,
        c.cal_year,
        c.cal_month,
        sum(s.nrx)                as nrx,
        sum(s.trx)                as trx,
        sum(s.trx) / 10.0         as fct_trx,     -- pill factor: TRx / 10
        sum(s.tqty)               as tqty
    from sales s
    join prod  p   on s.prod_sk  = p.prod_sk
    join payer pay on s.payer_sk = pay.payer_sk
    join cal   c   on s.cal_sk   = c.cal_sk
    group by 1,2,3,4,5,6,7,8,9
),

-- ---- aggregate claims (LAAD) to the same grain ----
claims_agg as (
    select
        p.prod_sk,
        p.brand_nm,
        pay.payer_sk,
        c.cal_year,
        c.cal_month,
        count(cl.claim_id)                                    as total_claims,
        sum(case when cl.claim_type = 'PD' then 1 else 0 end) as paid_claims,
        sum(case when cl.claim_type = 'RJ' then 1 else 0 end) as rejected_claims,
        avg(cl.opc_paid)                                      as avg_opc_paid
    from claims cl
    join prod  p   on cl.prod_sk  = p.prod_sk
    join payer pay on cl.payer_sk = pay.payer_sk
    join cal   c   on cl.cal_sk   = c.cal_sk
    group by 1,2,3,4,5
),

-- ---- formulary / coverage: one row per payer x product (national-level pick) ----
coverage as (
    select
        payer_sk,
        prod_sk,
        max(tier)             as formulary_tier,
        max(pa)               as prior_auth,
        max(st)               as step_therapy,
        max(ql)               as quantity_limit,
        max(stnd_form_group)  as coverage_group,
        sum(lives)            as covered_lives
    from formulary
    where geography_level = 'NATIONAL'      -- national coverage picture; use STATE for geo-level
    group by 1,2
)

-- ---- final ARD: sales + claims + coverage side by side ----
select
    s.brand_nm,
    s.mkt_cd,
    s.payer_entity,
    s.enterprise,
    s.pbm_vendor,
    s.cal_year,
    s.cal_month,

    -- sales metrics
    s.nrx,
    s.trx,
    s.fct_trx,
    s.tqty,

    -- claims metrics
    coalesce(cl.total_claims, 0)     as total_claims,
    coalesce(cl.paid_claims, 0)      as paid_claims,
    coalesce(cl.rejected_claims, 0)  as rejected_claims,
    cl.avg_opc_paid,

    -- coverage / formulary
    cov.formulary_tier,
    cov.prior_auth,
    cov.step_therapy,
    cov.quantity_limit,
    cov.coverage_group,
    cov.covered_lives,

    -- derived ARD metrics
    round(s.fct_trx / nullif(s.nrx, 0), 2)                        as pills_per_new_rx,
    round(cl.paid_claims / nullif(cl.total_claims, 0) * 100, 1)   as paid_claim_pct

from sales_agg s
left join claims_agg cl
    on  s.prod_sk   = cl.prod_sk
    and s.payer_sk  = cl.payer_sk
    and s.cal_year  = cl.cal_year
    and s.cal_month = cl.cal_month
left join coverage cov
    on  s.prod_sk  = cov.prod_sk
    and s.payer_sk = cov.payer_sk

where s.cal_year = {{ var('ard_year', 2026) }}
order by s.brand_nm, s.payer_entity, s.cal_month