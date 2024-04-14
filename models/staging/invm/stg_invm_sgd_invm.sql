with
    source as (select * from {{ source("invm", "sgd_invm") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y',{{ adapter.quote("date") }}) as local_date,
            'SGD' as local_currency_market,
            {{ adapter.quote("market_sgd") }} as local_market,
            {{ adapter.quote("base_sgd") }} as sgd_base,
            {{ adapter.quote("investment") }} as source,
            {{ adapter.quote("is_redeemed") }} as is_redeemed

        from source
    )
select *
from renamed
where local_date is not null
