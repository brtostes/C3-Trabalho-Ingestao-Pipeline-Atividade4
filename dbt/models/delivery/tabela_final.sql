select

    /*
    ==============================================================
    DADOS DA RECLAMAÇÃO
    ==============================================================
    */

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
    ==============================================================
    ENQUADRAMENTO
    ==============================================================
    */

    e.segmento,

    coalesce(
        e.nome_conglomerado,
        gn.nome_conglomerado
    ) as nome_conglomerado,


    /*
    ==============================================================
    DADOS GLASSDOOR

    Prioridade:
    1. associação por CNPJ;
    2. associação por nome normalizado.
    ==============================================================
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
    ==============================================================
    INDICADORES DE AUDITORIA
    ==============================================================
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
    ==============================================================
    METADADOS DE RASTREABILIDADE
    ==============================================================
    */

    r._source_file,
    r._source_row_number,
    r._ingested_at_utc


from {{ ref('int_reclamacoes_normalizadas') }} r


left join {{ ref('enquadramento') }} e
    on r.cnpj_if = e.cnpj_if


left join {{ ref('int_glassdoor_por_cnpj') }} gc
    on r.cnpj_if = gc.cnpj_if


left join {{ ref('int_glassdoor_por_nome') }} gn
    on r.cnpj_if is null
   and r.instituicao_nome_normalizado = gn.nome_normalizado
