{{ config(materialized='table') }}


select
    c.claim_id,
    c.patient_id,
    pr.prod_sk,
    pa.payer_sk,
    cl.cal_sk,
    c.svc_dt,
    c.claim_type,
    c.claim_status,
    c.days_supply,
    c.quantity,
    c.reject_code,
    c.opc_ask,
    c.opc_paid,
    c.sob,
    c.life_cycle_claims_yn,
    c.zip_code
from {{ ref('stg_claims') }} c
left join {{ ref('product_dim') }}  pr on c.prod_sk = pr.prod_sk_nat
left join {{ ref('payer_plan_xref') }} pa on c.payer_entity_id = pa.payer_entity_id
left join {{ ref('calendar_dim') }}   cl on c.svc_dt = cl.cal_dt