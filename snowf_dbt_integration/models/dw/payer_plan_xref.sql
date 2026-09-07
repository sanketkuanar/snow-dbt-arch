{{ config(materialized='table') }}


select
    row_number() over (order by payer_entity_id) as payer_sk,
    payer_entity_id,
    payer_entity,
    bob_id,
    bob,
    enterprise_id,
    enterprise,
    pop_desc,
    pbm_vendor_id,
    pbm_vendor,
    relationship_type
from {{ ref('stg_payer_hierarchy') }}