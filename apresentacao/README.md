# Apresentação da Atividade 4

A apresentação final está armazenada nesta pasta como:

`Apresentacao_Tarefa4_Engenharia_Dados.pptx`

A versão revisada incorpora as melhorias realizadas após a avaliação da atividade:

- tratamento determinístico dos CNPJs duplicados na camada Trusted;
- preservação dos nomes alternativos em `enquadramento_aliases`;
- tratamento do Unicode U+0096 por função Python reutilizável;
- refatoração da transformação para modelos `intermediate` com materialização `ephemeral`;
- uso explícito de `ref()` na DAG do dbt;
- macro `normalizar_nome` para centralizar a padronização textual;
- atualização dos indicadores para 1.459 CNPJs canônicos, 10 modelos dbt, 29 testes e build com 34 PASS.

## Observação sobre Parquet

Os arquivos Parquet atualmente versionados foram gerados antes da revisão final da deduplicação de CNPJ. A apresentação registra que `enquadramento.parquet` deve ser reexportado após a revisão, de modo a refletir as 1.459 linhas canônicas do modelo atual.
