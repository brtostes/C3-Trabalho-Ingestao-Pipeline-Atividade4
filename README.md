# Atividade 4 — Ingestão e ETL com Python + PostgreSQL + dbt

Projeto desenvolvido para a disciplina **Ingestão de Dados e Pipeline** do PECE/Poli-USP.

## Objetivo

Implementar um pipeline conteinerizado em Docker com Python para ingestão, PostgreSQL como banco relacional e dbt para tratamento, padronização, integração e construção das camadas Trusted e Delivery, com rastreabilidade, testes automatizados e exportação para Parquet.

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
  reclamacoes              918
  enquadramento canônico 1.459
  enquadramento_aliases  1.474
  glassdoor                 39
        |
        | intermediate (ephemeral)
        | + macro normalizar_nome
        v
     DELIVERY
  tabela_final — 918 linhas
```

## Tecnologias

Docker / Docker Compose; Python 3.12; pandas; SQLAlchemy; psycopg; PostgreSQL 17; dbt Core 1.12.3; dbt-postgres 1.11.0; PyArrow / Parquet.

## Estrutura principal

```text
scripts/
  ingest_raw.py
  text_utils.py
  export_parquet.py
  finalizar_artefatos.ps1

dbt/
  macros/
    generate_schema_name.sql
    normalizar_nome.sql
  models/
    trusted/
    intermediate/
    delivery/
  tests/

data/
  input/
  trusted/
  delivery/

evidencias/
apresentacao/
```

## Revisões realizadas após a avaliação

### 1. CNPJs duplicados

A deduplicação foi transferida para a camada Trusted. `trusted.enquadramento` seleciona deterministicamente um registro canônico por CNPJ-base, priorizando denominações com sufixo `- PRUDENCIAL` quando disponíveis. Os nomes alternativos permanecem em `trusted.enquadramento_aliases`.

Resultado: 1.474 registros de origem, 1.459 CNPJs distintos, 15 grupos duplicados e 1.459 linhas canônicas após o tratamento.

### 2. Unicode U+0096

O tratamento de cabeçalhos foi incorporado à ingestão em `scripts/text_utils.py`. A função reutilizável normaliza U+0096 e variantes tipográficas de hífen/travessão sem alterar os valores dos dados de negócio nem hífens ASCII já válidos.

### 3. Uso mais amplo dos recursos nativos do dbt

A lógica antes concentrada na Delivery foi decomposta nos modelos `ephemeral`:

- `int_reclamacoes_normalizadas`;
- `int_glassdoor_normalizado`;
- `int_glassdoor_por_nome`;
- `int_glassdoor_por_cnpj`.

As dependências são declaradas por `ref()` e a macro `normalizar_nome` centraliza a padronização textual reutilizada em diferentes modelos.

## Resultados validados

- RAW: 2.431 registros em 10 tabelas.
- `trusted.reclamacoes`: 918 linhas.
- `trusted.enquadramento`: 1.459 linhas canônicas.
- `trusted.enquadramento_aliases`: 1.474 linhas.
- `trusted.glassdoor`: 39 linhas.
- `delivery.tabela_final`: 918 linhas.
- Cardinalidade: 918 → 918.
- Linhas com enquadramento: 321 (34,97%).
- Linhas com Glassdoor: 136 (14,81%).
- Cobertura Glassdoor nos conglomerados sem CNPJ: 120/481 (24,95%).
- Estado final do projeto: 10 modelos, 29 data tests, 10 sources e 479 macros reconhecidas.
- Último build bem-sucedido: 34 PASS, 0 WARN, 0 ERROR e 0 SKIP.

## Execução

```bash
docker compose up -d postgres
docker compose run --rm ingest
docker compose run --rm dbt dbt build
```

Exportação Parquet:

```bash
docker compose run --rm \
  -v ./data/trusted:/data/trusted \
  -v ./data/delivery:/data/delivery \
  ingest python scripts/export_parquet.py
```

> **Atenção:** os Parquets atualmente versionados foram gerados antes da revisão final de deduplicação. `data/trusted/enquadramento.parquet` deve ser reexportado para refletir as 1.459 linhas canônicas.

## Qualidade e evidências

O projeto inclui testes `not_null`, `accepted_values`, `unique` e testes singulares de cardinalidade, granularidade, coerência Glassdoor, faixa de `match_percent` e consistência de segmento. As evidências das revisões estão em `evidencias/`, incluindo os arquivos 35, 36 e 37 relativos à refatoração dbt.

## Apresentação

A pasta `apresentacao/` contém:

- o PPTX binário válido anteriormente publicado;
- `Apresentacao_Tarefa4_Engenharia_Dados_atualizada.md`, com o conteúdo integral da apresentação revisada e alinhada ao estado final do pipeline.

A versão PPTX revisada também foi produzida durante a revisão do trabalho e deve substituir o binário anterior quando a exportação binária for feita pelo ambiente local.

## Finalização dos artefatos binários

O script `scripts/finalizar_artefatos.ps1` automatiza a última sincronização da entrega. Ele:

1. valida que o PPTX informado possui 15 slides;
2. sobe o PostgreSQL e reconstrói as imagens Docker;
3. reexecuta a ingestão RAW;
4. executa `dbt build`;
5. reexporta os quatro arquivos Parquet;
6. valida as cardinalidades 918 / 1.459 / 39 / 918;
7. substitui a apresentação;
8. registra a evidência `39_finalizacao_artefatos_binarios.txt`;
9. faz `git commit` e `git push` dos binários finais.

No PowerShell, a partir da raiz do repositório:

```powershell
.\scripts\finalizar_artefatos.ps1 `
  -PptxPath "C:\caminho\Apresentacao_Tarefa4_Engenharia_Dados_GitHub_final.pptx"
```

## Repositório

`https://github.com/brtostes/C3-Trabalho-Ingestao-Pipeline-Atividade4`
