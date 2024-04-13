with
    source as (select * from {{ source("bank", "sg_sgd_hsbccc") }}),
    renamed as (
        select
            'hsbc-cc' as source,
            parse_date('%d/%m/%Y', {{ adapter.quote("date") }}) as local_date,
            'SGD' as local_currency,
            {{ adapter.quote("amount") }} as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("description") }} as description

        from source
    )
select *
from renamed
