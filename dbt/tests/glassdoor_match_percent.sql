SELECT *
FROM {{ ref('glassdoor') }}

WHERE match_percent IS NOT NULL
  AND (
        match_percent < 0
        OR match_percent > 100
      )
