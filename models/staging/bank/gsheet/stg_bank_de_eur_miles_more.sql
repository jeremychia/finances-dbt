with
    source as (
        select *
        from {{ source("google_sheets", "de_eur_miles_more") }}
        where processed_on is not null
    ),
    renamed as (
        select
            'miles&more-cc' as source,
            parse_date('%d.%m.%Y',{{ adapter.quote("authorised_on") }}) as local_date,
            'EUR' as local_currency,
            safe_cast(
                replace(
                    replace({{ adapter.quote("amount") }}, '.', ''), ',', '.'
                ) as float64
            ) as local_amount,  -- convert european format
            {{ adapter.quote("category") }},
            trim({{ adapter.quote("description") }}) as description

        from source
    )
select *
from renamed
