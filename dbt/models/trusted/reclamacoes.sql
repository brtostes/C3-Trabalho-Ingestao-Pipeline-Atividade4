{% set tabelas = [
    {"source_name": "t2021_tri_01", "table_name": "2021_tri_01"},
    {"source_name": "t2021_tri_02", "table_name": "2021_tri_02"},
    {"source_name": "t2021_tri_03", "table_name": "2021_tri_03"},
    {"source_name": "t2021_tri_04", "table_name": "2021_tri_04"},
    {"source_name": "t2022_tri_01", "table_name": "2022_tri_01"},
    {"source_name": "t2022_tri_03", "table_name": "2022_tri_03"},
    {"source_name": "t2022_tri_04", "table_name": "2022_tri_04"}
] %}


with reclamacoes_unificadas as (

{% for t in tabelas %}

    select

        cast(
            nullif(trim(r."Ano"), '')
            as integer
        ) as ano,

        cast(
            nullif(
                regexp_replace(
                    trim(r."Trimestre"),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as integer
        ) as trimestre,

        nullif(
            trim(r."Categoria"),
            ''
        ) as categoria,

        nullif(
            trim(r."Tipo"),
            ''
        ) as tipo,

        nullif(
            trim(r."CNPJ IF"),
            ''
        ) as cnpj_if,

        nullif(
            trim(r."Instituição financeira"),
            ''
        ) as instituicao_financeira,

        cast(
            nullif(
                case
                    when trim(r."Índice") like '%,%'
                    then replace(
                        replace(trim(r."Índice"), '.', ''),
                        ',',
                        '.'
                    )
                    else trim(r."Índice")
                end,
                ''
            )
            as numeric(18,4)
        ) as indice,

        cast(
            nullif(
                regexp_replace(
                    trim(r."Quantidade de reclamações reguladas procedentes"),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as bigint
        ) as quantidade_reclamacoes_reguladas_procedentes,

        cast(
            nullif(
                regexp_replace(
                    trim(r."Quantidade de reclamações reguladas - outras"),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as bigint
        ) as quantidade_reclamacoes_reguladas_outras,

        cast(
            nullif(
                regexp_replace(
                    trim(r."Quantidade de reclamações não reguladas"),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as bigint
        ) as quantidade_reclamacoes_nao_reguladas,

        cast(
            nullif(
                regexp_replace(
                    trim(r."Quantidade total de reclamações"),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as bigint
        ) as quantidade_total_reclamacoes,


        /*
        As três colunas seguintes possuem o caractere
        de controle U+0096 no cabeçalho da fonte.

        Para manter a RAW intacta, o nome real é recuperado
        do catálogo do PostgreSQL pela posição ordinal.
        */

        cast(
            nullif(
                regexp_replace(
                    trim(
                        to_jsonb(r) ->> (
                            select c.column_name
                            from information_schema.columns c
                            where c.table_schema = 'raw'
                              and c.table_name = '{{ t["table_name"] }}'
                              and c.ordinal_position = 12
                        )
                    ),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as bigint
        ) as quantidade_total_clientes_ccs_scr,

        cast(
            nullif(
                regexp_replace(
                    trim(
                        to_jsonb(r) ->> (
                            select c.column_name
                            from information_schema.columns c
                            where c.table_schema = 'raw'
                              and c.table_name = '{{ t["table_name"] }}'
                              and c.ordinal_position = 13
                        )
                    ),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as bigint
        ) as quantidade_clientes_ccs,

        cast(
            nullif(
                regexp_replace(
                    trim(
                        to_jsonb(r) ->> (
                            select c.column_name
                            from information_schema.columns c
                            where c.table_schema = 'raw'
                              and c.table_name = '{{ t["table_name"] }}'
                              and c.ordinal_position = 14
                        )
                    ),
                    '[^0-9]',
                    '',
                    'g'
                ),
                ''
            )
            as bigint
        ) as quantidade_clientes_scr,


        /*
        Metadados técnicos preservados para rastreabilidade.
        */

        r._source_file,
        r._source_row_number,
        r._ingested_at_utc

    from {{ source('raw', t["source_name"]) }} as r

{% if not loop.last %}
    union all
{% endif %}

{% endfor %}

)

select *
from reclamacoes_unificadas
