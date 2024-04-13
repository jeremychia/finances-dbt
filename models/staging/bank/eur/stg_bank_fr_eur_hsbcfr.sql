with
    source as (select * from {{ source("bank", "fr_eur_hsbcfr") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y', {{ adapter.quote("operation") }}) as local_date,
            'EUR' as local_currency,
            coalesce(
                cast(
                    replace(
                        replace({{ adapter.quote("credit") }}, ',', '.'), ' ', ''
                    ) as float64
                ),
                0
            ) + coalesce(
                cast(
                    replace(
                        replace({{ adapter.quote("debit") }}, ',', '.'), ' ', ''
                    ) as float64
                ),
                0
            ) as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("description") }} as description

        from source
    )
select *
from renamed
