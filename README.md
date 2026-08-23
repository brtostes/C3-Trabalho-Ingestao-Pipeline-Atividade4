# Atividade 4 — Ingestão e ETL com Python + SQL/dbt

Projeto desenvolvido para a disciplina **Ingestão de Dados e Pipeline** do PECE/Poli-USP.

## Objetivo

Implementar um pipeline de dados conteinerizado em Docker, utilizando **Python para ingestão**, **PostgreSQL como banco relacional** e **dbt + SQL para tratamento, padronização, integração e construção das camadas Trusted e Delivery**.

## Arquitetura

```text
10 arquivos de entrada
        |
        | Python
        v
       RAW
10 tabelas / 2.431 registros
        |
        | dbt + SQL
        v
     TRUSTED
  +-------------------------------+
  | reclamacoes       918 linhas  |
  | enquadramento   1.474 linhas  |
  | glassdoor          39 linhas  |
  +-------------------------------+
        |
        | dbt + SQL
        v
     DELIVERY
  tabela_final — 918 linhas
        |
        +--> PostgreSQL
        +--> Parquet
```

## Tecnologias

- Docker / Docker Compose
- Python 3.12
- pandas
- SQLAlchemy
- psycopg
- PostgreSQL 17
- dbt Core / dbt-postgres
- PyArrow / Parquet

## Estrutura do repositório

```text
.
├── Dockerfile.dbt
├── Dockerfile.python
├── docker-compose.yml
├── requirements.txt
├── scripts/
│   ├── ingest_raw.py
│   └── export_parquet.py
├── dbt/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── macros/
│   ├── models/
│   │   ├── trusted/
│   │   └── delivery/
│   └── tests/
├── data/
│   ├── input/
│   ├── trusted/
│   └── delivery/
├── evidencias/
└── apresentacao/
```

## Resultados principais

- 10 arquivos ingeridos na camada RAW.
- 2.431 registros carregados na RAW.
- 918 registros consolidados em `trusted.reclamacoes`.
- 1.474 registros em `trusted.enquadramento`.
- 39 registros em `trusted.glassdoor`.
- 918 registros em `delivery.tabela_final`.
- Cardinalidade preservada entre Trusted e Delivery: **918 → 918**, diferença zero.
- 321 linhas da Delivery enriquecidas pelo enquadramento (**34,97%**).
- 136 linhas enriquecidas com dados do Glassdoor (**14,81%**).
- Entre 481 linhas de conglomerados sem CNPJ, 120 receberam dados Glassdoor (**24,95%**).
- 24 testes dbt executados com **24 PASS / 0 ERROR**.
- `dbt build` executado com **28 PASS / 0 ERROR** (4 modelos + 24 testes).
- Exportação Parquet validada com preservação integral das cardinalidades.

## Execução

### Subir o PostgreSQL

```bash
docker compose up -d postgres
```

### Ingestão RAW

```bash
docker compose run --rm ingest
```

### Construção e testes dbt

```bash
docker compose run --rm dbt dbt build
```

### Exportação para Parquet

```bash
docker compose run --rm \
  -v ./data/trusted:/data/trusted \
  -v ./data/delivery:/data/delivery \
  ingest python scripts/export_parquet.py
```

## Qualidade e rastreabilidade

O projeto inclui testes automáticos de:

- cardinalidade da Delivery;
- preservação da granularidade;
- coerência dos indicadores Glassdoor;
- faixa válida de `match_percent`;
- valores aceitos para trimestre, segmento e tipo de match;
- campos obrigatórios (`not_null`).

As evidências de execução estão armazenadas em `evidencias/`.

## Apresentação

A apresentação final da atividade deve ser mantida em `apresentacao/Apresentacao_Tarefa4_Engenharia_Dados.pptx`.

## Repositório

Projeto publicado em:

`https://github.com/brtostes/C3-Trabalho-Ingestao-Pipeline-Atividade4`
