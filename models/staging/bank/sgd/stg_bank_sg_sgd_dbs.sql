with
    source as (select * from {{ source("bank", "sg_sgd_dbs") }}),
    renamed as (
        select
            parse_date(
                '%d-%b-%y', {{ adapter.quote("transaction_date") }}
            ) as local_date,
            'SGD' as local_currency,
            coalesce(
                safe_cast({{ adapter.quote("credit_amount") }} as float64),
                0
            ) - coalesce(
                safe_cast({{ adapter.quote("debit_amount") }} as float64), 0
            ) as local_amount,
            {{ adapter.quote("category") }} as category,
            concat(
                coalesce({{ adapter.quote("transaction_ref1") }}, ''),
                ' ',
                coalesce({{ adapter.quote("transaction_ref2") }}, ''),
                ' ',
                coalesce({{ adapter.quote("transaction_ref3") }}, '')
            ) as description,

        from source
    )
select *
from renamed
order by local_date desc
