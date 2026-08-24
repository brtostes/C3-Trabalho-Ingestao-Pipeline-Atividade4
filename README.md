# Atividade 4 — Ingestão e ETL com Python + PostgreSQL + dbt

Projeto desenvolvido para a disciplina **Ingestão de Dados e Pipeline** do PECE/Poli-USP.

## Objetivo

Implementar um pipeline de dados conteinerizado em Docker, utilizando **Python para ingestão**, **PostgreSQL como banco relacional** e **dbt + SQL para tratamento, padronização, integração e construção das camadas Trusted e Delivery**, com rastreabilidade, testes automatizados e exportação para Parquet.

## Arquitetura final

```text
10 arquivos de entrada
        |
        | Python 3.12
        | ingest_raw.py + text_utils.py
        v
       RAW
10 tabelas / 2.431 registros
        |
        | dbt
        v
     TRUSTED
  +-------------------------------------------+
  | reclamacoes              918 linhas       |
  | enquadramento canônico 1.459 linhas       |
  | enquadramento_aliases  1.474 linhas       |
  | glassdoor                 39 linhas       |
  +-------------------------------------------+
        |
        | modelos intermediate (ephemeral)
        | + macro normalizar_nome
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
- dbt Core 1.12.3
- dbt-postgres 1.11.0
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
│   ├── text_utils.py
│   └── export_parquet.py
├── dbt/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── macros/
│   │   ├── generate_schema_name.sql
│   │   └── normalizar_nome.sql
│   ├── models/
│   │   ├── trusted/
│   │   ├── intermediate/
│   │   └── delivery/
│   └── tests/
├── data/
│   ├── input/
│   ├── trusted/
│   └── delivery/
├── evidencias/
└── apresentacao/
```

## Aprimoramentos realizados após a avaliação

### 1. Tratamento de CNPJs duplicados

A deduplicação foi transferida para a camada Trusted. O modelo `trusted.enquadramento` passou a selecionar deterministicamente **um registro canônico por CNPJ-base**, priorizando denominações com sufixo `- PRUDENCIAL` quando disponíveis. Os nomes alternativos são preservados em `trusted.enquadramento_aliases` para uso no matching.

Resultado:

- origem: 1.474 registros;
- CNPJs distintos: 1.459;
- CNPJs duplicados detectados: 15;
- `trusted.enquadramento`: 1.459 linhas e 1.459 CNPJs distintos;
- teste `unique` do CNPJ canônico aprovado.

### 2. Tratamento do Unicode U+0096

O tratamento de cabeçalhos foi incorporado à ingestão por meio de `scripts/text_utils.py`. A função reutilizável normaliza U+0096 e variantes tipográficas de hífen/travessão antes da persistência na RAW, sem alterar os valores dos dados de negócio e sem modificar hífens ASCII já válidos.

### 3. Maior uso dos recursos nativos do dbt

A lógica antes concentrada na Delivery foi decomposta em modelos intermediários `ephemeral`, conectados por `ref()`:

- `int_reclamacoes_normalizadas`;
- `int_glassdoor_normalizado`;
- `int_glassdoor_por_nome`;
- `int_glassdoor_por_cnpj`.

A macro `normalizar_nome` centraliza a regra de normalização textual utilizada em mais de um modelo. A `delivery.tabela_final` ficou responsável principalmente pela integração final.

## Resultados principais

- 10 arquivos ingeridos na camada RAW.
- 2.431 registros carregados na RAW.
- 918 registros em `trusted.reclamacoes`.
- 1.459 registros canônicos em `trusted.enquadramento`.
- 1.474 registros em `trusted.enquadramento_aliases`.
- 39 registros em `trusted.glassdoor`.
- 918 registros em `delivery.tabela_final`.
- Cardinalidade preservada entre reclamações e Delivery: **918 → 918**.
- 321 linhas da Delivery enriquecidas pelo enquadramento (**34,97%**).
- 136 linhas enriquecidas com dados do Glassdoor (**14,81%**).
- Entre 481 linhas de conglomerados sem CNPJ, 120 receberam dados Glassdoor (**24,95%**).
- dbt reconhecendo **10 modelos**, **29 data tests**, **10 sources** e **479 macros**.
- `dbt build`: **34 PASS / 0 WARN / 0 ERROR / 0 SKIP**.

## Modelos dbt

Dos 10 modelos reconhecidos pelo dbt:

- 5 são materializados como tabelas: quatro em Trusted e um em Delivery;
- 5 são `ephemeral`: `enquadramento_base` e os quatro modelos `intermediate`.

Essa organização explicita a DAG do projeto e reduz SQL monolítico no modelo final.

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

Resultado final validado:

```text
Found 10 models, 29 data tests, 10 sources, 479 macros
Done. PASS=34 WARN=0 ERROR=0 SKIP=0 TOTAL=34
```

### Exportação para Parquet

```bash
docker compose run --rm \
  -v ./data/trusted:/data/trusted \
  -v ./data/delivery:/data/delivery \
  ingest python scripts/export_parquet.py
```

> **Atenção:** os arquivos Parquet versionados foram gerados antes da revisão final de deduplicação. Após as alterações de CNPJ, execute novamente a exportação para sincronizar integralmente os artefatos binários com o estado atual do banco; em especial `data/trusted/enquadramento.parquet`, que deve refletir 1.459 linhas canônicas.

## Qualidade e rastreabilidade

O projeto inclui testes automáticos de:

- cardinalidade da Delivery;
- preservação da granularidade;
- coerência dos indicadores Glassdoor;
- faixa válida de `match_percent`;
- valores aceitos para trimestre, segmento e tipo de match;
- campos obrigatórios (`not_null`);
- unicidade do CNPJ canônico;
- consistência do segmento por CNPJ.

As evidências de execução estão armazenadas em `evidencias/`, incluindo os registros das revisões de CNPJ, Unicode e refatoração dbt.

## Apresentação

A apresentação revisada está em:

`apresentacao/Apresentacao_Tarefa4_Engenharia_Dados.pptx`

Ela incorpora as três melhorias realizadas após a avaliação: deduplicação de CNPJ, tratamento de Unicode por função reutilizável e refatoração para maior uso de modelos, `ref()`, materialização `ephemeral` e macro dbt.

## Repositório

Projeto publicado em:

`https://github.com/brtostes/C3-Trabalho-Ingestao-Pipeline-Atividade4`
