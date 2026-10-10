# Verificação da configuração

Execução em 6 de outubro de 2026, Windows, Python 3.12.13 instalado via uv. Consulte `verification.json` para o resultado final, os logs dos comandos e os bloqueios do exemplo.

## Revisão antes de executar

Foram lidos os scripts de verificação, validação, geração de prompts e testes, além de `package_utils.py`, instalador, atualizador, checagem de atualizações e utilitários de release chamados pela suíte. As funções de rede do atualizador foram examinadas; os testes usam comparação offline e arquivos de release locais. Nenhum instalador global ou atualizador de rede foi executado.

A suíte compila os scripts, exercita validadores e prepara instalações/arquivos de release em diretórios temporários. Os subagentes opcionais do instalador não são usados. Esta é uma revisão para decidir a execução desses comandos, não uma auditoria de segurança exaustiva ou garantia de ausência de vulnerabilidades.

## Ajustes de ambiente

- O clone inicial herdou `core.autocrlf=true`. Os arquivos foram restaurados em LF, a configuração foi fixada apenas no clone e o índice foi atualizado sem diferenças em relação ao commit. O manifesto original passou sem ser regenerado.
- O launcher `py -3.12` não localizou o Python Astral. `scripts/check.ps1` encontra o executável instalado diretamente e confirma a série 3.12 antes de executar.
- Na primeira execução direta, 68 testes passaram e dois testes de sintaxe shell chamaram o Bash/WSL do System32. `scripts/upstream_tests.py` resolve exclusivamente essas chamadas para o Git Bash existente. O teste continua sendo `bash -n` sobre cada script original; nenhum teste foi removido ou substituído por um resultado fixo. [Saída da suíte](upstream-tests.txt).

## Interpretação

Os testes locais exercitam orçamento zero, orçamento insuficiente, envio desconhecido, deriva do estado entre cenas, caminhos fora do projeto, alteração de referências e invalidação da conferência após mudança de prompt. Evidências sintéticas usadas nos testes existem somente em pastas temporárias e não foram colocadas no projeto como aprovações.

A compatibilidade atual é checada fora da tabela histórica do upstream. O linter continua verificando estrutura, handles e intervalos. Os prompts de storyboard gerados foram comparados com a saída do gerador original. São arquivos de texto, sem geração de mídia.

O resultado esperado é planejamento aprovado e geração pendente, devido a referências não aprovadas/anexadas, custo e preflight específicos ausentes e orçamento zero. Não há clipes para inspeção visual ou prova de melhora na fidelidade.
