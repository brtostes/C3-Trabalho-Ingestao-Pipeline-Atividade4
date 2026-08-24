with

/*
==============================================================
1. ENQUADRAMENTO CANÔNICO
A deduplicação dos CNPJs é realizada previamente no modelo
trusted.enquadramento.

Neste ponto, cada CNPJ possui apenas um registro canônico.
==============================================================
*/

enquadramento_canonico as (

    select

        cnpj_if,
        segmento,
        nome_conglomerado

    from {{ ref('enquadramento') }}

),

/*
==============================================================
2. ALIASES DO ENQUADRAMENTO
Os nomes alternativos dos CNPJs são preservados em modelo
específico para aumentar a capacidade de associação com
os registros do Glassdoor.
==============================================================
*/

enquadramento_aliases as (

    select

        cnpj_if,
        segmento,
        nome_conglomerado,
        nome_normalizado

    from {{ ref('enquadramento_aliases') }}

),

/*
==============================================================
3. GLASSDOOR NORMALIZADO
==============================================================
*/

glassdoor_normalizado as (

    select

        g.*,

        trim(
            regexp_replace(
                regexp_replace(
                    translate(
                        upper(trim(g.nome_conglomerado)),
                        'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                        'AAAAAEEEEIIIIOOOOOUUUUC'
                    ),
                    '[^A-Z0-9]+',
                    ' ',
                    'g'
                ),
                '[[:space:]]+',
                ' ',
                'g'
            )
        ) as nome_normalizado

    from {{ ref('glassdoor') }} g

    where g.nome_conglomerado is not null
),


/*
==============================================================
4. UM REGISTRO GLASSDOOR POR NOME DE CONGLOMERADO
==============================================================
*/

glassdoor_nome_ranqueado as (

    select

        g.*,

        row_number() over (

            partition by g.nome_normalizado

            order by

                g.match_percent desc nulls last,

                case
                    when g.tipo_match = 'match'
                    then 1
                    else 2
                end,

                g.reviews_count desc nulls last,

                g.employer_name

        ) as rn_nome

    from glassdoor_normalizado g
),

glassdoor_por_nome as (

    select *
    from glassdoor_nome_ranqueado

    where rn_nome = 1
),


/*
==============================================================
5. CANDIDATOS GLASSDOOR POR CNPJ VIA ALIASES
==============================================================
*/

glassdoor_cnpj_por_alias as (

    select distinct

        a.cnpj_if,

        g.employer_name,
        g.reviews_count,
        g.culture_count,
        g.salaries_count,
        g.benefits_count,

        g.employer_website,
        g.employer_headquarters,
        g.employer_founded,
        g.employer_industry,
        g.employer_revenue,
        g.glassdoor_url,

        g.avaliacao_geral,
        g.cultura_valores,
        g.diversidade_inclusao,
        g.qualidade_vida,
        g.alta_lideranca,
        g.remuneracao_beneficios,
        g.oportunidades_carreira,
        g.recomendam_percentual,
        g.perspectiva_positiva_percentual,

        g.nome_conglomerado as glassdoor_nome_conglomerado,
        g.match_percent,
        g.tipo_match,

        'alias_enquadramento'::text as metodo_vinculo

    from enquadramento_aliases a

    join glassdoor_normalizado g
      on a.nome_normalizado = g.nome_normalizado

     and (
            g.segmento is null
            or g.segmento = a.segmento
         )
),


/*
==============================================================
6. CANDIDATOS DIRETOS POR CNPJ DOS REGISTROS MATCH_LESS
==============================================================
*/

glassdoor_cnpj_direto as (

    select distinct

        g.cnpj_if,

        g.employer_name,
        g.reviews_count,
        g.culture_count,
        g.salaries_count,
        g.benefits_count,

        g.employer_website,
        g.employer_headquarters,
        g.employer_founded,
        g.employer_industry,
        g.employer_revenue,
        g.glassdoor_url,

        g.avaliacao_geral,
        g.cultura_valores,
        g.diversidade_inclusao,
        g.qualidade_vida,
        g.alta_lideranca,
        g.remuneracao_beneficios,
        g.oportunidades_carreira,
        g.recomendam_percentual,
        g.perspectiva_positiva_percentual,

        g.nome_conglomerado as glassdoor_nome_conglomerado,
        g.match_percent,
        g.tipo_match,

        'cnpj_glassdoor'::text as metodo_vinculo

    from glassdoor_normalizado g

    where g.cnpj_if is not null
),


/*
==============================================================
7. CONSOLIDA OS CANDIDATOS DE CNPJ
==============================================================
*/

glassdoor_cnpj_candidatos as (

    select *
    from glassdoor_cnpj_por_alias

    union

    select *
    from glassdoor_cnpj_direto
),

glassdoor_cnpj_ranqueado as (

    select

        g.*,

        row_number() over (

            partition by g.cnpj_if

            order by

                g.match_percent desc nulls last,

                case
                    when g.tipo_match = 'match'
                    then 1
                    else 2
                end,

                g.reviews_count desc nulls last,

                g.employer_name

        ) as rn_cnpj

    from glassdoor_cnpj_candidatos g
),

glassdoor_por_cnpj as (

    select *
    from glassdoor_cnpj_ranqueado

    where rn_cnpj = 1
),


/*
==============================================================
8. NORMALIZA O NOME DA INSTITUIÇÃO DA RECLAMAÇÃO
==============================================================
*/

reclamacoes_normalizadas as (

    select

        r.*,

        trim(
            regexp_replace(
                regexp_replace(
                    translate(
                        upper(
                            regexp_replace(
                                trim(r.instituicao_financeira),
                                '[[:space:]]*\(CONGLOMERADO\)[[:space:]]*$',
                                '',
                                'i'
                            )
                        ),
                        'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                        'AAAAAEEEEIIIIOOOOOUUUUC'
                    ),
                    '[^A-Z0-9]+',
                    ' ',
                    'g'
                ),
                '[[:space:]]+',
                ' ',
                'g'
            )
        ) as instituicao_nome_normalizado

    from {{ ref('reclamacoes') }} r
),


/*
==============================================================
9. TABELA FINAL
Granularidade preservada:
uma linha por registro de trusted.reclamacoes.
==============================================================
*/

final as (

    select

        r.ano,
        r.trimestre,
        r.categoria,
        r.tipo,

        r.cnpj_if,
        r.instituicao_financeira,

        r.indice,

        r.quantidade_reclamacoes_reguladas_procedentes,
        r.quantidade_reclamacoes_reguladas_outras,
        r.quantidade_reclamacoes_nao_reguladas,
        r.quantidade_total_reclamacoes,

        r.quantidade_total_clientes_ccs_scr,
        r.quantidade_clientes_ccs,
        r.quantidade_clientes_scr,


        /*
        Dados de enquadramento
        */

        e.segmento,

        coalesce(
            e.nome_conglomerado,
            gn.nome_conglomerado
        ) as nome_conglomerado,


        /*
        Dados Glassdoor
        Prioridade:
        CNPJ/enquadramento -> nome do conglomerado.
        */

        coalesce(
            gc.employer_name,
            gn.employer_name
        ) as glassdoor_employer_name,

        coalesce(
            gc.reviews_count,
            gn.reviews_count
        ) as glassdoor_reviews_count,

        coalesce(
            gc.culture_count,
            gn.culture_count
        ) as glassdoor_culture_count,

        coalesce(
            gc.salaries_count,
            gn.salaries_count
        ) as glassdoor_salaries_count,

        coalesce(
            gc.benefits_count,
            gn.benefits_count
        ) as glassdoor_benefits_count,

        coalesce(
            gc.avaliacao_geral,
            gn.avaliacao_geral
        ) as glassdoor_avaliacao_geral,

        coalesce(
            gc.cultura_valores,
            gn.cultura_valores
        ) as glassdoor_cultura_valores,

        coalesce(
            gc.diversidade_inclusao,
            gn.diversidade_inclusao
        ) as glassdoor_diversidade_inclusao,

        coalesce(
            gc.qualidade_vida,
            gn.qualidade_vida
        ) as glassdoor_qualidade_vida,

        coalesce(
            gc.alta_lideranca,
            gn.alta_lideranca
        ) as glassdoor_alta_lideranca,

        coalesce(
            gc.remuneracao_beneficios,
            gn.remuneracao_beneficios
        ) as glassdoor_remuneracao_beneficios,

        coalesce(
            gc.oportunidades_carreira,
            gn.oportunidades_carreira
        ) as glassdoor_oportunidades_carreira,

        coalesce(
            gc.recomendam_percentual,
            gn.recomendam_percentual
        ) as glassdoor_recomendam_percentual,

        coalesce(
            gc.perspectiva_positiva_percentual,
            gn.perspectiva_positiva_percentual
        ) as glassdoor_perspectiva_positiva_percentual,

        coalesce(
            gc.match_percent,
            gn.match_percent
        ) as glassdoor_match_percent,

        coalesce(
            gc.tipo_match,
            gn.tipo_match
        ) as glassdoor_tipo_match,


        /*
        Indicadores de auditoria do enriquecimento
        */

        case
            when e.cnpj_if is not null
            then true
            else false
        end as enquadramento_encontrado,

        case
            when gc.employer_name is not null
              or gn.employer_name is not null
            then true
            else false
        end as glassdoor_encontrado,

        case

            when gc.employer_name is not null
            then gc.metodo_vinculo

            when gn.employer_name is not null
            then 'nome_conglomerado'

            else 'sem_correspondencia'

        end as glassdoor_metodo_vinculo,


        /*
        Metadados da reclamação original
        */

        r._source_file,
        r._source_row_number,
        r._ingested_at_utc

    from reclamacoes_normalizadas r


    left join enquadramento_canonico e
        on r.cnpj_if = e.cnpj_if


    left join glassdoor_por_cnpj gc
        on r.cnpj_if = gc.cnpj_if


    left join glassdoor_por_nome gn
        on r.cnpj_if is null
       and r.instituicao_nome_normalizado = gn.nome_normalizado
)

select *
from final