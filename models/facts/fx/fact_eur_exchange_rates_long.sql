with
    source as (
        select local_date, sgd, exchange_rate, currency
        from {{ ref("stg_fx_fx_sgd") }}
    ), pivot as (
        select *
        from
            source pivot (
                avg(exchange_rate)
                for currency in ('HKD', 'USD', 'EUR', 'MYR', 'CHF', 'GBP', 'HUF')
            )
    ),

    convert_eur as (
        select
            local_date,
            safe_divide(sgd, eur) as sgd,
            safe_divide(hkd, eur) as hkd,
            safe_divide(usd, eur) as usd,
            safe_divide(eur, eur) as eur,
            safe_divide(myr, eur) as myr,
            safe_divide(chf, eur) as chf,
            safe_divide(gbp, eur) as gbp,
            safe_divide(huf, eur) as huf,
        from pivot
    ),

    unpivot_eur as (
        select local_date, 1 as eur, exchange_rate, upper(currency) as currency
        from
            convert_eur
            unpivot (exchange_rate for currency in (sgd, hkd, usd, myr, chf, gbp, huf))
    )

select *
from unpivot_eur
