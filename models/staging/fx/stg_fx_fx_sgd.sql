with
    source as (select * from {{ source("fx", "fx_sgd") }}),
    renamed as (
        select
            parse_date('%d/%m/%Y',{{ adapter.quote("date") }}) as local_date,
            {{ adapter.quote("hkd") }} as hkd,
            {{ adapter.quote("usd") }} as usd,
            {{ adapter.quote("eur") }} as eur,
            {{ adapter.quote("myr") }} as myr,
            {{ adapter.quote("huf") }} as huf,
            {{ adapter.quote("chf") }} as chf,
            {{ adapter.quote("gbp") }} as gbp

        from source
    ), unpivot as (
        select *
        from
            renamed
            unpivot (exchange_rate for currency in (hkd, usd, eur, myr, huf, chf, gbp))
    ),
    clarity as (
        select
            local_date,
            1 as sgd,
            safe_divide(1, exchange_rate) as exchange_rate,
            upper(currency) as currency
        from unpivot
    )
select *
from clarity
where exchange_rate is not null
