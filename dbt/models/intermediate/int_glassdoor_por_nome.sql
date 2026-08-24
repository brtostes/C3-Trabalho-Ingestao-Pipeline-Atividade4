with ranqueado as (

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

    from {{ ref('int_glassdoor_normalizado') }} g
)

select *
from ranqueado
where rn_nome = 1
