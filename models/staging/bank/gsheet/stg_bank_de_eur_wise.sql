with source as (
      select * from {{ source('google_sheets', 'de_eur_wise') }}
      where lower({{ adapter.quote("currency") }}) = 'eur'
),
renamed as (
    select
        'wise-eur' as source,
        parse_date('%d-%m-%Y',{{ adapter.quote("date") }}) as local_date,
        'EUR' as local_currency,
        safe_cast({{ adapter.quote("amount") }} as float64) as local_amount,
        {{ adapter.quote("category") }} as category,
        {{ adapter.quote("description") }} as description

    from source
)
select * from renamed
  