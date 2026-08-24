select

    g.*,

    {{ normalizar_nome('g.nome_conglomerado') }}
        as nome_normalizado

from {{ ref('glassdoor') }} g

where g.nome_conglomerado is not null
