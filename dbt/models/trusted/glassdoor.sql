with glassdoor_match as (

    select

        nullif(trim("employer_name"), '') as employer_name,

        cast(
            nullif(trim("reviews_count"), '')
            as bigint
        ) as reviews_count,

        cast(
            nullif(trim("culture_count"), '')
            as bigint
        ) as culture_count,

        cast(
            nullif(trim("salaries_count"), '')
            as bigint
        ) as salaries_count,

        cast(
            nullif(trim("benefits_count"), '')
            as bigint
        ) as benefits_count,

        nullif(trim("employer-website"), '') as employer_website,

        nullif(trim("employer-headquarters"), '') as employer_headquarters,

        cast(
            nullif(
                regexp_replace(
                    trim("employer-founded"),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as integer
        ) as employer_founded,

        nullif(trim("employer-industry"), '') as employer_industry,

        nullif(trim("employer-revenue"), '') as employer_revenue,

        nullif(trim("url"), '') as glassdoor_url,


        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_v2'
                      and ordinal_position = 12
                ),
                ''
            )
            as numeric(4,2)
        ) as avaliacao_geral,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_v2'
                      and ordinal_position = 13
                ),
                ''
            )
            as numeric(4,2)
        ) as cultura_valores,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_v2'
                      and ordinal_position = 14
                ),
                ''
            )
            as numeric(4,2)
        ) as diversidade_inclusao,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_v2'
                      and ordinal_position = 15
                ),
                ''
            )
            as numeric(4,2)
        ) as qualidade_vida,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_v2'
                      and ordinal_position = 16
                ),
                ''
            )
            as numeric(4,2)
        ) as alta_lideranca,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_v2'
                      and ordinal_position = 17
                ),
                ''
            )
            as numeric(4,2)
        ) as remuneracao_beneficios,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_v2'
                      and ordinal_position = 18
                ),
                ''
            )
            as numeric(4,2)
        ) as oportunidades_carreira,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_v2'
                      and ordinal_position = 19
                ),
                ''
            )
            as numeric(6,2)
        ) as recomendam_percentual,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_v2'
                      and ordinal_position = 20
                ),
                ''
            )
            as numeric(6,2)
        ) as perspectiva_positiva_percentual,


        nullif(trim("Segmento"), '') as segmento,

        cast(null as text) as cnpj_original,

        cast(null as text) as cnpj_if,

        nullif(trim("Nome"), '') as nome_conglomerado,

        cast(
            nullif(trim("match_percent"), '')
            as numeric(6,2)
        ) as match_percent,

        'match'::text as tipo_match,

        _source_file,
        _source_row_number,
        _ingested_at_utc

    from {{ source('raw', 'glassdoor_match') }} r
),


glassdoor_match_less as (

    select

        nullif(trim("employer_name"), '') as employer_name,

        cast(nullif(trim("reviews_count"), '') as bigint) as reviews_count,
        cast(nullif(trim("culture_count"), '') as bigint) as culture_count,
        cast(nullif(trim("salaries_count"), '') as bigint) as salaries_count,
        cast(nullif(trim("benefits_count"), '') as bigint) as benefits_count,

        nullif(trim("employer-website"), '') as employer_website,
        nullif(trim("employer-headquarters"), '') as employer_headquarters,

        cast(
            nullif(
                regexp_replace(
                    trim("employer-founded"),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as integer
        ) as employer_founded,

        nullif(trim("employer-industry"), '') as employer_industry,
        nullif(trim("employer-revenue"), '') as employer_revenue,
        nullif(trim("url"), '') as glassdoor_url,


        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_less_v2'
                      and ordinal_position = 12
                ),
                ''
            )
            as numeric(4,2)
        ) as avaliacao_geral,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_less_v2'
                      and ordinal_position = 13
                ),
                ''
            )
            as numeric(4,2)
        ) as cultura_valores,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_less_v2'
                      and ordinal_position = 14
                ),
                ''
            )
            as numeric(4,2)
        ) as diversidade_inclusao,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_less_v2'
                      and ordinal_position = 15
                ),
                ''
            )
            as numeric(4,2)
        ) as qualidade_vida,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_less_v2'
                      and ordinal_position = 16
                ),
                ''
            )
            as numeric(4,2)
        ) as alta_lideranca,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_less_v2'
                      and ordinal_position = 17
                ),
                ''
            )
            as numeric(4,2)
        ) as remuneracao_beneficios,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_less_v2'
                      and ordinal_position = 18
                ),
                ''
            )
            as numeric(4,2)
        ) as oportunidades_carreira,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_less_v2'
                      and ordinal_position = 19
                ),
                ''
            )
            as numeric(6,2)
        ) as recomendam_percentual,

        cast(
            nullif(
                to_jsonb(r) ->> (
                    select column_name
                    from information_schema.columns
                    where table_schema = 'raw'
                      and table_name = 'glassdoor_consolidado_join_match_less_v2'
                      and ordinal_position = 20
                ),
                ''
            )
            as numeric(6,2)
        ) as perspectiva_positiva_percentual,


        cast(null as text) as segmento,

        nullif(trim("CNPJ"), '') as cnpj_original,

        case
            when nullif(trim("CNPJ"), '') is null
                then null
            else lpad(trim("CNPJ"), 8, '0')
        end as cnpj_if,

        nullif(trim("Nome"), '') as nome_conglomerado,

        cast(
            nullif(trim("match_percent"), '')
            as numeric(6,2)
        ) as match_percent,

        'match_less'::text as tipo_match,

        _source_file,
        _source_row_number,
        _ingested_at_utc

    from {{ source('raw', 'glassdoor_match_less') }} r
)

select *
from glassdoor_match

union all

select *
from glassdoor_match_less
