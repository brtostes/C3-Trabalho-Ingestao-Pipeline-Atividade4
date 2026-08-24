with

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

    from {{ ref('enquadramento_aliases') }} a

    inner join {{ ref('int_glassdoor_normalizado') }} g
        on a.nome_normalizado = g.nome_normalizado

       and (
            g.segmento is null
            or g.segmento = a.segmento
       )
),

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

    from {{ ref('int_glassdoor_normalizado') }} g

    where g.cnpj_if is not null
),

candidatos as (

    select *
    from glassdoor_cnpj_por_alias

    union

    select *
    from glassdoor_cnpj_direto
),

ranqueado as (

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

    from candidatos g
)

select *
from ranqueado
where rn_cnpj = 1
