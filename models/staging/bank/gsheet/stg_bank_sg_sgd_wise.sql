with
    source as (
        select *
        from {{ source("google_sheets", "sg_sgd_wise") }}
        where lower({{ adapter.quote("currency") }}) = 'sgd'
    ),
    renamed as (
        select
            'wise-sgd' as source,
            parse_date('%d/%m/%Y', {{ adapter.quote("date") }}) as local_date,
            'SGD' as local_currency,
            safe_cast({{ adapter.quote("amount") }} as float64) as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("description") }} as description
        from source
    )
select *
from renamed