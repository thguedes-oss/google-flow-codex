<a id="graficos-e-movimento-editavel"></a>

# Gráficos e movimento editável

Gráficos explicam, localizam, comparam ou nomeiam informação necessária. Planeje texto exato, origem, hierarquia, intervalo e região. Use Tesseract fixado e [pós-produção](../pos-producao.md), sem importar React/Remotion, código AGPL ou scripts upstream. Este guia não cria `.tsrct` nem render.

<a id="tipografia-e-legenda"></a>

## Tipografia e legenda

Família/pesos vêm de marca e público, com funções claras de título, corpo, rótulo e legenda. Fonte local exige arquivo, hash, licença e face correta, inclusive TTC. Não substitua silenciosamente. Confira glifos portugueses, símbolos, números e quebras no render.

Legibilidade depende de canvas, densidade, contraste, tempo e tela final. Teste no tamanho de exibição; safe zones históricas não garantem UI atual. Faixa/fundo pode melhorar contraste, sem cobrir ação, mãos/rosto. Título precisa de entrada, sustentação legível e saída; animação não consome todo o tempo.

Legenda é transcrição verificada com tempos e `transcript_evidence`. Quebre por sentido, confira linhas, leitura, sincronismo e conflitos com rótulos. Repetir fala é função legítima de acessibilidade: evite título redundante competindo, sem retirar legendas necessárias apenas por repetirem áudio.

<a id="diagramas-e-dados"></a>

## Diagramas e dados

Defina relação: sequência, fluxo, hierarquia, comparação, quantidade ou evolução. Escolha formas, conexões, unidades, rótulos e fontes dos dados. Barra compara magnitude; linha representa evolução; partes de um todo pedem denominador coerente. Eixo truncado/área podem distorcer impressão. Informe período/unidade/categoria; não invente valores. Sem primitiva suportada, planeje texto/retângulos ou recurso aprovado e declare limite.

Revele elementos quando a fala os nomeia. Destaque relevante mantendo contexto. Diagrama distingue hipótese de dado. Interface/terminal sintético não deve representar resultado inventado como captura real; identifique reconstrução quando a veracidade importar.

<a id="overlays-e-motion"></a>

## Overlays e motion

`native.overlay` compõe fonte sobre base; reserve área sem ocultar prova. `native.collage` compara/acumula fontes com hierarquia e espaçamento. Grade, pilha fotográfica e lado a lado têm funções distintas; cada material exige origem/aprovação. `native.text-reveal`/`native.shape-reveal` organizam entrada de texto/forma conforme catálogo e smoke. Escolha posição, escala, opacidade e curva pelo propósito e esquema real; linear pode servir velocidade constante, sem proibição estética universal.

Máquina de escrever, máscara, pop, entrada em palavras e deslocamento têm custo de leitura. Revele, sustente, retire. Rótulo fixo não rastreia objeto automaticamente. Blur, partículas, 3D, tracking, máscaras arbitrárias e shaders customizados não são capacidades inferidas de um ID. Falhe/mantenha pendente se esquema e smoke não confirmarem.

<a id="familias-de-transicoes-gl"></a>

## Familias de transicoes GL

O [catálogo individual GL](../../resources/gl-transitions/catalog.json) mapeia os 125 arquivos por ID `gl.NomeOriginal`, com proveniência, autoria, licença, parâmetros e estado conforme campos efetivamente registrados. Famílias ajudam a escolher função; não substituem inspeção individual.

| Família visual | Função possível | Revisão necessária |
|---|---|---|
| Mistura/fade e passagem por cor | passagem gradual/separação | exposição, pele, duração, endpoints |
| Wipe/cortina/varredura | transferência direcional de atenção | sentido, borda, proporção e texto |
| Formas/círculos/janelas/mosaicos | revelação parcial ou ligação gráfica | centro, cobertura, formato vertical/quadrado |
| Slide/porta/página/cubo | troca espacial estilizada | bordas vazias, escala e origem/destino |
| Zoom/rotação/espiral/perspectiva | ênfase ou ruptura forte | recorte, distorção e conforto |
| Ondas/água/ruído/displacement | passagem orgânica/subjetiva | artefatos e texturas auxiliares |
| Pixel/glitch/canais digitais | ruptura tecnológica deliberada | informação perdida e flicker |
| Blur/luma/mistura por conteúdo | ponte guiada pelas imagens | ordem, faixa tonal e inputs extras |

GLSL usa duas texturas e progresso 0→1: os extremos devem corresponder à origem e ao destino conforme a matemática original. `AdvancedMosaic` conserva pequena quantização UV e `tangentMotionBlur` conserva desfoque residual; sete shaders podem forçar opacidade. Consulte as [limitações por efeito](../../resources/gl-transitions/README.md) antes de usar transparência ou exigir extremos exatos. Parâmetros são constantes na janela salvo adaptação explícita validada. `gl.luma` e `gl.displacement` recebem terceira fonte para o mapa, com nome registrado em `texture_inputs`; imagem de mapa aprovada só fica ativa durante a janela. Texturas extras exigem declaração/provisão, nunca defaults inventados. Autoria/licença pertencem a cada shader, não a uma atribuição genérica.

Inventário não comprova compilação/render no Tesseract. Tradução GLSL, WGSL e API requerem verificação; catálogo operacional e smoke prevalecem. Compare início, intermediários e fim nos formatos usados. Efeito não altera áudio, prolonga fonte ou desloca corte automaticamente.

Técnicas: [graphic.type](../tecnicas.md#graphictype), [graphic.caption](../tecnicas.md#graphiccaption), [graphic.diagram](../tecnicas.md#graphicdiagram), [native.overlay](../tecnicas.md#nativeoverlay), [native.collage](../tecnicas.md#nativecollage), [native.text-reveal](../tecnicas.md#nativetext-reveal), [native.shape-reveal](../tecnicas.md#nativeshape-reveal), [gl.transition](../tecnicas.md#gltransition).

Fontes: OpenMontage `skills/creative/typography.md`, `data-visualization.md`, `diagram-gen-usage.md`, `remotion-composer/SCENE_TYPES.md`; BeatCut `README.md`; GL `README.md`, `skills/gl-transitions/references/video.md`, `transitions/*.glsl`. [Cobertura](../../reports/knowledge-coverage.md).
