# Apresentação revisada — Atividade 4

Este arquivo registra o conteúdo atualizado da apresentação após as revisões da atividade. Ele deve ser usado como referência para o PPTX final.

## Slide 1 — Tarefa 4
**Pipeline de Ingestão, Transformação e Delivery**

Python • PostgreSQL • dbt • Docker • Parquet

- RAW: 2.431 linhas
- Trusted: reclamações 918; enquadramento canônico 1.459; Glassdoor 39
- Delivery: 918 linhas
- 29/29 testes dbt
- 34/34 no build

## Slide 2 — Objetivo e requisitos
Transformar arquivos de entrada em uma tabela analítica final, com camadas controladas e validação reprodutível.

- Docker com PostgreSQL isolado por serviço.
- Ingestão RAW com metadados de origem.
- Tratamento, tipagem, normalização e integração via dbt.
- Delivery no PostgreSQL e exportação Parquet.
- Evidências e publicação no GitHub.

## Slide 3 — Arquitetura implementada
- 10 arquivos CSV/TSV.
- Serviço `ingest`: Python 3.12.
- Serviço `postgres`: PostgreSQL 17.
- Serviço `dbt`: dbt-postgres.
- RAW → Trusted → Intermediate → Delivery.
- Porta externa 5434; comunicação interna `postgres:5432`.
- Healthcheck do banco.

## Slide 4 — Estrutura final do projeto
Destaques:
- `scripts/ingest_raw.py`
- `scripts/text_utils.py`
- `scripts/export_parquet.py`
- `dbt/macros/normalizar_nome.sql`
- `dbt/models/trusted/`
- `dbt/models/intermediate/`
- `dbt/models/delivery/`
- `dbt/tests/`
- `evidencias/`

Indicadores:
- 10 modelos dbt.
- 29 testes de dados.
- 4 arquivos Parquet previstos.

## Slide 5 — Camada RAW
- 10 arquivos processados.
- 2.431 linhas RAW.
- 10 tabelas RAW.
- 3 metadados de rastreabilidade por linha.
- `normalize_dataframe_columns()` aplicado aos cabeçalhos.
- Glassdoor identificado com delimitador `|`.
- Valores de negócio preservados.

## Slide 6 — Validação da RAW
Problemas tratados:
- cabeçalhos Glassdoor fragmentados;
- Unicode U+0096;
- CNPJs-base duplicados;
- coluna `Unnamed: 14` vazia;
- BOM UTF-8 e particularidades do PowerShell.

Decisões:
- Unicode tratado por função reutilizável em `text_utils.py`;
- CNPJ mantido como texto;
- deduplicação realizada na Trusted, não na RAW.

## Slide 7 — Camada Trusted
Modelos materializados:
- `trusted.reclamacoes`: 918 linhas;
- `trusted.enquadramento`: 1.459 linhas canônicas;
- `trusted.enquadramento_aliases`: 1.474 linhas;
- `trusted.glassdoor`: 39 linhas.

A deduplicação seleciona um registro canônico por CNPJ e preserva os nomes alternativos em aliases.

## Slide 8 — Camada Delivery via modelos dbt intermediários
Modelos `ephemeral`:
- `int_reclamacoes_normalizadas`;
- `int_glassdoor_normalizado`;
- `int_glassdoor_por_nome`;
- `int_glassdoor_por_cnpj`.

A Delivery consome os modelos via `ref()` e mantém 918 linhas.

## Slide 9 — Resultados quantitativos
- Delivery: 918 linhas.
- Diferença vs. Trusted de reclamações: 0.
- Com enquadramento: 321.
- Com Glassdoor: 136.
- Sem Glassdoor: 782.
- Cobertura Glassdoor nos conglomerados sem CNPJ: 24,95%.
- Vínculo por nome: 120.
- Vínculo por alias: 16.

## Slide 10 — Testes e reprodutibilidade
- 29 data tests.
- 34/34 no `dbt build`.
- 10 modelos.
- 10 sources.
- 479 macros reconhecidas no projeto/ambiente.
- 0 erros no último build bem-sucedido.

Testes incluem `not_null`, `accepted_values`, `unique` e testes singulares de cardinalidade, granularidade e coerência.

## Slide 11 — Parquet
- `reclamacoes.parquet`: 918 linhas no estado anterior validado.
- `glassdoor.parquet`: 39 linhas no estado anterior validado.
- `tabela_final.parquet`: 918 linhas no estado anterior validado.
- `enquadramento.parquet`: deve ser **reexportado após a deduplicação**, para refletir 1.459 linhas canônicas.

## Slide 12 — Aprimoramentos após avaliação
1. CNPJ duplicado: 1.474 registros de origem → 1.459 CNPJs canônicos.
2. Unicode U+0096: tratamento por função reutilizável em Python.
3. dbt nativo: decomposição em modelos `intermediate`, uso de `ref()`, `ephemeral` e macro.
4. Macro `normalizar_nome`: regra textual centralizada e reutilizável.

## Slide 13 — Entregáveis e GitHub
- Branch: `main`.
- Refatoração dbt: commit `548668c`.
- Atualização documental posterior: commit específico de documentação/evidências.
- Build: 34/34 PASS.
- Credenciais protegidas pelo `.gitignore`.

## Slide 14 — Conclusões
- 918 reclamações preservadas na Delivery.
- CNPJ canônico com aliases auditáveis.
- Unicode tratado na ingestão.
- DAG dbt com modelos intermediários e macro reutilizável.
- Controles automatizados de qualidade.

Resultado: pipeline funcional, auditável, reproduzível e mais aderente aos recursos nativos do dbt.

## Slide 15 — Referências técnicas
- Apache Parquet.
- dbt: build, data tests, Jinja/macros, materializations e `ref()`.
- Docker Compose.
- PostgreSQL.
