with
    invm as (
        select
            'investment' as type,
            local_date,
            source,
            local_currency_market as local_currency,
            local_market as local_balance,
            sgd_currency_market as sgd_currency,
            sgd_market as sgd_balance,
            cumulative_sgd_invm_gain_loss as sgd_invm_gain_loss,
            cumulative_sgd_fx_gain_loss as sgd_fx_gain_loss
        from {{ ref("mart_sgd_invm_balances") }}
    ),

    bank as (
        select
            case when source like '%cc' then 'credit-card' else 'cash' end as type,
            local_date,
            source,
            local_currency,
            local_balance,
            sgd_currency,
            sgd_amount as sgd_balance,
            0 as sgd_invm_gain_loss,
            sgd_fx_gain_loss
        from {{ ref("mart_sgd_bank_balances") }}
    ),

    unioned as (
        select *
        from invm
        union all
        select *
        from bank
    )

select *
from unioned
order by local_date desc, source
