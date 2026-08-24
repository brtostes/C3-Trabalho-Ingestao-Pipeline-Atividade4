select distinct

    e.cnpj_if,
    e.segmento,
    e.nome_conglomerado,

    {{
        normalizar_nome(
            'e.nome_conglomerado',
            '[[:space:]]*-[[:space:]]*PRUDENCIAL[[:space:]]*$'
        )
    }} as nome_normalizado

from {{ ref('enquadramento_base') }} e

where e.cnpj_if is not null
  and e.nome_conglomerado is not null