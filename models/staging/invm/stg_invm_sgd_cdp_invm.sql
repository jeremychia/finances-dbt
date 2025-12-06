{{ config(
    materialized = "table",
    tags = ["staging", "invm"]
) }}

with
    source as (select * from {{ source("google_sheets", "sgd_cdp_invm") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y',{{ adapter.quote("date") }}) as local_date,
            'SGD' as local_currency_market,
            round(
                safe_cast({{ adapter.quote("market_unit_price_sgd") }} as float64)
                * safe_cast({{ adapter.quote("quantity") }} as float64),
                2
            ) as local_market,
            safe_cast({{ adapter.quote("base_sgd") }} as float64) as sgd_base,
            concat('CDP - ',{{ adapter.quote("counter") }}) as source,
            safe_cast({{ adapter.quote("is_redeemed") }} as boolean) as is_redeemed

        from source
    )
select *
from renamed
