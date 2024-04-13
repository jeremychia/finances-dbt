with
    source as (select * from {{ source("bank", "sg_eur_revolut_v1") }}),
    renamed as (
        select
            'revolut-eur' as source,
            parse_date('%b %d, %Y',{{ adapter.quote("completed_date") }}) as local_date,
            'EUR' as local_currency,
            coalesce(cast({{ adapter.quote("paid_in_eur") }} as float64), 0) - coalesce(
                cast({{ adapter.quote("paid_out_eur") }} as float64), 0
            ) as local_amount,
            {{ adapter.quote("category2") }} as category,
            {{ adapter.quote("description") }} as description

        from source
    )
select *
from renamed
