with
    source as (select * from {{ source("google_sheets", "sgd_fundingsoc") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y', {{ adapter.quote("date") }}) as local_date,
            'SGD' as local_currency_market,
            coalesce(safe_cast({{ adapter.quote("acc_balance_sgd") }} as float64), 0)
            + coalesce(safe_cast({{ adapter.quote("outstanding_principle_sgd") }} as float64), 0)
            + coalesce(safe_cast({{ adapter.quote("expected_returns_sgd") }} as float64), 0) as local_market,
            {{ adapter.quote("principal_sgd") }} as sgd_base,
            {{ adapter.quote("investment") }} as source,
            safe_cast({{ adapter.quote("is_redeemed") }} as boolean) as is_redeemed

        from source
    )
select *
from renamed
where local_date >= '2020-01-10'  -- start of investments
