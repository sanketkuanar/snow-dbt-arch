{{ config(materialized='table') }}


select
    row_number() over (order by prod_sk_nat) as prod_sk,
    prod_sk_nat,
    prod_brand_sk,
    prod_nm,
    brand_nm,
    prod_class,
    mkt_cd,
    mkt_nm,
    generic_flg,
    actv_flg
from (
    select
        prod_sk as prod_sk_nat,
        prod_brand_sk, prod_nm, brand_nm, prod_class,
        mkt_cd, mkt_nm, generic_flg, actv_flg
    from {{ ref('prod_dim') }}
)