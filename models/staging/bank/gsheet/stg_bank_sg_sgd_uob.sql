with
    source as (select * from {{ source("google_sheets", "sg_sgd_uob") }}),
    renamed as (
        select
            'uob' as source,
            parse_date(
                '%d-%b-%y',{{ adapter.quote("transaction_date") }}
            ) as local_date,
            'SGD' as local_currency,
            coalesce(safe_cast({{ adapter.quote("deposit") }} as float64), 0)
            - coalesce(safe_cast({{ adapter.quote("withdrawal") }} as float64), 0) as local_amount,
            {{ adapter.quote("category") }},
            {{ adapter.quote("transaction_description") }} as description
        from source
    )
select *
from renamed
