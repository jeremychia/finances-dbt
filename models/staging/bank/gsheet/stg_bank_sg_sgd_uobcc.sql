with
    source as (select * from {{ source("google_sheets", "sg_sgd_uobcc") }}),
    renamed as (
        select
            'uob-cc' as source,
            parse_date(
                '%d-%b-%y', {{ adapter.quote("transaction_date") }}
            ) as local_date,
            'SGD' as local_currency,
            -safe_cast({{ adapter.quote("transaction_amount_local") }} as float64) as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("description") }} as description
        from source
    )
select *
from renamed
