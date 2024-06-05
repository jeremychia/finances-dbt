with
    source as (select * from {{ source("google_sheets", "de_eur_amex") }}),
    renamed as (
        select
            'amex_payback-cc' as source,
            parse_date('%d/%m/%Y',{{ adapter.quote("Datum") }}) as local_date,
            'EUR' as local_currency,
            safe_cast(replace({{ adapter.quote("Betrag") }}, ',', '.') as float64) as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("Beschreibung") }} as description
        from source
    )
select * from renamed