# Incorporação das cinco fontes — registro de execução

Plano: pedido aprovado nesta conversa em 2026-10-10.

| Etapa | Produto | Verificação | Estado |
|---|---|---|---|
| Fontes | Clones fixados, 2459 arquivos e 437 grupos duplicados | Hashes, checkout e cobertura offline passaram | Concluída |
| Conhecimento | Oito guias, 32 fichas e dois templates | Matriz de conteúdos e destinos completos | Concluída |
| Infraestrutura | Contrato opcional techniques e congelamento de receitas | Rejeições, compatibilidade e prova end-to-end passaram | Concluída |
| Recursos | Dez receitas habilitadas e 125 portes GL | 33 casos nativos; 375 GL, 1875 frames | Concluída com limites explícitos |
| Integração | Documentação, checks e relatório de cobertura | Python 3.12: 140 testes locais e 70 upstream passaram | Concluída |

O checkout atual foi preservado: está na branch codex/claudia-wiki e ainda não possui commit inicial. Nenhum arquivo anterior foi movido ou incluído num commit por efeito deste trabalho. A ausência de um commit base impede uma comparação por intervalo Git; a revisão usará os arquivos e os testes da incorporação.

Interfaces verificadas antes da implementação: inventários são sidecars em config/source-inventories; guias em workflow/conhecimento; GL tem catálogo próprio e WGSL estático; receitas locais têm catálogo em resources/techniques; o pipeline consome ambos e congela seus hashes. Tempos visuais novos são frames, tempos preexistentes permanecem em ms. Fontes, documentos e recursos têm responsáveis separados durante a execução.

Fluxo de produção permanece: Chrome, orçamento Flow zero, nenhuma aprovação inferida, mídia sintética somente em diretórios temporários.

## Encerramento verificado

Execução completa `scripts/check.ps1`, Python 3.12.13: `20261010T112801445562Z-28e7a5e7`, código 0. `planning_passed=true`, `generation_ready=false` por pendências reais do exemplo e orçamento zero. Gate offline de cobertura passou com os hashes atuais. Os perfis 720p/1080p/4K foram reconferidos no motor portátil; falha preexistente do conversor Premiere com gráficos híbridos permanece explícita, sem entrega parcial.

Durante a prova, o relógio do efeito foi separado do recorte da mídia e medido em relação à janela da camada proprietária. Helpers preservam relógios/recortes, escondem somente a imagem original durante substituições e têm áudio zero. Transparência 127 permaneceu 127. A revisão independente identificou dois P2 corrigidos: substituições cobrindo legendas e evidência de integração sem vínculo completo aos hashes da implementação. Os testes de regressão passaram e a integração final foi renderizada novamente após as correções; áudio decodificado ficou idêntico e frames externos ficaram iguais ao baseline.

O [relatório final](incorporation-final.md) separa cobertura documental, recursos habilitados, evidências e conveniências ainda incompletas. Não declara melhoria de qualidade ou aprovação de produção a partir de fixtures.
