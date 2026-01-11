with base_dates as ({{ dbt_date.get_base_dates("2018-01-01", "2027-01-01") }})

select
    cast(date_day as date) as local_date,
    {{ dbt_date.day_of_week("date_day") }} as day_of_week_iso,
    {{ dbt_date.day_of_month("date_day") }} as day_of_month,
    {{ dbt_date.day_of_year("date_day") }} as day_of_year,
    {{ dbt_date.iso_week_of_year("date_day") }} as iso_week_of_year
from base_dates
