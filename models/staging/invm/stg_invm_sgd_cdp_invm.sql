with
    source as (select * from {{ source("invm", "sgd_cdp_invm") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y',{{ adapter.quote("date") }}) as local_date,
            'SGD' as local_currency_market,
            round(
                {{ adapter.quote("market_unit_price_sgd") }}
                * {{ adapter.quote("quantity") }},
                2
            ) as local_market,
            {{ adapter.quote("base_sgd") }} as sgd_base,
            concat('CDP - ',{{ adapter.quote("counter") }}) as source,
            {{ adapter.quote("is_redeemed") }} as is_redeemed

        from source
    )
select *
from renamed
