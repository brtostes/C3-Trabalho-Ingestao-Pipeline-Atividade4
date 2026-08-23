WITH contagens AS (

    SELECT
        (SELECT COUNT(*) FROM {{ ref('reclamacoes') }})
            AS trusted_reclamacoes,

        (SELECT COUNT(*) FROM {{ ref('tabela_final') }})
            AS delivery_tabela_final
)

SELECT *
FROM contagens
WHERE trusted_reclamacoes <> delivery_tabela_final
