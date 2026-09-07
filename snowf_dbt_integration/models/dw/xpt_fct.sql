{{ config(materialized='table') }}


select
    s.period_key,
    cl.cal_sk,
    pr.prod_sk,
    pa.payer_sk,
    s.mkt_key,
    s.chan_key,
    s.nrx,
    s.nqty,
    s.nfact,
    s.trx,
    s.tqty,
    s.tfact,
    s.batch_id
from {{ ref('stg_sales') }} s
left join {{ ref('product_dim') }}  pr on s.prod_sk = pr.prod_sk_nat
left join {{ ref('payer_plan_xref') }} pa on s.payer_entity_id = pa.payer_entity_id
left join {{ ref('calendar_dim') }}   cl on to_date(s.period_key::varchar, 'YYYYMMDD') = cl.cal_dt