with
    source as (select * from {{ source("google_sheets", "usd_invm") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y',{{ adapter.quote("date") }}) as local_date,
            'USD' as local_currency_market,
            safe_cast({{ adapter.quote("market_usd") }} as float64) as local_market,
            safe_cast({{ adapter.quote("base_usd") }} as float64) as usd_base,
            safe_cast({{ adapter.quote("base_sgd") }} as float64) as sgd_base,
            {{ adapter.quote("investment") }} as source

        from source
    )
select *
from renamed
