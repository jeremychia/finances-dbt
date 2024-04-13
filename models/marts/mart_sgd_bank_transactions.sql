with
    bank_local_currency as (
        select source, local_date, local_currency, local_amount, category, description
        from {{ ref("fact_bank_transactions") }}
    ),

    fx as (
        select local_date, currency, exchange_rate
        from {{ ref("fact_sgd_exchange_rates_long") }}
    ),

    join_fx as (
        select
            local_cur.source,
            local_cur.local_date,
            local_cur.local_currency,
            local_cur.local_amount,
            fx.exchange_rate,
            'SGD' as sgd_currency,
            case
                when local_cur.local_currency = 'SGD'
                then local_cur.local_amount
                else safe_divide(local_cur.local_amount, fx.exchange_rate)
            end as sgd_amount,
            local_cur.category,
            local_cur.description
        from bank_local_currency as local_cur
        left join
            fx on fx.local_date = local_cur.local_date and fx.currency = local_currency
    )

select *
from join_fx
