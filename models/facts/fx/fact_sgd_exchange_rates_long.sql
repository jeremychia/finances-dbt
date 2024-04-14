select local_date, sgd, exchange_rate, currency from {{ ref("stg_fx_fx_sgd") }}
