with
    source as (select * from {{ source("google_sheets", "de_eur_n26") }}),
    renamed as (
        select
            'n26' as source,
            parse_date('%d/%m/%Y',{{ adapter.quote("date") }}) as local_date,
            'EUR' as local_currency,
            safe_cast({{ adapter.quote("amount_eur") }} as float64) as local_amount,
            {{ adapter.quote("category") }},
            trim(
                concat(
                    coalesce(
                        cast({{ adapter.quote("payment_reference") }} as string), ''
                    ),
                    ' ',
                    coalesce(cast({{ adapter.quote("payee") }} as string), ''),
                    ' ',
                    coalesce(cast({{ adapter.quote("account_number") }} as string), '')
                )
            ) as description

        from source
    )
select *
from renamed
