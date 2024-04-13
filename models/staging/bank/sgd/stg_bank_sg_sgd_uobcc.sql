with
    source as (select * from {{ source("bank", "sg_sgd_uobcc") }}),
    renamed as (
        select
            parse_date(
                '%d-%b-%y', {{ adapter.quote("transaction_date") }}
            ) as local_date,
            'SGD' as local_currency,
            -{{ adapter.quote("transaction_amountlocal") }} as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("description") }} as description
        from source
    )
select *
from renamed
