select

    r.*,

    {{
        normalizar_nome(
            'r.instituicao_financeira',
            '[[:space:]]*[(]CONGLOMERADO[)][[:space:]]*$'
        )
    }} as instituicao_nome_normalizado

from {{ ref('reclamacoes') }} r