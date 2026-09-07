{{ config(materialized='table') }}

select
    pa.payer_sk,
    pr.prod_sk,
    cl.cal_sk,
    m.product_name,
    m.geography_level,
    m.geography,
    m.tier,
    m.pa,
    m.st,
    m.ql,
    m.stnd_form_group,
    m.lives,
    m.src_data_month
from {{ ref('stg_payer_msr') }} m
left join {{ ref('product_dim') }}  pr on m.product_id       = pr.prod_sk_nat
left join {{ ref('payer_plan_xref') }} pa on m.payer_entity_id   = pa.payer_entity_id
left join {{ ref('calendar_dim') }}   cl on to_date(m.src_data_month::varchar || '01', 'YYYYMMDD') = cl.cal_dt