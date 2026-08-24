select

    g.*,

    trim(
        regexp_replace(
            regexp_replace(
                translate(
                    upper(
                        trim(g.nome_conglomerado)
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
    ) as nome_normalizado

from {{ ref('glassdoor') }} g

where g.nome_conglomerado is not null
