SELECT
    _source_file,
    _source_row_number,
    COUNT(*) AS ocorrencias

FROM {{ ref('tabela_final') }}

GROUP BY
    _source_file,
    _source_row_number

HAVING COUNT(*) <> 1
