{{
  config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='SRC_DATA_MONTH',
    schema='PAYER'
  )
}}

select
    PAYER_ENTITY_ID,
    PRODUCT_ID,
    PRODUCT_NAME,
    GEOGRAPHY_LEVEL,
    GEOGRAPHY,
    TIER,
    PA,
    ST,
    QL,
    STND_FORM_GROUP,
    LIVES,
    SRC_DATA_MONTH,
    current_timestamp() as LOAD_DATE
from {{ source('payer', 'MAJORITY_STATUS_TB') }}