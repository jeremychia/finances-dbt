with
    source as (select * from {{ source("bank", "hk_hkd_hangseng") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y',{{ adapter.quote("date_ddmmyyyy") }}) as local_date,
            'HKD' as local_currency,
            coalesce(safe_cast({{ adapter.quote("credit") }} as float64), 0) - coalesce(
                safe_cast({{ adapter.quote("debit") }} as float64), 0
            ) as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("details") }} as description

        from source
    )
select *
from renamed
