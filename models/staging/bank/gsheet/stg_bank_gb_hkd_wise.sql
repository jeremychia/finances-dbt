with
    source as (
        select *
        from {{ source("google_sheets", "gb_hkd_wise") }}
        where lower({{ adapter.quote("target_currency") }}) = 'hkd' 
    ),
    renamed as (
        select
            'wise-hkd' as source,
            cast(
                parse_datetime(
                    "%Y-%m-%d %H:%M:%S",{{ adapter.quote("created_on") }}
                ) as date
            ) as local_date,
            'HKD' as local_currency,
            case
                when lower(direction) = 'in'
                then
                    safe_cast(
                        {{ adapter.quote("target_amount_after_fees") }} as float64
                    )
                when lower(direction) = 'out'
                then
                    - safe_cast(
                        {{ adapter.quote("target_amount_after_fees") }} as float64
                    )
            end as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("target_name") }} as description

        from source
    )
select *
from renamed
