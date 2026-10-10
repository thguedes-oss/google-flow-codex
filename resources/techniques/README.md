# Receitas locais para Tesseract 0.3.1

O [catálogo](catalog.json) define IDs, fontes, parâmetros, limites e mecanismos. A implementação está em [flow_techniques.py](../../scripts/flow_techniques.py); o tratamento de cor usa [color.wgsl](color.wgsl). Os conceitos de BeatCut foram reescritos sem incorporar seu código. As orientações de OpenMontage e fal não adicionam seus runtimes ou serviços.

Cada ID corresponde a casos no [smoke nativo](../../reports/techniques-smoke.json), pelo campo `cases[].id`. `recipe_files` fixa hashes do compilador, catálogo e shader testados. O [gate offline](../../scripts/technique_coverage.py) exige essa correspondência e rejeita evidência desatualizada. A [prova de integração](../../reports/technique-pipeline-smoke.json) sela também o pipeline e verifica janela, recortes, ordem de camadas, alpha e áudio. Preparar uma revisão congela os mesmos recursos usados; alterar os bytes invalida a revisão.

| ID | Requisito específico | Mecanismo | Evidência nativa |
|---|---|---|---|
| `native.flash` | Nenhuma fonte; cor RGBA e janela na entrega | Retângulo frontal temporário | 1/2 frames em 24/30/60 fps e formatos portrait/square |
| `native.fade` | Uma fonte visual, pelo menos 2 frames | Keyframes de opacidade | Landscape/portrait/square |
| `native.transform` | Uma visual, pelo menos 2 frames | Posição, escala e rotação | Landscape/portrait/square |
| `native.reframe` | Uma visual | Cópia visual recortada na janela | Landscape/portrait/square |
| `native.overlay` | Uma visual; sobreposição deliberada | Cópia frontal sem áudio | Landscape/portrait/square |
| `native.collage` | Duas a quatro visuais; margem/gap que caibam | Grade de cópias sem áudio | Landscape/portrait/square |
| `native.text-reveal` | Um `text:N`, pelo menos 2 frames | Opacidade e deslocamento | Landscape/portrait/square |
| `native.shape-reveal` | Um `rectangle:N`, pelo menos 2 frames | Opacidade e deslocamento | Landscape/portrait/square |
| `native.color` | Uma visual | Brilho/contraste/saturação/vinheta em WGSL | Três formatos e alpha 127 preservado na integração |
| `native.audio-gain` | Um `audio:N`, pelo menos 2 frames | Envelope linear na camada original | RMS antes/durante/depois e restauração do ganho |

Os tempos existentes continuam em ms. Técnicas usam frames no FPS da entrega (24, 30 ou 60); não deslocam cortes, estendem fontes ou alteram áudio por inferência. Escala é relativa ao tamanho ajustado da fonte; posição é deslocamento relativo. O relógio do efeito é relativo à camada proprietária, separado do tempo selecionado da mídia. Substituições preservam os gráficos que já estavam acima; overlay/flash ocupam a frente deliberadamente.

Fontes devem cobrir toda a janela. Técnicas sobrepostas ou contíguas na mesma fonte, `fade_ms` concorrente e `native_actions` junto de `techniques` são rejeitados. Plano estático `kind: design` não usa este contrato em frames. Aprovações formais, status `completed` e hashes continuam obrigatórios. Veja [uso e exemplos](../../workflow/pos-producao.md#tecnicas-em-janelas-existentes).

Todos os 33 casos finais passaram com mídia sintética temporária. Isso comprova a implementação nas condições registradas, sem escuta humana, aprovação de montagem real ou cobertura de todas as combinações de parâmetros. [Limites e conveniências ainda incompletas](../../reports/incorporation-final.md#limites-e-itens-incompletos) distinguem orientação editorial de receita habilitada.
