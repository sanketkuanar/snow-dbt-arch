SELECT
    *
FROM
    {{ source('payer', 'MAJORITY_STATUS_TB') }}