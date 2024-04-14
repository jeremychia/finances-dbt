with
    source as (select * from {{ source("invm", "usd_invm") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y',{{ adapter.quote("date") }}) as local_date,
            'USD' as local_currency_market,
            {{ adapter.quote("market_usd") }} as local_market,
            {{ adapter.quote("base_usd") }} as usd_base,
            {{ adapter.quote("base_sgd") }} as sgd_base,
            {{ adapter.quote("investment") }} as source

        from source
    )
select *
from renamed
