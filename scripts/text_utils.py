"""
Funções utilitárias para tratamento de textos durante a ingestão.

A normalização aqui realizada é exclusivamente técnica:
corrige caracteres Unicode problemáticos em nomes de colunas,
sem alterar os valores dos dados de negócio.
"""

import re
import unicodedata


# Apenas caracteres Unicode problemáticos são convertidos.
#
# Importante:
# o hífen ASCII normal "-" NÃO é modificado.
# Assim, nomes legítimos como "employer-website" permanecem intactos.
DASH_TRANSLATION = str.maketrans(
    {
        "\u0096": " - ",  # caractere de controle identificado na avaliação
        "\u2010": " - ",  # hyphen
        "\u2011": " - ",  # non-breaking hyphen
        "\u2012": " - ",  # figure dash
        "\u2013": " - ",  # en dash
        "\u2014": " - ",  # em dash
        "\u2212": " - ",  # minus sign
    }
)


def normalize_column_name(column_name: str) -> str:
    """
    Normaliza tecnicamente um nome de coluna.

    Regras:
    1. aplica normalização Unicode NFKC;
    2. converte U+0096 e variantes tipográficas de traço em hífen ASCII;
    3. preserva hífens ASCII existentes;
    4. remove caracteres Unicode de controle remanescentes;
    5. normaliza espaços.

    Exemplos:
        'Quantidade de clientes \\u0096 CCS'
        -> 'Quantidade de clientes - CCS'

        'Quantidade de clientes – CCS'
        -> 'Quantidade de clientes - CCS'

        'employer-website'
        -> 'employer-website'
    """

    text = unicodedata.normalize(
        "NFKC",
        str(column_name)
    )

    # Converte somente os caracteres Unicode mapeados.
    text = text.translate(DASH_TRANSLATION)

    # Elimina outros caracteres Unicode de controle.
    text = "".join(
        " "
        if unicodedata.category(character) in {"Cc", "Cf"}
        else character
        for character in text
    )

    # Normaliza apenas espaços repetidos.
    # Não mexemos nos hífens ASCII já existentes.
    text = re.sub(r"\s+", " ", text)

    return text.strip()


def normalize_dataframe_columns(dataframe):
    """
    Aplica normalize_column_name() a todas as colunas do DataFrame.

    Registra alterações de cabeçalho e impede que a normalização
    produza nomes de colunas duplicados.
    """

    original_columns = list(dataframe.columns)

    normalized_columns = [
        normalize_column_name(column)
        for column in original_columns
    ]

    duplicates = sorted(
        {
            column
            for column in normalized_columns
            if normalized_columns.count(column) > 1
        }
    )

    if duplicates:
        raise ValueError(
            "A normalização Unicode gerou nomes de colunas "
            f"duplicados: {duplicates}"
        )

    for original, normalized in zip(
        original_columns,
        normalized_columns
    ):
        if original != normalized:
            print(
                "        Cabeçalho normalizado: "
                f"{original!r} -> {normalized!r}"
            )

    dataframe.columns = normalized_columns

    return dataframe