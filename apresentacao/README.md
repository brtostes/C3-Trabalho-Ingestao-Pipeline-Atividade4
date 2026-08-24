# Apresentação da Atividade 4

Esta pasta contém a apresentação da Atividade 4 e o roteiro atualizado após as revisões realizadas na avaliação.

## Arquivos

- `Apresentacao_Tarefa4_Engenharia_Dados.pptx`: versão binária válida anteriormente publicada no repositório.
- `Apresentacao_Tarefa4_Engenharia_Dados_atualizada.md`: conteúdo integral revisado, incorporando as alterações de CNPJ, Unicode e refatoração dbt.

## Estado técnico atualizado

- `trusted.reclamacoes`: 918 linhas;
- `trusted.enquadramento`: 1.459 linhas canônicas;
- `trusted.enquadramento_aliases`: 1.474 linhas;
- `trusted.glassdoor`: 39 linhas;
- `delivery.tabela_final`: 918 linhas;
- 10 modelos dbt;
- 29 data tests;
- 479 macros reconhecidas;
- último build bem-sucedido: 34 PASS, 0 ERROR.

## Melhorias incorporadas no roteiro revisado

- tratamento determinístico de CNPJs duplicados;
- preservação de aliases;
- tratamento do Unicode U+0096 por função Python reutilizável;
- modelos `intermediate` com materialização `ephemeral`;
- dependências por `ref()`;
- macro `normalizar_nome`.

## Observação sobre Parquet

`data/trusted/enquadramento.parquet` deve ser reexportado após a deduplicação para refletir as 1.459 linhas canônicas do modelo atual.
