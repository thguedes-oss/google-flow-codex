<a id="tecnicas-escolher-por-finalidade-executar-somente-com-suporte-verificado"></a>

# Técnicas: escolher por finalidade, executar somente com suporte verificado

IDs abaixo são estáveis para documentação. Apenas IDs presentes no [catálogo runtime](../resources/techniques/catalog.json) ou [catálogo GL](../resources/gl-transitions/catalog.json) são candidatos a `techniques`; os demais são referências de planejamento, não comandos. A presença no catálogo não substitui estado operacional e smoke. Use [ficha completa](../templates/technique-fiche.md) quando uma produção precisar registrar parâmetros e decisões.

Cada ficha resumida traz finalidade/situação, limite/requisito, exemplo/execução e revisão. Todos os exemplos são intenção textual, sem mídia ou aprovação. Flow usa Chrome autorizado e preflight; Tesseract usa portátil 0.3.1, telemetria false, fontes aprovadas e revisão separada. Uma técnica visual não estende fonte, desloca corte ou altera áudio automaticamente.

<a id="contrato-de-aplicacao-nativa"></a>

## Contrato de aplicação nativa

O plano aceita `techniques` opcional como lista de objetos com `id`, `sources`, `start_frame`, `duration_frames` e `params`. Omitir a lista mantém o plano anterior. `clip:0` e `image:0` identificam entradas existentes; `text:0`/`rectangle:0` identificam texto/forma existentes, sem importar ativos. Índices dependem do plano real. Frames são do FPS da entrega, não milissegundos de origem.

Exemplo apenas estrutural: `{"id":"native.flash","sources":[],"start_frame":12,"duration_frames":2,"params":{"color":[1,1,1,1]}}`. A janela precisa caber na entrega e servir à direção. Não copiar o exemplo para produzir flash sem decisão. Parâmetros nativos consultados: fade usa `from_opacity`/`to_opacity` (0–100); transform usa posições, escalas em porcentagem e rotação; reframe usa `position`/`scale`; overlay usa `position`/`scale`/`opacity`; collage usa `gap`/`margin`; reveals usam `offset`; color usa `brightness`/`contrast`/`saturation`/`vignette`. O arquivo do catálogo prevalece se mudar. Esses nomes não declaram sucesso operacional: confira os testes da versão.

Fontes devem cobrir a janela inteira, sem extensão automática. Flash não recebe fontes; fade/transform/reframe/overlay/color recebem uma visual; collage recebe duas a quatro; text-reveal recebe um texto e shape-reveal um retângulo. `native.audio-gain` recebe `audio:N`. GL recebe duas fontes visuais; `gl.luma`/`gl.displacement` recebem uma terceira como mapa, seguindo `texture_inputs` no catálogo. Imagem de mapa precisa de origem/aprovação e só fica ativa na janela do efeito. Não transformar ID documental em runtime por semelhança de nome.

`scale` de transform/reframe/overlay é multiplicador relativo à camada já ajustada ao canvas: 100 mantém seu tamanho planejado. `position` é deslocamento relativo à posição planejada. Não são tamanho absoluto do recurso nem coordenadas absolutas de recorte. O validador rejeita `native_actions` e `techniques` simultâneos, `fade_ms` na fonte que recebe técnica e técnicas sobrepostas na mesma fonte. Separe revisões para resolver conflitos deliberadamente. `kind: design` não aceita técnicas em frames; vídeo exige FPS 24, 30 ou 60. Animações GL/fade/transform/reveals/audio-gain precisam de pelo menos dois frames distintos.

A revisão congela receita, catálogos e shaders usados com seus hashes. Alterar implementação exige nova preparação; não apresentar render antigo como saída da versão nova. Relatórios de smoke determinam o suporte efetivamente exercitado por efeito e formato, sem extrapolar uma prova landscape para portrait/square.

<a id="nativeaudio-gain"></a>

## native.audio-gain

**Finalidade/situação:** controlar entrada/saída ou nível de áudio já aprovado sem duplicar a camada. **Limites/requisitos:** uma fonte `audio:N` existente, janela coberta com pelo menos dois frames, ganhos finais lineares `from_gain`/`to_gain` de 0 a 4; não são multiplicadores adicionais do ganho anterior. **Exemplo/execução:** `{"id":"native.audio-gain","sources":["audio:0"],"start_frame":24,"duration_frames":12,"params":{"from_gain":0,"to_gain":1}}` a 24 fps faz rampa na janela temporal existente; o ganho originalmente planejado volta fora dela. Não muda origem, posição, palavras ou duração da faixa. **Revisão:** escuta antes/durante/depois, ganho/picos, ausência de áudio duplicado, clicks e restauração do nível externo. Origem conceitual: OpenMontage sound-design; implementação nativa local.

<a id="planbrief"></a>

## plan.brief

**Finalidade/situação:** fixar público, mensagem, destino e evidência antes de criar planos. **Limites/requisitos:** depende de dados reais; não inventa testemunho, número ou autorização. **Exemplo/execução:** aviso para moradores explica uma ação e termina com data fornecida; preencher [brief](../templates/creative-brief.md) e decidir o que fica fora. **Revisão:** mensagem compreensível, alegações rastreáveis, duração/idioma e pendências explícitos. Origem: fal marketing/campaign-patterns, UGC/formats; OpenMontage brief schema.

<a id="plansequence"></a>

## plan.sequence

**Finalidade/situação:** distribuir abertura, contexto, prova e resultado por planos. **Limites/requisitos:** forma é adaptável, não fórmula de retenção garantida; fala precisa ser lida. **Exemplo/execução:** geral situa café, médio mostra pega, detalhe confirma contato, fecho resolve; registrar função em `direction`. **Revisão:** causalidade clara, soma de tempos, ação legível e fecho útil. Origem: fal storytelling/shot-planning; OpenMontage storytelling.

<a id="planbroll"></a>

## plan.broll

**Finalidade/situação:** inserir detalhe/contexto/prova ligado ao roteiro. **Limites/requisitos:** origem/direitos, ponto de vista e duração reais; reconstrução não é registro. **Exemplo/execução:** mostrar alça durante explicação da pega; listar material necessário, usar aprovado ou deixar pendente; geração depende do fluxo autorizado. **Revisão:** inserção demonstra o que afirma e não contradiz espaço/tempo. Origem: OpenMontage broll-planning.

<a id="identitysheet"></a>

## identity.sheet

**Finalidade/situação:** estabilizar identidade antes de múltiplos enquadramentos. **Limites/requisitos:** canônico aprovado/hash; vistas adicionais só necessárias e autorizadas; prancha pode variar identidade. **Exemplo/execução:** derivar perfil de Lia da origem com cabelo/roupa preservados, pelo image_gen após inspeção local, apresentando candidato. **Revisão:** rosto, idade, assimetria, silhueta e roupa painel a painel; não enviar sheet inteira como primeiro frame. Origem: Square-Zero character-sheets; fal anchor-system.

<a id="identityhandoff"></a>

## identity.handoff

**Finalidade/situação:** preservar estado entre corte/continuação. **Limites/requisitos:** estados explícitos e último frame real aprovado para continuação compatível. **Exemplo/execução:** caneca continua apoiada na mão direita; registrar handoff e selecionar frame no Chrome. **Revisão:** comparação de frames e emenda reproduzida, mão, orientação, velocidade, luz e som. Origem: fal shot-planning; Square-Zero Veo endpoints.

<a id="shotcamera"></a>

## shot.camera

**Finalidade/situação:** conduzir atenção/espaço por enquadramento e movimento motivado. **Limites/requisitos:** distinguir pan/truck e dolly/zoom; um movimento principal, sem suporte físico garantido. **Exemplo/execução:** dolly lento aproxima a mão sem ocultar alça; escrever início/direção/fim no prompt Flow. **Revisão:** ação visível, geometria, trajetória e composição final. Origem: fal shot-language; OpenMontage video-gen-prompting.

<a id="shotfocus"></a>

## shot.focus

**Finalidade/situação:** selecionar ou transferir atenção. **Limites/requisitos:** foco raso pode apagar prova; definir plano focal inicial/final. **Exemplo/execução:** caneca nítida, depois rosto nítido com câmera sem deslocamento; prompt e direção. **Revisão:** foco transfere no momento útil sem apagar contato necessário ou contradizer câmera fixa. Origem: fal lighting-lens-color; OpenMontage video-gen-prompting.

<a id="shotlight"></a>

## shot.light

**Finalidade/situação:** dar leitura, volume e aparência consistente a sujeito/material. **Limites/requisitos:** fonte/direção/dureza coerentes; referência aprovada não é recolorida silenciosamente. **Exemplo/execução:** janela difusa esquerda separa rosto e destaca cerâmica; prompt com sombras plausíveis. **Revisão:** pele/produto, direção, exposição e continuidade entre planos. Origem: fal lighting-lens-color e commercial/prompt-patterns.

<a id="shotperformance"></a>

## shot.performance

**Finalidade/situação:** tornar ação/reação observável. **Limites/requisitos:** não inventar gesto dramático; poucas ações e trajeto/contato definidos. **Exemplo/execução:** Lia olha a caneca e fecha dedos na alça sem erguer; beats Flow autossuficientes. **Revisão:** começo/resultado, anatomia, mão, expressão, duração e fala. Origem: OpenMontage storytelling e video-gen-prompting; fal storytelling.

<a id="promptobservable"></a>

## prompt.observable

**Finalidade/situação:** escrever clipe autossuficiente e avaliável. **Limites/requisitos:** capacidades reais e referências vinculadas; estrutura local prevalece sobre formatação de outras engines. **Exemplo/execução:** sujeito/ação/contexto/câmera/luz/áudio completos, beats coverage, tentativa congelada antes do Chrome. **Revisão:** texto não contradiz slots, estado ou brief; resultado avaliado além do lint. Origem: Square-Zero Veo prompting; fal storytelling workflows; OpenMontage Veo prompting.

<a id="promptaudio"></a>

## prompt.audio

**Finalidade/situação:** dirigir fala, som de ação e ambiente. **Limites/requisitos:** áudio suportado no modo e idioma/texto reais; não garante boca sincronizada. **Exemplo/execução:** ambiente de café baixo, toque de cerâmica no contato e ausência de diálogo; declarar no prompt. **Revisão:** escuta integral, causa/instante, palavras/idioma e sincronismo quando houver fala. Origem: Square-Zero Veo prompting; OpenMontage sound-design.

<a id="editcut"></a>

## edit.cut

**Finalidade/situação:** selecionar trecho/relação narrativa sem efeito obrigatório. **Limites/requisitos:** fontes formalmente aprovadas, duração existente e palavras inteiras. **Exemplo/execução:** cortar no fechamento dos dedos para detalhe correspondente; `clips` no plano Tesseract em ms. **Revisão:** gesto não duplica, significado preservado, geografia e emenda sonora. Origem: OpenMontage video-editing/cinematic.

<a id="editjl"></a>

## edit.jl

**Finalidade/situação:** antecipar ou prolongar som entre imagens. **Limites/requisitos:** intervalos de áudio independentes, fontes aprovadas, nenhum áudio duplicado; confirmar esquema nativo. **Exemplo/execução:** som do café seguinte começa antes de sua imagem, por decisão explícita na montagem. **Revisão:** escuta, limites de palavras, origem sonora plausível e sincronismo; não inferir implementação só por documentação. Origem: OpenMontage video-editing.

<a id="editrhythm"></a>

## edit.rhythm

**Finalidade/situação:** ajustar tempo à percepção/energia. **Limites/requisitos:** não impor corte a cada beat, manter fala/leitura; marcadores não alteram corte. **Exemplo/execução:** sustentar prova e acelerar apenas passagem; escolher janelas existentes em nova revisão. **Revisão:** compreensão, reação, leitura e sensação de duração na reprodução. Origem: OpenMontage cinematic; BeatCut sync-mode-design (conceito em redação própria).

<a id="audiomarkers"></a>

## audio.markers

**Finalidade/situação:** anotar eventos ou extrair candidatos de energia para sugestões editoriais. **Limites/requisitos:** fonte/hash e evento conferido por escuta; energia RMS não comprova beat, melodia ou percussão. **Exemplo/execução:** `scripts/audio_markers.py` analisa recurso aprovado usado uma única vez no plano e grava JSON novo, sem alterar áudio/timeline; [procedimento](conhecimento/audio.md#extracao-local-de-candidatos). **Revisão:** confirmar evento/tempo por escuta, preservar fala e registrar decisão editorial; `confirmed: false` não vira aprovação automaticamente. Origem conceitual: BeatCut sync-mode-design; implementação independente sem código da fonte.

<a id="audiomix"></a>

## audio.mix

**Finalidade/situação:** priorizar fala com ambiente/música coerentes. **Limites/requisitos:** recursos aprovados e ganho linear distinto de dB/LUFS; efeitos só confirmados por esquema/teste. **Exemplo/execução:** diminuir trilha durante instrução, preservar ambiente útil; áudio Tesseract em revisão independente. **Revisão:** escuta integral, inteligibilidade, clipping, clicks, cauda e medidas reais. Origem: OpenMontage sound-design.

<a id="graphictype"></a>

## graphic.type

**Finalidade/situação:** criar hierarquia e mensagem legível. **Limites/requisitos:** fonte local/licença/hash, glifos portugueses, texto real, margens de UI conferidas. **Exemplo/execução:** título curto em região livre, sustentado após entrada; `texts` Tesseract. **Revisão:** glifos, contraste, tamanho de exibição e leitura completa. Origem: OpenMontage typography.

<a id="graphiccaption"></a>

## graphic.caption

**Finalidade/situação:** tornar fala/sons acessíveis por texto sincronizado. **Limites/requisitos:** palavras/tempos reais e `transcript_evidence`; roteiro não é transcrição. **Exemplo/execução:** duas unidades de sentido conferidas no áudio; `texts` com `role: caption`. **Revisão:** sincronismo, nomes/acentos, quebras, emissor e espaço sem obstruir ação. Origem: OpenMontage subtitle-sync/typography.

<a id="graphicdiagram"></a>

## graphic.diagram

**Finalidade/situação:** explicar relação, fluxo, comparação ou dados. **Limites/requisitos:** dados/fontes/unidades reais e primitivas suportadas; não promete biblioteca de charts. **Exemplo/execução:** dois estados ligados por seta conceitual ou comparação textual, usando formas/textos nativos disponíveis. **Revisão:** relação correta, escala não enganosa, hierarquia e entrada alinhada à explicação. Origem: OpenMontage data-visualization, diagram-gen-usage e SCENE_TYPES.

<a id="nativeflash"></a>

## native.flash

**Finalidade/situação:** acento visual breve em evento deliberado. **Limites/requisitos:** janela existente, cor/parâmetros no catálogo, suporte testado; evitar pulsação repetida/desconfortável. **Exemplo/execução:** clarão discreto numa passagem, ID runtime `native.flash` sem fontes quando o contrato confirmar. **Revisão:** intensidade, duração, legibilidade, frames adjacentes e conforto. Origem conceitual: BeatCut README; implementação local própria.

<a id="nativefade"></a>

## native.fade

**Finalidade/situação:** entrada/saída gradual de uma fonte. **Limites/requisitos:** uma fonte visual e janela coberta; não confundir com crossfade automático entre clipes. **Exemplo/execução:** suavizar aparecimento de imagem aprovada, parâmetros só do catálogo. **Revisão:** origem/destino de opacidade e informação legível. Origem: BeatCut README; OpenMontage typography.

<a id="nativetransform"></a>

## native.transform

**Finalidade/situação:** movimentar/escalar/rotacionar visual por função. **Limites/requisitos:** uma fonte, esquema verificado, sem câmera física simulada como garantia. **Exemplo/execução:** aproximação gráfica discreta sobre imagem aprovada dentro da janela. **Revisão:** recorte, bordas, suavidade e resolução útil. Origem: BeatCut zoom; OpenMontage SCENE_TYPES (conceitos).

<a id="nativereframe"></a>

## native.reframe

**Finalidade/situação:** reposicionar recorte para manter informação importante. **Limites/requisitos:** uma fonte, resolução e espaço existentes; não é detecção/rastreamento automático de rosto. **Exemplo/execução:** manter rosto e mão no formato vertical por recorte explicitamente escolhido. **Revisão:** frame a frame, cabeça/mãos, texto e contexto sem expansão inventada. Origem: BeatCut README (reenquadramento conceitual).

<a id="nativeoverlay"></a>

## native.overlay

**Finalidade/situação:** adicionar fonte visual informativa sobre a base. **Limites/requisitos:** uma fonte declarada por efeito, aprovação/hash, posição/tamanho conforme catálogo. **Exemplo/execução:** detalhe aprovado em região livre do quadro. **Revisão:** hierarquia, margens, opacidade, duração e ação sem obstrução. Origem: OpenMontage SCENE_TYPES.

<a id="nativecollage"></a>

## native.collage

**Finalidade/situação:** comparar ou acumular duas a quatro fontes. **Limites/requisitos:** cada fonte aprovada, layout/tempo cobertos, sem importar código de pilha BeatCut. **Exemplo/execução:** comparação lado a lado ou grade própria em Tesseract. **Revisão:** tamanho útil, ordem, margens, pontos de atenção e ausência de sobrecarga. Origem: BeatCut README; OpenMontage comparison card.

<a id="nativetext-reveal"></a>

## native.text-reveal

**Finalidade/situação:** apresentar texto editável na ordem de compreensão. **Limites/requisitos:** fonte `text:N` existente, glifos/licença e parâmetro confirmado; não presume máscara ou palavra a palavra. **Exemplo/execução:** título entra, sustenta e sai dentro da duração declarada. **Revisão:** início/meio/fim, tempo estável de leitura e texto exato. Origem: OpenMontage typography.

<a id="nativeshape-reveal"></a>

## native.shape-reveal

**Finalidade/situação:** revelar destaque/forma explicativa. **Limites/requisitos:** `rectangle:N` existente, esquema real, sem presumir vetores arbitrários. **Exemplo/execução:** faixa de destaque entra antes do rótulo. **Revisão:** alinhamento, timing, cobertura e propósito. Origem: OpenMontage diagram-gen-usage/SCENE_TYPES.

<a id="nativecolor"></a>

## native.color

**Finalidade/situação:** tratamento visual controlado e coerente. **Limites/requisitos:** uma fonte, parâmetros/suporte reais; não promete LUT/HDR ou perfil upstream. **Exemplo/execução:** leve ajuste aprovado que mantém pele e produto, em nova revisão Tesseract. **Revisão:** comparação original/derivado, clipping, tonalidade, continuidade e fidelidade de marca. Origem: OpenMontage core/color-grading; BeatCut filtros (conceitos).

<a id="gltransition"></a>

## gl.transition

**Finalidade/situação:** escolher passagem específica pelo [catálogo GL individual](../resources/gl-transitions/catalog.json), usando ID `gl.NomeOriginal`, nunca este ID documental. **Limites/requisitos:** duas fontes cobertas e terceira para mapa em luma/displacement conforme catálogo; parâmetros/texturas declarados, autoria/licença por arquivo e estado/smoke reais. Mapa aprovado só fica ativo na janela. GLSL não prova WGSL/Tesseract. **Exemplo/execução:** uma varredura direcional liga duas fontes aprovadas somente quando a entrada correspondente estiver operacionalmente confirmada. **Revisão:** em progresso 0 só origem; em 1 só destino; intermediários, proporção, alfa, bordas, legibilidade e flicker. Origem: GL README/transitions; [famílias](conhecimento/graficos.md#familias-de-transicoes-gl).

<a id="reviewcompare"></a>

## review.compare

**Finalidade/situação:** comparar resultado real a brief/referências/estados/direção. **Limites/requisitos:** mídia real/hash, reprodução/escuta; amostras não bastam. **Exemplo/execução:** conferir mão/alça no contato e emenda, registrar timestamp e observação em revisão existente. **Revisão:** decisão humana vigente sem aprovação por preenchimento. Origem: OpenMontage reviewer; fal quality bar.

<a id="reviewdiagnose"></a>

## review.diagnose

**Finalidade/situação:** corrigir uma causa e preservar aprendizado entre tentativas. **Limites/requisitos:** hipótese distinta de fato e comparação equivalente; sem declarar ganho sem evidência. **Exemplo/execução:** corrigir vínculo de referência antes de mudar atuação, preservando tentativa congelada anterior. **Revisão:** mudança rastreável, critério comparável e defeito resolvido observado. Origem: OpenMontage reviewer/video-gen-prompting.

Proveniência completa, commits, caminhos e exclusões: [cobertura documental](../reports/knowledge-coverage.md). Guias de [pré-produção](conhecimento/pre-producao.md), [direção](conhecimento/direcao.md), [geração](conhecimento/geracao-flow.md), [continuidade](conhecimento/continuidade.md), [montagem](conhecimento/montagem.md), [áudio](conhecimento/audio.md), [gráficos](conhecimento/graficos.md) e [revisão](conhecimento/revisao.md) consolidam aplicação sem acionar serviços upstream.
