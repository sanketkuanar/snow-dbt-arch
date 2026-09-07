{{ 
    config(
    materialized='table',
    schema = 'PAYER'
    ) 
}}

select
    payer_entity_id,
    payer_entity,
    bob_id,
    bob,
    enterprise_id,
    enterprise,
    pop_desc,
    pbm_vendor_id,
    pbm_vendor,
    relationship_type,
    current_timestamp() as load_date
from {{ source('payer', 'PAYER_HIER_TB') }}