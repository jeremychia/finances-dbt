with
    source as (select * from {{ source("bank", "sg_other_revolut_v2") }}),
    renamed as (
        select
            'revolut-other' as source,
            date(
                parse_datetime('%d/%m/%Y %H:%M', {{ adapter.quote("started_date") }})
            ) as local_date,
            {{ adapter.quote("currency") }} as local_currency,
            {{ adapter.quote("amount") }} as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("description") }} as description

        from source
    )
select *
from renamed
