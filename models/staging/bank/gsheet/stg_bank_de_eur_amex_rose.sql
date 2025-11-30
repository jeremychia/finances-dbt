with
    source as (select * from {{ source("google_sheets", "de_eur_amex_rose") }}),
    renamed as (
        select
            'amex_payback-cc' as source,
            parse_date('%d/%m/%Y',{{ adapter.quote("datum") }}) as local_date,
            'EUR' as local_currency, - safe_cast(
                replace({{ adapter.quote("betrag") }}, ',', '.') as float64
            ) as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("beschreibung") }} as description
        from source
    )
select *
from renamed
