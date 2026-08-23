import os
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine import URL


def criar_engine():
    url = URL.create(
        drivername="postgresql+psycopg",
        username=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
        host=os.environ.get("POSTGRES_HOST", "postgres"),
        port=int(os.environ.get("POSTGRES_PORT", "5432")),
        database=os.environ["POSTGRES_DB"],
    )

    return create_engine(url)


TABELAS = [
    (
        "trusted",
        "reclamacoes",
        Path("/data/trusted/reclamacoes.parquet"),
    ),
    (
        "trusted",
        "enquadramento",
        Path("/data/trusted/enquadramento.parquet"),
    ),
    (
        "trusted",
        "glassdoor",
        Path("/data/trusted/glassdoor.parquet"),
    ),
    (
        "delivery",
        "tabela_final",
        Path("/data/delivery/tabela_final.parquet"),
    ),
]


def exportar_tabela(engine, schema, tabela, destino):
    destino.parent.mkdir(parents=True, exist_ok=True)

    consulta = f'SELECT * FROM "{schema}"."{tabela}"'

    dataframe = pd.read_sql_query(
        consulta,
        engine,
    )

    dataframe.to_parquet(
        destino,
        engine="pyarrow",
        index=False,
    )

    # Leitura de retorno para confirmar que o arquivo
    # Parquet pode ser aberto corretamente.
    validacao = pd.read_parquet(
        destino,
        engine="pyarrow",
    )

    linhas_banco = len(dataframe)
    linhas_parquet = len(validacao)

    if linhas_banco != linhas_parquet:
        raise RuntimeError(
            f"Falha de cardinalidade em {schema}.{tabela}: "
            f"banco={linhas_banco}, parquet={linhas_parquet}"
        )

    tamanho_bytes = destino.stat().st_size

    print(
        f"[OK] {schema}.{tabela} -> {destino} | "
        f"linhas_banco={linhas_banco} | "
        f"linhas_parquet={linhas_parquet} | "
        f"bytes={tamanho_bytes}"
    )


def main():
    print("=" * 70)
    print("EXPORTACAO DAS CAMADAS TRUSTED E DELIVERY PARA PARQUET")
    print("=" * 70)

    engine = criar_engine()

    try:
        for schema, tabela, destino in TABELAS:
            exportar_tabela(
                engine,
                schema,
                tabela,
                destino,
            )

    finally:
        engine.dispose()

    print("=" * 70)
    print("EXPORTACAO CONCLUIDA COM SUCESSO")
    print("=" * 70)


if __name__ == "__main__":
    main()