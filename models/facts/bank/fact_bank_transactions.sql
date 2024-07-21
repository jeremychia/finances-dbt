with
    union_all as (
        {{
            dbt_utils.union_relations(
                relations=[
                    ref("stg_bank_de_eur_amex"),
                    ref("stg_bank_de_eur_n26"),
                    ref("stg_bank_de_eur_wise"),
                    ref("stg_bank_gb_gbp_wise"),
                    ref("stg_bank_fr_eur_hsbcfr"),
                    ref("stg_bank_sg_eur_revolut_v1"),
                    ref("stg_bank_sg_eur_revolut_v2"),
                    ref("stg_bank_hk_hkd_hangseng"),
                    ref("stg_bank_sg_other_revolut_v2"),
                    ref("stg_bank_sg_sgd_adjustments_v1"),
                    ref("stg_bank_sg_sgd_citicc"),
                    ref("stg_bank_sg_sgd_dbs"),
                    ref("stg_bank_sg_sgd_hsbccc"),
                    ref("stg_bank_sg_sgd_ocbc_v1"),
                    ref("stg_bank_sg_sgd_revolut_v1"),
                    ref("stg_bank_sg_sgd_revolut_v2"),
                    ref("stg_bank_sg_sgd_scbcc"),
                    ref("stg_bank_sg_sgd_uob"),
                    ref("stg_bank_sg_sgd_uobcc"),
                ],
                source_column_name=None,
            )
        }}
    )

select source, local_date, local_currency, local_amount, category, description
from union_all
