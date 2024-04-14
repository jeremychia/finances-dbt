with
    union_all as (
        {{
            dbt_utils.union_relations(
                relations=[
                    ref("stg_invm_hkdusd_invm"),
                    ref("stg_invm_sgd_cdp_invm"),
                    ref("stg_invm_sgd_fundingsoc"),
                    ref("stg_invm_sgd_invm"),
                    ref("stg_invm_usd_invm"),
                ],
                source_column_name=None,
            )
        }}
    ),

    fx as (
        select local_date, currency, exchange_rate
        from {{ ref("fact_sgd_exchange_rates_long") }}
    ),

    fx_hkd as (
        select local_date, currency, exchange_rate from fx where currency = 'HKD'
    ),

    fx_usd as (
        select local_date, currency, exchange_rate from fx where currency = 'USD'
    ),

    prep_fx_gain_loss as (
        select
            union_all.source,
            union_all.local_date,
            union_all.local_currency_market,
            union_all.local_market,
            'SGD' as sgd_currency_market,
            case
                when union_all.local_currency_market = 'SGD'
                then union_all.local_market
                else safe_divide(union_all.local_market, fx.exchange_rate)
            end as sgd_market,
            union_all.hkd_base,
            safe_divide(union_all.hkd_base, fx_hkd.exchange_rate) as hkd_base_in_sgd,
            union_all.usd_base,
            safe_divide(union_all.usd_base, fx_usd.exchange_rate) as usd_base_in_sgd,
            union_all.sgd_base,
            coalesce(union_all.is_redeemed, false) as is_redeemed
        from union_all
        left join
            fx
            on fx.local_date = union_all.local_date
            and fx.currency = union_all.local_currency_market
        left join fx_hkd on fx_hkd.local_date = union_all.local_date
        left join fx_usd on fx_usd.local_date = union_all.local_date
    ),

    calculate_fx_gain_loss as (
        select
            *,
            case
                when is_redeemed = true
                then 0
                when local_currency_market = 'HKD'
                then coalesce(sgd_market, 0) - coalesce(hkd_base_in_sgd, 0)
                when local_currency_market = 'USD'
                then coalesce(sgd_market, 0) - coalesce(usd_base_in_sgd, 0)
                when local_currency_market = 'SGD'
                then coalesce(sgd_market, 0) - coalesce(sgd_base, 0)
            end as sgd_invm_gain_loss,
            case
                when is_redeemed = true
                then 0
                when local_currency_market = 'HKD'
                then coalesce(hkd_base_in_sgd, 0) - coalesce(sgd_base, 0)
                when local_currency_market = 'USD'
                then coalesce(usd_base_in_sgd, 0) - coalesce(sgd_base, 0)
                when local_currency_market = 'SGD'
                then 0
            end as sgd_fx_gain_loss
        from prep_fx_gain_loss
    )

select *
from calculate_fx_gain_loss
