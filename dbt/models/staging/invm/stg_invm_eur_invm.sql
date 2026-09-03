{{ config(
    materialized = "view",
    tags = ["staging", "invm"]
) }}

with
source as (select * from {{ source("google_sheets", "eur_invm") }}),

renamed as (
    select
        'EUR' as local_currency_market,
        investment as investment_source,
        parse_date('%d/%m/%Y', date) as local_date,
        safe_cast(market_eur as float64) as local_market,
        safe_cast(base_eur as float64) as eur_base,
        safe_cast(base_sgd as float64) as sgd_base

    from source
)

select *
from renamed
