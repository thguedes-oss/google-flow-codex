# Direção contextual — registro de implementação

Plano: “Direção contextual como padrão do FLOW”, aprovado nesta conversa em 10 de outubro de 2026.

| Etapa | Produto | Estado |
|---|---|---|
| Política e procedimento | Padrão no AGENTS, direção contextual e template editorial | Implementado e revisado |
| Integração | Entrada, direção, continuidade, geração, montagem e revisão conectadas | Implementada |
| Exercícios | Cinco briefs, dez planos de revisão e nove cenários de contrato/diagnóstico | Exercitados sem mídia |
| Verificação | Links, integridade protegida, check Python 3.12 e revisão final | Concluída; relatórios vinculados abaixo |

Execução inline conforme a skill executing-plans; verificação antes da conclusão. O plano aprovado na conversa é a especificação desta mudança. Antes de editar, foram preservados snapshots de 32 documentos e hashes de 324 arquivos de scripts, testes, catálogos/shaders, config, projetos, biblioteca e lock em `.work/contextual-direction/`. As evidências técnicas da incorporação anterior serão reutilizadas apenas se seus bytes permanecerem atuais.

Ruling: manter o checkout atual, que está em `codex/claudia-wiki` sem commit inicial — criar worktree/commits agora perderia ou incorporaria indevidamente a base preexistente não versionada; snapshots locais delimitam a mudança. Não haverá merge, push ou commit por efeito deste pedido.

Ruling: implementar orientação do agente e documentos, preservando todos os contratos JSON e executáveis — a escolha contextual pertence ao Codex e o plano exige os mecanismos existentes. Não serão criados testes que apenas procurem frases nos documentos; exercícios editoriais e validações reais do pipeline distinguirão organização de qualidade criativa.

Interfaces conferidas: editorial → `direction`/momentos e manifesto → prompts/preflight/congelamento; editorial → fontes e `techniques` da pós-produção → revisão. O editorial não é manifesto executável nem selo de aprovação. Orçamento permanece zero; nenhuma mídia de produção está autorizada por esta implementação.

Os exercícios de aviso, tutorial, depoimento fictício, publicidade e narrativa estão em [contextual-direction-exercises.json](contextual-direction-exercises.json), incluindo briefs, escolhas e motivos completos. Os planos editoriais e dez JSONs de revisão foram escritos apenas em diretório temporário, com caminhos/hashes registrados; `load_review_plan` validou a transposição dos quatro campos de direção e momentos. Todos mantêm observação/aprovação pendentes. A saída demonstra decisões redigidas pelo Codex e validade estrutural, não uma avaliação automática de qualidade artística.

Foram exercitados os validadores existentes para técnica indisponível, janela de fonte insuficiente, efeitos sobrepostos, fonte de técnica ausente, parâmetro desconhecido e mídia ausente; todos rejeitaram como esperado. Um controle positivo de janela válida e um plano legado passaram. O preflight do exemplo preservou bloqueio explícito de orçamento zero, além das demais pendências reais. Um diagnóstico manual hipotético de resultado divergente preservou o plano esperado; não houve mídia observada, detector semântico ou fechamento formal simulado.

## Verificação e revisão final

`scripts/check.ps1` terminou com código zero usando Python 3.12.13 na execução `20261010T125144214299Z-391afebd`: os 15 checks passaram, incluindo 140 testes locais e 70 testes upstream. O [relatório completo desta execução](runs/20261010T125144214299Z-391afebd/verification.json) mantém planejamento válido e geração não pronta, com orçamento zero e pendências reais do exemplo. Compatibilidade dos planos e exigências de aprovação formal continuam cobertas pelos testes existentes.

A [verificação documental e de integridade](contextual-direction-verification.json) registra os documentos alterados, seus hashes, os links locais conferidos e a comparação dos 324 arquivos protegidos com o snapshot anterior. Scripts, testes, catálogos, receitas, shaders, configurações, projetos, biblioteca e lock permaneceram idênticos. Por isso foram reutilizadas as evidências nativas atuais: 125 transições GL e dez técnicas nativas habilitadas, com os 375 casos GL já renderizados. Não foram repetidos renders técnicos nem alterados perfis, áudio, manifesto, créditos ou aprovações.

A revisão independente final leu o plano, o diff, este registro e os exercícios. Encontrou um ajuste P3 na transposição dos momentos do tutorial: eventos distintos em 8 e 12 segundos da montagem haviam sido agrupados na expectativa do primeiro momento do segundo clipe. A conferência específica falhou antes da correção; após separar os eventos, os tempos locais são 0 e 4 segundos, respectivamente. Os dez planos foram novamente validados, com hashes íntegros e correspondência individual dos 20 momentos. O guia e o modelo agora pedem origem temporal explícita e conversão considerando o recorte da fonte. Não restou achado reproduzível desta revisão sem tratamento.

Na conferência final também foi esclarecida a separação de autorizações: orçamento Flow zero bloqueia geração no Flow, mas não cancela um pedido próprio já autorizado de imagens pelo Codex ou montagem local autorizada com materiais aprovados. A adoção desta política, sozinha, não autoriza piloto, geração ou aprovação de mídia.

A revisão não avaliou qualidade artística, eficácia contra alucinações ou comportamento em mídia real; esses resultados continuam sem comprovação, conforme o aceite. A interpretação semântica pertence ao Codex por decisão explícita do plano, sem novo motor nos executáveis. Tempos e materiais fictícios permanecem provisórios e sem aprovação. As verificações técnicas completas são as registradas nesta execução; a reutilização das provas nativas depende da integridade conferida, e as restrições operacionais anteriores foram preservadas.

Entrega documental concluída: um pedido comum orienta o planejamento inteiro, com escolhas atribuídas, justificativas por cena e transposição para os mecanismos existentes. Os exercícios foram mantidos fora da biblioteca de produção. Esta implementação não iniciou produção, gerou mídia de produção, consumiu créditos, aprovou materiais nem criou commit, merge ou push.
