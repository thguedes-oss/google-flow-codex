# Revisão independente da incorporação

Veredito final: **sem defeitos reproduzíveis abertos no escopo revisado**. Os dois P2 identificados foram corrigidos e rechecados. Revisão dos arquivos atuais, sem comparação Git porque o repositório não possui commit inicial. O manifesto `.work/incorporation-review/package.json` foi usado para delimitar arquivos, não como selo de produção. A execução final da integração está a cargo do responsável principal; este parecer não antecipa seu resultado.

## P2 corrigido — validade da evidência de integração

Local: `scripts/technique_coverage.py`, função `audit`, e registro de saída em `scripts/smoke_technique_pipeline.py`.

Antes da correção, o gate só exigia `status`, `decoded_audio_byte_identical` e `production_files_unchanged` no relatório de integração. Ignorava os hashes de `frozen_technique_files` e não associava a prova à versão do pipeline e do executor de smoke. Assim, a prova poderia continuar aceita depois de alterações na implementação.

A versão corrigida exige e compara hashes atuais de `implementation_files` (pipeline, compilador de receitas e executor da integração) e `frozen_technique_files` (compilador, catálogos nativo/GL e shaders color/fade). O executor registra as três implementações e reúne os arquivos congelados das revisões GL e `native.color`.

Rechecagem sem alterar arquivos e sem render: um relatório simulado em memória com todos os fingerprints atuais passou; mudar o hash do compilador para 64 zeros foi rejeitado com `Implementação mudou após integração de receitas/shaders`; remover `implementation_files` foi rejeitado com `Hashes obrigatórios ausentes`. Os dois testes de `tests/test_technique_coverage.py` também passaram no Python 3.12 (código 0). O controle positivo confirma que as rejeições não decorrem apenas de algum outro bloqueio.

## Defeito corrigido durante a revisão

A inserção de todo helper em `layers[0:0]` fazia `native.color` e `native.reframe` cobrirem legendas/elementos superiores. A versão atual insere substituições na posição da primeira fonte visual e exclui o mapa auxiliar GL desse cálculo; overlay e flash mantêm sua inserção frontal deliberada. A reprodução estática passou de `[helper, subtitle, footage]` para `[subtitle, helper, footage]`. A ordem foi confirmada contra o contrato nativo 0.3.1 (`layers[0]` é a frente). A integração agora compara um gráfico frontal com a versão sem efeito e falha se ele for coberto; sua execução final permanece com o responsável principal.

## Escopo e limites

- Leitura de AGENTS, README, operação, manifesto do exemplo, pipeline, receitas, tradutor, catálogos, integridade, marcadores de áudio, documentação de cobertura e evidências GL disponíveis.
- Conferência específica de tipos, coerções, swizzles e matrizes nos portes, inclusive InvertedPageCurl e hexagonalize; nenhuma divergência semântica concreta identificada nessa amostra.
- `source_integrity.py`, com Python 3.12, concluiu com código 0: sete fontes complementares e inventário de duplicatas íntegros.
- Nenhum smoke nativo foi repetido por este revisor; os testes simultâneos do responsável não foram classificados como defeito. Compilação/smoke não significam equivalência visual integral aos shaders originais nem aprovação de produção.
- Nenhuma geração, gasto Flow, instalação global, alteração de vendor ou aprovação de mídia foi efetuada pela revisão.
