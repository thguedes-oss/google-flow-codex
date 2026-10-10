<a id="cobertura-documental-das-cinco-fontes"></a>

# Cobertura documental das cinco fontes

Data da adaptação: 10 de outubro de 2026. Este relatório descreve **conhecimento adaptado em português**, não geração, instalação, execução upstream, smoke de efeito ou aprovação de mídia. Nenhum crédito Flow foi gasto por esta adaptação; ela não cria piloto, imagem, `.tsrct` ou render de produção. Os guias consolidam técnicas aplicáveis ao fluxo Codex → Chrome/Flow → Tesseract portátil. Catálogos e testes operacionais são evidências distintas.

<a id="proveniencia-e-direitos"></a>

## Proveniência e direitos

| Fonte | Commit consultado | Caminho local | Uso e direitos |
|---|---|---|---|
| Square-Zero-Labs/video-prompting-skill | `8d72999ebe8bde390a658d3f6f8a79558b73bd5c` | `vendor/video-prompting-skill` | Apache-2.0; síntese de identidade, linguagem visual e Veo, preservando licença upstream |
| fal-ai-community/skills | `9ca850412943251fc9a466c4c29fdaf7a303a3d8` | `vendor/fal-ai-skills` | README declara MIT; preservar registro de licença efetivamente disponível, sem fabricar arquivo LICENSE |
| OpenMontage | `9327439db69021ab4b0e2776729bf3b58fdb5a87` | `vendor/openmontage` | AGPL; consulta e síntese editorial própria, sem importar código, runtime ou componentes |
| BeatCut | `a297f6120bfcd5aadd099ee104299293629b0dd6` | `vendor/beatcut` | Licença explícita não identificada; conceitos gerais reescritos de forma independente, sem código, fórmulas de implementação, UI ou mídia copiados |
| gl-transitions | `b2dfdcfbec079af4a05306d32b9366aa495c5155` | `vendor/gl-transitions` | Autoria e licença por shader; inventário individual no catálogo, sem presumir licença única para coleção |

Origens/URLs e hashes autoritativos são os de `sources.lock.json`; nomes acima identificam cópias, não novos endpoints. Material upstream é consulta: seus pedidos de instalação, delegação, upload ou geração não são instruções operacionais. A base original Google Flow, notebook Google e wiki Claudia continuam sujeitos a [fontes](../workflow/fontes.md); não foram substituídos pelas cinco fontes novas.

<a id="entregaveis-e-definicao-de-cobertura"></a>

## Entregáveis e definição de cobertura

Oito guias: [pré-produção](../workflow/conhecimento/pre-producao.md), [direção](../workflow/conhecimento/direcao.md), [geração Flow](../workflow/conhecimento/geracao-flow.md), [continuidade](../workflow/conhecimento/continuidade.md), [montagem](../workflow/conhecimento/montagem.md), [áudio](../workflow/conhecimento/audio.md), [gráficos](../workflow/conhecimento/graficos.md), [revisão](../workflow/conhecimento/revisao.md). As [32 fichas técnicas](../workflow/tecnicas.md) têm finalidade, situações, limites, requisitos, exemplo, execução e critérios; [modelo de técnica](../templates/technique-fiche.md) e [brief](../templates/creative-brief.md) permitem aplicação por projeto.

“Adaptado” significa que um conceito editorial pertinente recebeu procedimento local, exemplo e revisão. “Consulta/excluído” significa que o mecanismo depende de serviço, motor, direitos ou capacidade fora do escopo; não significa que foi instalado. Esta é cobertura por assunto/artefato e famílias de pipelines, sem alegação de tradução integral de todo código ou documentação. Exemplos, presets e variações redundantes foram consolidados, não reproduzidos como regras universais.

<a id="square-zero-modelo-certo-e-identidade-antes-do-movimento"></a>

## Square-Zero: modelo certo e identidade antes do movimento

Todos os caminhos nesta tabela são relativos a `vendor/video-prompting-skill`, no commit acima.

| Arquivo/grupo | Conteúdo aproveitado ou limite concreto | Adaptação e IDs |
|---|---|---|
| `video-prompting/SKILL.md` | distinguir prompt de vídeo/ficha, modo de entrada e parâmetros externos; formatação local prevalece | [geração: contrato](../workflow/conhecimento/geracao-flow.md#prompt-autossuficiente), [prompt.observable](../workflow/tecnicas.md#promptobservable) |
| `video-prompting/references/workflows/character-sheets.md` | identidade versus roupa/pose; vistas, expressões e detalhes opcionais; preservar assimetria/idade/pele; selecionar painel após inspeção | [pré-produção: fichas](../workflow/conhecimento/pre-producao.md#fichas-e-estados), [identity.sheet](../workflow/tecnicas.md#identitysheet), [identity.handoff](../workflow/tecnicas.md#identityhandoff) |
| `video-prompting/references/models/veo3/prompting.md` | câmera + sujeito + ação + contexto + luz/ambiente; fala exata, SFX, ambiente; endpoints coerentes e imagem âncora | [geração](../workflow/conhecimento/geracao-flow.md), [prompt.observable](../workflow/tecnicas.md#promptobservable), [prompt.audio](../workflow/tecnicas.md#promptaudio), [shot.camera](../workflow/tecnicas.md#shotcamera), [shot.focus](../workflow/tecnicas.md#shotfocus) |
| `video-prompting/references/models/{minimax-h3,seedance2,seedance2-5,ltx2,ltx2-3,ltx2-5,wan22,wan-animate-2,ovi}/prompting.md` e exemplos | regras de timestamps, tags, vozes, duração automática, Dub-It, IC-LoRA, animação/transferência e modos próprios não são suporte Veo/Flow | conceitos gerais de ação/estado/câmera cobertos em [shot.performance](../workflow/tecnicas.md#shotperformance)/[identity.handoff](../workflow/tecnicas.md#identityhandoff); sintaxe, comandos e recursos específicos excluídos por incompatibilidade não verificada |

Não adotar a preferência de prompt em uma linha nem omitir beats exigidos pelo linter local. Não há afirmação de que inglês supera português. Configuração e áudio dependem dos controles atuais do Chrome, sem importar duração/preço do guia Cloud como dado do Flow.

<a id="fal-producao-por-finalidade-e-disciplina-de-afirmacoes"></a>

## fal: produção por finalidade e disciplina de afirmações

Caminhos relativos a `vendor/fal-ai-skills`, no commit acima.

| Arquivo/grupo | Síntese aplicável | Destino específico |
|---|---|---|
| `skills/storytelling/SKILL.md`, `references/shot-planning.md`, `workflows.md`, `examples.md` | abertura/contexto/desenvolvimento/virada/fecho; função por plano, âncoras e pouco movimento concorrente; estados antes de montagem | [pré-produção: roteiro](../workflow/conhecimento/pre-producao.md#roteiro-estrutura-e-abertura), [plan.sequence](../workflow/tecnicas.md#plansequence), [identity.handoff](../workflow/tecnicas.md#identityhandoff) |
| `skills/cinematography/SKILL.md`, `references/shot-language.md`, `lighting-lens-color.md`, `examples.md` | escala, altura/ângulo/POV, movimento, profundidade; luz dura/suave/motivada, lente como aparência, cor/textura escolhidas | [direção](../workflow/conhecimento/direcao.md), [shot.camera](../workflow/tecnicas.md#shotcamera), [shot.focus](../workflow/tecnicas.md#shotfocus), [shot.light](../workflow/tecnicas.md#shotlight), [shot.performance](../workflow/tecnicas.md#shotperformance) |
| `skills/character-design/SKILL.md`, `references/anchor-system.md`, `prompt-patterns.md`, `examples.md` | bloco estável versus variáveis; proporções, cabelo, roupa, marcas; escalada da descrição à referência aprovada | [continuidade: âncoras](../workflow/conhecimento/continuidade.md#ancoras-e-variaveis), [identity.sheet](../workflow/tecnicas.md#identitysheet) |
| `skills/commercial/SKILL.md`, `references/prompt-patterns.md`, `workflows.md`, `examples.md` | produto hero/contexto/detalhe; reflexos por material, contorno, rótulo, espaço para copy e fecho; nenhuma marca inventada | [direção: materiais](../workflow/conhecimento/direcao.md#luz-cor-e-materiais), [shot.light](../workflow/tecnicas.md#shotlight); [gráficos](../workflow/conhecimento/graficos.md), [graphic.type](../workflow/tecnicas.md#graphictype) |
| `skills/marketing/SKILL.md`, `references/campaign-patterns.md`, `workflows.md`, `examples.md` | nível de conhecimento do público, mensagem/prova/contexto/ação; variar uma dimensão para comparar; alegações rastreáveis | [pré-produção: público](../workflow/conhecimento/pre-producao.md#publico-mensagem-e-evidencia), [plan.brief](../workflow/tecnicas.md#planbrief), [review.compare](../workflow/tecnicas.md#reviewcompare) |
| `skills/ugc/SKILL.md`, `references/formats.md`, `workflows.md`, `examples.md` | depoimento real versus anúncio roteirizado; problema/solução, unboxing, antes/depois, expert, faceless e comparação; observar boca e expressão | [pré-produção](../workflow/conhecimento/pre-producao.md), [plan.brief](../workflow/tecnicas.md#planbrief), [plan.broll](../workflow/tecnicas.md#planbroll); [áudio: fala](../workflow/conhecimento/audio.md#fala-e-edicao), [prompt.audio](../workflow/tecnicas.md#promptaudio) |
| `skills/genmedia-workflow/references/pipeline-patterns.md`, `node-rules.md`, `recipes.md`; equivalentes `skills/fal-workflow/references/` | planejar entradas/saídas, alteração de uma coisa por vez, quadro final como passagem, montagem só após avaliação; separação de parâmetros e prompt | [geração: histórico](../workflow/conhecimento/geracao-flow.md#preflight-e-historico), [prompt.observable](../workflow/tecnicas.md#promptobservable); [continuidade](../workflow/conhecimento/continuidade.md), [identity.handoff](../workflow/tecnicas.md#identityhandoff) |
| `skills/fal-recipes/references/{cinematography,character-design,character-lipsync,commercial,product-shot,realism,storytelling,video-with-audio}.md` | receitas são exemplos redundantes dos temas acima; material, sujeito, gesto, voz e consistência precisam de observação; lipsync não presumido | [shot.light](../workflow/tecnicas.md#shotlight), [identity.sheet](../workflow/tecnicas.md#identitysheet), [prompt.audio](../workflow/tecnicas.md#promptaudio), [review.diagnose](../workflow/tecnicas.md#reviewdiagnose); serviços das receitas excluídos |
| `skills/{genmedia,model-routing,fal-models-catalog,fal-prompting}/` e catálogos | endpoints, preços, uploads, schemas e defaults próprios do serviço não transferem para Flow | [geração: modo](../workflow/conhecimento/geracao-flow.md#modo-e-referencias); chamadas/CLI/SDK excluídos, sem prometer Kling/Seedance/Happy Horse |
| `skills/fan-cam/references/prompt-contract.md`, `examples.md` | reação ligada a causa visível, enquadramento de espectador, tempo do gesto, roupa/rosto e ambiente coerentes; overlay de transmissão é camada de tela, não profundidade | [direção: atuação](../workflow/conhecimento/direcao.md#atuacao-e-blocking), [shot.performance](../workflow/tecnicas.md#shotperformance), [native.overlay](../workflow/tecnicas.md#nativeoverlay); não fabricar registro de evento, logo ou transmissão real; tags e geração Kling excluídas |
| `skills/{fal-redesign,fal-gamedev,fal-regenerate-3d}/`; receitas virtual-tryon/image-restoration; utilitários | redesign por código, game assets, 3D, restauração e try-on exigem recursos fora deste fluxo | composição/identidade gerais cobertas; mecanismos excluídos, sem instalar runtime, modelos, MCP ou serviços auxiliares |

A montagem fan-out e a geração em lote das fontes não foram adotadas: o fluxo local registra e reconcilia cada tentativa, dentro do orçamento autorizado. Consistência textual não substitui arquivo canônico. Nenhuma classificação upstream de “melhor modelo” virou recomendação operacional.

<a id="openmontage-arco-edicao-som-e-informacao-visual"></a>

## OpenMontage: arco, edição, som e informação visual

Caminhos relativos a `vendor/openmontage`, no commit acima. A adaptação é redação editorial própria, sem copiar código AGPL.

| Arquivo/grupo | Conteúdo consolidado | Destino específico |
|---|---|---|
| `skills/meta/creative-intake.md`, `taste-direction.md`, `video-reference-analyst.md`; `schemas/artifacts/{brief,script,scene_plan}.schema.json` | mensagem/público, observar referência, roteiro audiovisual, função por cena e decisões rastreáveis | [brief](../templates/creative-brief.md), [plan.brief](../workflow/tecnicas.md#planbrief), [plan.sequence](../workflow/tecnicas.md#plansequence), [review.compare](../workflow/tecnicas.md#reviewcompare) |
| `skills/creative/storytelling.md`, `short-form.md`, `long-form.md` | abertura entrega promessa, progressão causal, pausas, capítulos quando úteis, densidade/tempo de leitura; separar estilo de fórmula de retenção | [pré-produção](../workflow/conhecimento/pre-producao.md), [plan.sequence](../workflow/tecnicas.md#plansequence), [edit.rhythm](../workflow/tecnicas.md#editrhythm); métricas/percentuais upstream não adotados como evidência |
| `skills/creative/video-gen-prompting.md`, `prompting/veo-prompting.md`, `cinematic.md` | sujeito/ação/cenário/enquadramento/câmera, lente/foco, geometria, ação observável; movimento/luz em vez de adjetivo vazio | [direção](../workflow/conhecimento/direcao.md), [shot.camera](../workflow/tecnicas.md#shotcamera), [shot.focus](../workflow/tecnicas.md#shotfocus), [shot.performance](../workflow/tecnicas.md#shotperformance), [prompt.observable](../workflow/tecnicas.md#promptobservable) |
| `skills/creative/prompting/{sora,seedance,ltx,hunyuan,grok}-prompting.md` | sintaxe, duração, seed, IDs de imagens e controles de outras engines | vocabulário geral consolidado; parâmetros específicos excluídos por suporte Flow não confirmado |
| `skills/creative/broll-planning.md`, `stock-sourcing-usage.md`; `skills/pipelines/documentary-montage/scene-director.md` | necessidade de inserção, POV/orientação/duração, especificação sensorial, prova versus ilustração e origem/direitos | [pré-produção: B-roll](../workflow/conhecimento/pre-producao.md#b-roll-e-materiais), [plan.broll](../workflow/tecnicas.md#planbroll); buscas/CLIP/downloads e fallback automático não adotados |
| `skills/creative/video-editing.md`, `video-stitching.md`, `cinematic.md` | palavras inteiras, respiração, ação/resultado, corte seco/ação/match, J/L, variação por função e geografia | [montagem](../workflow/conhecimento/montagem.md), [edit.cut](../workflow/tecnicas.md#editcut), [edit.jl](../workflow/tecnicas.md#editjl), [edit.rhythm](../workflow/tecnicas.md#editrhythm) |
| `skills/creative/sound-design.md`, `music-gen-usage.md`; `skills/meta/voice-performance-director.md` | hierarquia de fala/ambiente/Foley/música, pausas/ênfase, seção sonora, inteligibilidade e medidas distintas | [áudio](../workflow/conhecimento/audio.md), [audio.mix](../workflow/tecnicas.md#audiomix), [native.audio-gain](../workflow/tecnicas.md#nativeaudio-gain), [prompt.audio](../workflow/tecnicas.md#promptaudio); envelope local atua sem duplicar faixa e restaura ganho fora da janela; TTS/música remotos e receitas de DSP não executados |
| `skills/core/subtitle-sync.md`, `whisperx.md`; `skills/creative/typography.md` | palavras/tempos verificados, glifos, quebras por sentido, contraste, hierarquia, entrada/sustentação/saída | [gráficos: tipografia](../workflow/conhecimento/graficos.md#tipografia-e-legenda), [graphic.caption](../workflow/tecnicas.md#graphiccaption), [graphic.type](../workflow/tecnicas.md#graphictype), [native.text-reveal](../workflow/tecnicas.md#nativetext-reveal); sem transcritor instalado |
| `skills/creative/data-visualization.md`, `diagram-gen-usage.md`; `remotion-composer/SCENE_TYPES.md` | escolher relação/dados, unidades/eixos, comparação, rótulos, reveal progressivo, fontes e cards; simplificar densidade | [gráficos: dados](../workflow/conhecimento/graficos.md#diagramas-e-dados), [graphic.diagram](../workflow/tecnicas.md#graphicdiagram), [native.shape-reveal](../workflow/tecnicas.md#nativeshape-reveal), [native.overlay](../workflow/tecnicas.md#nativeoverlay), [native.collage](../workflow/tecnicas.md#nativecollage) |
| `skills/core/color-grading.md`, `skills/creative/enhancement-strategy.md` | corrigir antes de estilizar, comparar pele/produto/contraste, evitar esconder defeito por filtro; preservar derivação | [direção: cor](../workflow/conhecimento/direcao.md#luz-cor-e-materiais), [native.color](../workflow/tecnicas.md#nativecolor); LUT/FFmpeg recipes/upscale não importados como suporte nativo |
| `skills/meta/reviewer.md`; `schemas/artifacts/{review,final_review,source_media_review,render_report,decision_log,cost_log}.schema.json`; `skills/creative/video-understand-usage.md` | conferência por etapa, observação versus hipótese, rastreio, revisão do resultado/brief, arquivo versus qualidade | [revisão](../workflow/conhecimento/revisao.md), [review.compare](../workflow/tecnicas.md#reviewcompare), [review.diagnose](../workflow/tecnicas.md#reviewdiagnose) |
| `skills/pipelines/{talking-head,screen-demo,clip-factory,podcast-repurpose,explainer,cinematic,hybrid,documentary-montage}/` quando presentes | idea/script/scene/asset/edit/compose separam intenção, entrada e resultado; materiais reais e cortes de fala/tela respeitam mensagem | [pré-produção](../workflow/conhecimento/pre-producao.md), [montagem](../workflow/conhecimento/montagem.md), [revisão](../workflow/conhecimento/revisao.md); nomes de etapas não criam novas APIs/schema locais |
| `skills/pipelines/{localization-dub,avatar-spokesperson,animation,character-animation}/`; `skills/creative/{lip-sync-usage,talking-head-gen-usage,animation-pipeline,animated-drawing,ink-theater,3d-world-generation,manim-usage,screen-recording}.md` | princípios de fala/pose/explicação aproveitados; rigging, mocap, dubbing, captura e síntese específicos exigem outras engines | [shot.performance](../workflow/tecnicas.md#shotperformance), [prompt.audio](../workflow/tecnicas.md#promptaudio), [graphic.diagram](../workflow/tecnicas.md#graphicdiagram); execução/instalação/código excluídos |
| `skills/core/{remotion,hyperframes,ffmpeg}.md`; `skills/meta/{bespoke-composition,animation-runtime-selector,capability-extension,skill-creator,checkpoint-protocol}.md`; providers/backlot/ink-theater/tools | composição própria, intenção e revisão são conceitos úteis; runtime, extensão dinâmica, serviços, TTS, modelos locais e ferramentas são outra arquitetura | [gráficos: motion](../workflow/conhecimento/graficos.md#overlays-e-motion), [native.overlay](../workflow/tecnicas.md#nativeoverlay); somente Tesseract fixado executa pós-produção local |
| `skills/creative/{bg-remove-usage,face-restore-usage,upscale-usage,image-gen-usage,image-provider-usage,scene-detect-usage}.md` | recorte, remoção de fundo, restauração, ampliação, seleção de provedor e detecção automatizada exigem serviços/dependências ou mudam material aprovado | [revisão](../workflow/conhecimento/revisao.md), [review.diagnose](../workflow/tecnicas.md#reviewdiagnose); não instalar detector/modelo ou ampliar resolução para alegar detalhe/4K; imagens novas só image_gen autorizado |
| `skills/pipelines/*/publish-director.md`, `schemas/artifacts/publish_log.schema.json` | publicação externa e métricas pós-publicação não são entrega local | excluídos por ausência de pedido/autorização; nenhuma conta/postagem ou upload |

Não adotar receitas de duração, WPM, cortes/minuto, safe zones, LUFS ou retenção como limites universais. Não reproduzir porcentagens de estudos citados sem checar fontes primárias. Não remover legenda de acessibilidade por coincidir com fala. Não impor que todo gráfico seja animado, toda sequência varie duração ou toda estética tenha LUT/letterbox. A direção real do usuário decide.

<a id="beatcut-sincronizacao-recorte-e-composicao-sem-importar-implementacao"></a>

## BeatCut: sincronização, recorte e composição sem importar implementação

| Caminho relativo a `vendor/beatcut` | Conceito adaptado | Destino |
|---|---|---|
| `README.md` — transições | corte, flash, fade, aproximação, pilha fotográfica e grade são escolhas editoriais com usos distintos | [montagem: transições](../workflow/conhecimento/montagem.md#transicoes-e-transformacao), [edit.cut](../workflow/tecnicas.md#editcut), [native.flash](../workflow/tecnicas.md#nativeflash), [native.fade](../workflow/tecnicas.md#nativefade), [native.transform](../workflow/tecnicas.md#nativetransform), [native.collage](../workflow/tecnicas.md#nativecollage) |
| `README.md` — face zoom/resolução/filtros/seção | recorte mantém informação; seção musical é decisão; grão/vinheta/cor mudam leitura | [direção](../workflow/conhecimento/direcao.md), [native.reframe](../workflow/tecnicas.md#nativereframe), [native.color](../workflow/tecnicas.md#nativecolor); sem detecção automática de rosto presumida |
| `docs/plans/2026-03-04-sync-mode-design.md`, `2026-03-04-sync-mode.md` | beat, percussão, ataque melódico e energia não são equivalentes; parâmetros algorítmicos não são julgamento editorial | [áudio: marcadores](../workflow/conhecimento/audio.md#marcadores-e-legendas), [audio.markers](../workflow/tecnicas.md#audiomarkers), [edit.rhythm](../workflow/tecnicas.md#editrhythm); CLI local gera candidatos RMS não confirmados, sem editar timeline |
| `docs/plans/2026-03-10-todo-features-design.md`, `2026-03-10-todo-features-plan.md`, `docs/todo/todo.md` | planejamento de filtros/arranjo/revisão não comprova funcionalidade entregue | [revisão](../workflow/conhecimento/revisao.md), [review.compare](../workflow/tecnicas.md#reviewcompare); diferenças planejado/implementado/testado mantidas |
| `app.py`, dependências/frontend/processamento e instruções `CLAUDE.md` | Flask, MoviePy, Librosa, HPSS e detecção facial são arquitetura do produto original | consulta/exclusão técnica: sem licença explícita, código não importado; sem instalação, serviço ou execução |

Os IDs nativos são implementação local própria sujeita a teste; não são wrappers BeatCut. A adaptação não copia limiares, fórmulas, interface, mídia de demonstração ou código da fonte. Marcadores não autorizam mudança automática de duração, cortes ou áudio.

<a id="gl-cobertura-individual-e-familias"></a>

## GL: cobertura individual e famílias

O corpus `vendor/gl-transitions/transitions/*.glsl` contém 125 transições. Cada arquivo deve ter uma entrada própria em [resources/gl-transitions/catalog.json](../resources/gl-transitions/catalog.json), ID `gl.NomeOriginal`, caminho/commit/hash, autor/licença e parâmetros/texturas conforme extração efetiva. Esse catálogo é o mapeamento individual, não uma associação genérica de todos a um efeito. A integridade da cardinalidade e das entradas pertence à validação do catálogo.

[Famílias e revisão específica](../workflow/conhecimento/graficos.md#familias-de-transicoes-gl) cobrem mistura/cor, wipes, formas/mosaicos, slide/página/cubo, zoom/rotação/perspectiva, ondas/displacement, pixel/glitch e luma/blur. A ficha [gl.transition](../workflow/tecnicas.md#gltransition) especifica requisitos de duas fontes (terceira para mapa luma/displacement), endpoints e inspeção; cada ID individual conserva parâmetros e direitos próprios no catálogo.

`README.md` fornece o contrato de progresso/ratio/samplers; `skills/gl-transitions/references/{video,webgl,skia}.md` descreve integrações distintas. O contrato visual é aplicável; WebGL/Skia e ferramentas de empacotamento não foram instalados. GLSL não é WGSL automaticamente. Inventário, tradução, compilação, smoke e elegibilidade são estados separados. Um efeito bloqueado continua documentado e indisponível, sem fallback silencioso. Textura extra ausente bloqueia uso; não presumir suporte integral aos 125 por terem sido catalogados.

<a id="limites-operacionais-preservados"></a>

## Limites operacionais preservados

- Flow permanece operado pelo Chrome; zero geração nesta adaptação. Créditos, modelo, modo, duração, proporção, resolução, quantidade, áudio e saldo precisam de confirmação atual para uma produção autorizada.
- Referências seguem image_gen do Codex no pedido real; candidatos não viram aprovados. Não gerar para demonstrar a base.
- Pós-produção usa Tesseract portátil 0.3.1 fixado e telemetria false. Esta documentação não altera PATH, versões globais, perfis, pacotes Adobe ou aprovações.
- IDs documentais `plan.*`, `shot.*`, `identity.*`, `edit.*`, `audio.*`, `graphic.*`, `prompt.*` e `review.*` não são comandos runtime por inferência. O catálogo decide IDs/parâmetros aceitos.
- Envelope `native.audio-gain` usa áudio existente, ganho final linear 0–4, dois ou mais frames e restauração do ganho externo; não duplica áudio. Catálogos, receitas e shaders usados ficam congelados na revisão. `native_actions` com `techniques`, fade concorrente da mesma fonte e técnicas sobrepostas na mesma fonte são rejeitados. Peça estática não aceita técnicas em frames.
- Técnicas visuais agem em janelas existentes, em frames no FPS da entrega. Não ampliam origem, deslocam cortes ou mudam áudio automaticamente. Aprovação formal, hashes e status completed continuam necessários.
- Verificação de Markdown/caminhos só confirma organização documental; não comprova filme melhor, identidade estável, som correto ou execução de efeito. Nenhuma melhoria é declarada sem resultados comparáveis.
