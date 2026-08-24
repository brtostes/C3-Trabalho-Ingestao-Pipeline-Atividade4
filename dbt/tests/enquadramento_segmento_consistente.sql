select

    cnpj_if,

    count(distinct segmento) as quantidade_segmentos

from {{ ref('enquadramento_aliases') }}

group by cnpj_if

having count(distinct segmento) > 1