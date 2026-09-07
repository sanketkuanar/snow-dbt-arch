{{ config(materialized='table') }}

SELECT
PROD_SK,
PROD_BRAND_SK,
PROD_NM,
BRAND_NM,
PROD_CLASS,
MKT_CD,
MKT_NM,
GENERIC_FLG,
ACTV_FLG,
CURRENT_TIMESTAMP() AS LOAD_DATE
from {{ source('sales_claims', 'PROD_XREF') }}