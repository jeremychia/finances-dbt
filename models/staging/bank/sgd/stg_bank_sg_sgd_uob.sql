with
    source as (select * from {{ source("bank", "sg_sgd_uob") }}),
    renamed as (
        select
            parse_date(
                '%d-%b-%y',{{ adapter.quote("transaction_date") }}
            ) as local_date,
            'SGD' as local_currency,
            coalesce({{ adapter.quote("deposit") }}, 0)
            - coalesce({{ adapter.quote("withdrawal") }}, 0) as local_amount,
            {{ adapter.quote("category") }},
            {{ adapter.quote("transaction_description") }} as description
        from source
    )
select *
from renamed
