{{ config(materialized='table') }}

with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="to_date('2026-01-01','YYYY-MM-DD')",
        end_date="to_date('2027-01-01','YYYY-MM-DD')"
    ) }}
)

select
    row_number() over (order by date_day)      as cal_sk,
    date_day::date                             as cal_dt,
    year(date_day)                             as cal_year,
    month(date_day)                            as cal_month,
    day(date_day)                              as cal_day,
    date_trunc('week', date_day)::date         as cal_week,
    weekofyear(date_day)                       as week_of_year,
    quarter(date_day)                          as cal_quarter,
    dayname(date_day)                          as day_name,
    case when dayofweekiso(date_day) in (6,7) then true else false end as is_weekend
from spine