SELECT *
FROM {{ ref('tabela_final') }}

WHERE
    (
        glassdoor_encontrado = TRUE
        AND glassdoor_employer_name IS NULL
    )

    OR

    (
        glassdoor_encontrado = FALSE
        AND glassdoor_employer_name IS NOT NULL
    )
