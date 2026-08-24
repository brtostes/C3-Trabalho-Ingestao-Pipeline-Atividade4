with base as (

    select *
    from {{ ref('enquadramento_base') }}

    where cnpj_if is not null

),

estatisticas as (

    select

        cnpj_if,

        count(*) as quantidade_registros_cnpj,

        count(distinct segmento)
            as quantidade_segmentos_cnpj,

        count(distinct nome_conglomerado)
            as quantidade_nomes_cnpj,

        string_agg(
            distinct nome_conglomerado,
            ' | '
            order by nome_conglomerado
        ) as nomes_associados

    from base

    group by cnpj_if

),

ranqueado as (

    select

        b.*,

        row_number() over (

            partition by b.cnpj_if

            order by

                /*
                Prioridade 1:
                registro identificado como PRUDENCIAL.
                */
                case
                    when b.nome_conglomerado
                         ~* '[[:space:]]*-[[:space:]]*PRUDENCIAL[[:space:]]*$'
                    then 1
                    else 2
                end,

                /*
                Prioridade 2:
                ordem original da fonte.
                */
                b._source_row_number,

                /*
                Prioridade 3:
                nome para desempate determinístico.
                */
                b.nome_conglomerado

        ) as ordem_canonica

    from base b

),

canonico as (

    select

        r.segmento,
        r.cnpj_original,
        r.cnpj_if,
        r.nome_conglomerado,

        e.quantidade_registros_cnpj,

        (
            e.quantidade_registros_cnpj > 1
        ) as cnpj_duplicado,

        e.quantidade_segmentos_cnpj,
        e.quantidade_nomes_cnpj,
        e.nomes_associados,

        case

            when e.quantidade_registros_cnpj = 1
                then 'REGISTRO_UNICO'

            when r.nome_conglomerado
                 ~* '[[:space:]]*-[[:space:]]*PRUDENCIAL[[:space:]]*$'
                then 'PRIORIDADE_PRUDENCIAL'

            else 'DESEMPATE_ORDEM_FONTE'

        end as regra_deduplicacao,

        r._source_file,
        r._source_row_number,
        r._ingested_at_utc

    from ranqueado r

    inner join estatisticas e
        on r.cnpj_if = e.cnpj_if

    where r.ordem_canonica = 1

)

select *
from canonico