from pathlib import Path
from datetime import datetime, timezone
import os
import re

import pandas as pd
from sqlalchemy import create_engine, text


INPUT_DIR = Path("/data/input")

DB_HOST = os.getenv("POSTGRES_HOST", "postgres")
DB_PORT = os.getenv("POSTGRES_PORT", "5432")
DB_NAME = os.getenv("POSTGRES_DB", "atividade4")
DB_USER = os.getenv("POSTGRES_USER", "atividade4")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD")


def normalize_table_name(filename: str) -> str:
    """
    Converte apenas o nome físico do arquivo em um identificador
    compatível com PostgreSQL. Os dados internos não são transformados.
    """
    name = Path(filename).stem.lower()
    name = re.sub(r"[^a-z0-9]+", "_", name)
    return name.strip("_")


def read_file(path: Path) -> pd.DataFrame:
    """
    Realiza apenas a interpretação física correta dos arquivos de origem.

    Não são aplicadas transformações de negócio nesta etapa.
    """

    filename = path.name.lower()

    # Arquivo TSV
    if path.suffix.lower() == ".tsv":
        return pd.read_csv(
            path,
            sep="\t",
            dtype=str,
            encoding="utf-8",
            keep_default_na=False
        )

    # Arquivos Glassdoor: delimitador pipe (|)
    if filename.startswith("glassdoor_"):
        return pd.read_csv(
            path,
            sep="|",
            dtype=str,
            encoding="utf-8",
            keep_default_na=False
        )

    # Demais arquivos CSV
    encodings = ["utf-8-sig", "utf-8", "latin-1"]

    last_error = None

    for encoding in encodings:
        try:
            return pd.read_csv(
                path,
                sep=None,
                engine="python",
                dtype=str,
                encoding=encoding,
                keep_default_na=False
            )

        except Exception as exc:
            last_error = exc

    raise RuntimeError(
        f"Não foi possível ler {path.name}. "
        f"Último erro: {last_error}"
    )


def main():

    print("=" * 70)
    print("ATIVIDADE 4 - INGESTÃO DA CAMADA RAW")
    print("=" * 70)

    if not DB_PASSWORD:
        raise RuntimeError("Variável POSTGRES_PASSWORD não definida.")

    connection_url = (
        f"postgresql+psycopg://{DB_USER}:{DB_PASSWORD}"
        f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

    engine = create_engine(connection_url)

    print("\n[1] Testando conexão com PostgreSQL...")

    with engine.begin() as connection:
        connection.execute(
            text("CREATE SCHEMA IF NOT EXISTS raw")
        )

    print("    Conexão estabelecida.")
    print("    Schema RAW disponível.")

    files = sorted(
        [
            path
            for path in INPUT_DIR.iterdir()
            if path.suffix.lower() in {".csv", ".tsv"}
        ]
    )

    if not files:
        raise RuntimeError(
            f"Nenhum arquivo CSV/TSV encontrado em {INPUT_DIR}"
        )

    print(f"\n[2] Arquivos encontrados: {len(files)}")

    total_rows = 0

    for index, path in enumerate(files, start=1):

        table_name = normalize_table_name(path.name)

        print("\n" + "-" * 70)
        print(f"[{index}/{len(files)}] Arquivo: {path.name}")
        print(f"        Tabela RAW: raw.{table_name}")

        df = read_file(path)

        original_rows = len(df)
        original_columns = len(df.columns)

        #
        # Metadados técnicos de rastreabilidade.
        # Não representam transformação de negócio.
        #
        df["_source_file"] = path.name
        df["_source_row_number"] = range(1, len(df) + 1)
        df["_ingested_at_utc"] = datetime.now(timezone.utc)

        print(f"        Linhas: {original_rows}")
        print(f"        Colunas de origem: {original_columns}")

        df.to_sql(
            name=table_name,
            con=engine,
            schema="raw",
            if_exists="replace",
            index=False,
            chunksize=1000
        )

        total_rows += original_rows

        print("        Status: CARREGADO COM SUCESSO")

    print("\n" + "=" * 70)
    print("RESUMO DA INGESTÃO")
    print("=" * 70)
    print(f"Arquivos processados : {len(files)}")
    print(f"Linhas carregadas     : {total_rows}")
    print("Schema de destino     : raw")
    print("Resultado              : SUCESSO")
    print("=" * 70)


if __name__ == "__main__":
    main()
