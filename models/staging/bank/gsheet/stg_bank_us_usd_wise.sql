with
    source as (
        select *
        from {{ source("google_sheets", "us_usd_wise") }}
        where lower({{ adapter.quote("source_currency") }}) = 'usd'
    ),
    renamed as (
        select
            'wise-usd' as source,
            cast(
                parse_datetime(
                    "%Y-%m-%d %H:%M:%S",{{ adapter.quote("created_on") }}
                ) as date
            ) as local_date,
            'USD' as local_currency,
            case
                when lower(direction) = 'in'
                then
                    safe_cast(
                        {{ adapter.quote("source_amount_after_fees") }} as float64
                    )
                when lower(direction) = 'out'
                then
                    - safe_cast(
                        {{ adapter.quote("source_amount_after_fees") }} as float64
                    )
            end as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("target_name") }} as description

        from source
    )
select *
from renamed
