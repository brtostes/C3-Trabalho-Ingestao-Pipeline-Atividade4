select distinct

    e.cnpj_if,
    e.segmento,
    e.nome_conglomerado,

    trim(
        regexp_replace(
            regexp_replace(
                translate(
                    upper(
                        regexp_replace(
                            trim(e.nome_conglomerado),
                            '[[:space:]]*-[[:space:]]*PRUDENCIAL[[:space:]]*$',
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
    ) as nome_normalizado

from {{ ref('enquadramento_base') }} e

where e.cnpj_if is not null
  and e.nome_conglomerado is not null