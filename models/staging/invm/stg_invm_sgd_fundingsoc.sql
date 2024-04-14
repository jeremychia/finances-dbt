with
    source as (select * from {{ source("invm", "sgd_fundingsoc") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y', {{ adapter.quote("date") }}) as local_date,
            'SGD' as local_currency_market,
            coalesce({{ adapter.quote("acc_balance_sgd") }}, 0)
            + coalesce({{ adapter.quote("outstanding_principle_sgd") }}, 0)
            + coalesce({{ adapter.quote("expected_returns_sgd") }}, 0) as local_market,
            {{ adapter.quote("principal_sgd") }} as sgd_base,
            {{ adapter.quote("investment") }} as source,

        from source
    )
select *
from renamed
where local_date >= '2020-01-10'  -- start of investments
