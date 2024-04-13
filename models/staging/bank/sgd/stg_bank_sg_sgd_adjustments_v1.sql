with
    source as (select * from {{ source("bank", "sg_sgd_adjustments") }}),
    renamed as (
        select
            date_sub(
                date_add(
                    parse_date('%Y-%m', {{ adapter.quote("yyyymm") }}), interval 1 month
                ),
                interval 1 day
            ) as local_date,
            'SGD' as local_currency,
            {{ adapter.quote("amount") }} as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("remarks") }} as description,

        from source
    )
select *
from renamed
