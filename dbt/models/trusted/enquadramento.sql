with enquadramento_tratado as (

    select

        nullif(
            trim("Segmento"),
            ''
        ) as segmento,

        nullif(
            trim("CNPJ"),
            ''
        ) as cnpj_original,

        case
            when nullif(trim("CNPJ"), '') is null
                then null

            else lpad(
                trim("CNPJ"),
                8,
                '0'
            )
        end as cnpj_if,

        nullif(
            trim("Nome"),
            ''
        ) as nome_conglomerado,

        _source_file,
        _source_row_number,
        _ingested_at_utc

    from {{ source('raw', 'enquadramento') }}

)

select *
from enquadramento_tratado
