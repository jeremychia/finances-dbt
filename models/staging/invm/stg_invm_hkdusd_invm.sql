with
    source as (
        select
            * except ({{ adapter.quote("date") }}),
            parse_date('%d/%m/%Y', {{ adapter.quote("date") }}) as local_date
        from {{ source("invm", "hkdusd_invm") }}
    ),
    fx as (
        select parse_date('%d/%m/%Y', date) as local_date, hkd, usd
        from {{ source("fx", "fx_sgd") }}
    ),
    hkd as (
        select
            local_date,
            'HKD' as local_currency_market,
            {{ adapter.quote("market_hkd") }} as local_market,
            {{ adapter.quote("base_hkd") }} as hkd_base,
            0 as usd_base,
            {{ adapter.quote("investment") }} as source
        from source
    ),
    usd as (
        select
            local_date,
            'USD' as local_currency_market,
            {{ adapter.quote("market_usd") }} as local_market,
            0 as hkd_base,
            {{ adapter.quote("base_usd") }} as usd_base,
            {{ adapter.quote("investment") }} as source
        from source
    ),
    unioned as (
        select *
        from hkd
        union all
        select *
        from usd
    ),
    translate_to_sgd_base as (
        select
            unioned.local_date,
            unioned.local_currency_market,
            unioned.local_market,
            unioned.hkd_base,
            unioned.usd_base,
            sum(unioned.hkd_base) over (partition by unioned.local_date)
            * fx.hkd as total_hkd_base_in_sgd,
            sum(unioned.usd_base) over (partition by unioned.local_date)
            * fx.usd as total_usd_base_in_sgd,
            source,
        from unioned
        left join fx on unioned.local_date = fx.local_date
        where unioned.local_date >= '2021-03-12'

    ),
    allocate_sgd_base as (
        select
            translate_to_sgd_base.local_date,
            translate_to_sgd_base.local_currency_market,
            translate_to_sgd_base.local_market,
            translate_to_sgd_base.hkd_base,
            translate_to_sgd_base.usd_base,
            case
                when translate_to_sgd_base.local_currency_market = 'HKD'
                then
                    safe_divide(
                        translate_to_sgd_base.total_hkd_base_in_sgd,
                        translate_to_sgd_base.total_hkd_base_in_sgd
                        + translate_to_sgd_base.total_usd_base_in_sgd
                    )
                    * source.base_sgd
                when translate_to_sgd_base.local_currency_market = 'USD'
                then
                    safe_divide(
                        translate_to_sgd_base.total_usd_base_in_sgd,
                        translate_to_sgd_base.total_hkd_base_in_sgd
                        + translate_to_sgd_base.total_usd_base_in_sgd
                    )
                    * source.base_sgd
            end sgd_base,
            translate_to_sgd_base.source
        from translate_to_sgd_base
        left join source on translate_to_sgd_base.local_date = source.local_date
    )

select *
from allocate_sgd_base
order by local_date, local_currency_market
