with
    source as (select * from {{ source("bank", "sg_sgd_scbcc") }}),
    renamed as (
        select
            'scb-cc' as source,
            parse_date('%d/%m/%Y',{{ adapter.quote("date") }}) as local_date,
            'SGD' as local_currency,
            case
                when {{ adapter.quote("sgd_amount") }} like '% DR'
                then
                    -1 * cast(
                        regexp_replace(
                            {{ adapter.quote("sgd_amount") }}, '[^0-9.]', ''
                        ) as float64
                    )
                when {{ adapter.quote("sgd_amount") }} like '% CR'
                then
                    cast(
                        regexp_replace(
                            {{ adapter.quote("sgd_amount") }}, '[^0-9.]', ''
                        ) as float64
                    )
            end as local_amount,
            {{ adapter.quote("category") }} as category,
            {{ adapter.quote("description") }} as description

        from source
    )
select *
from renamed
