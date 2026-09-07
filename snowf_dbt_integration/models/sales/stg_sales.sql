{{
  config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='PERIOD_KEY',
    schema='SALES'
  )
}}

SELECT
    A.PERIOD_KEY,
    A.MKT_KEY,
    A.PGN_KEY AS PROD_SK,
    A.PLAN_KEY AS PAYER_ENTITY_ID,
    A.CHAN_KEY,
    A.NRX,
    A.NQTY,
    A.NFACT,
    A.TRX,
    A.TQTY,
    A.TFACT,
    A.BATCH_ID,
    CURRENT_TIMESTAMP() AS LOAD_DATE
FROM {{ source('sales_claims', 'XPT_TB') }} A