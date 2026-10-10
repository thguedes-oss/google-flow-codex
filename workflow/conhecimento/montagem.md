<a id="montagem-relacoes-duracao-e-ritmo"></a>

# Montagem: relações, duração e ritmo

Use fontes elegíveis segundo [pós-produção](../pos-producao.md): tentativa `completed`, hash íntegro e aprovação formal vigente verificada por `flow_review.verify_decision`. Tesseract portátil 0.3.1, telemetria desativada, plano separado dos CSVs e revisões novas são obrigatórios. Este guia não cria composição/render.

<a id="selecao-e-cortes"></a>

## Seleção e cortes

Selecione trecho que cumpre função com início/resultado legíveis. Registre origem, entrada/saída em milissegundos e posição. Confira frames reais no corte. Na fala, preserve palavras inteiras, respiração necessária e contexto. Hesitação/repetição pode ser removida sem alterar sentido; pausa pode ser intenção, sem limiar universal.

Corte seco separa planos; corte na ação acompanha gesto; match cut liga forma/movimento; detalhe mostra prova; reação mostra consequência. Cobertura não fabrica evento nem oculta contradição. J-cut antecipa som seguinte e L-cut prolonga anterior; precisam de intervalos e fontes conferidos em [áudio](audio.md).

<a id="ritmo-e-sincronizacao"></a>

## Ritmo e sincronização

Ritmo depende de perceber ação, ler, ouvir e reagir. Varie duração conforme função, sem forçar variedade ou regularidade. Música sugere batida, percussão, ataque melódico ou pico de energia: eventos diferentes, e nem todo pico é beat. BPM sozinho não localiza cortes. Escute seção real e registre marcadores com origem/evidência.

Marcadores propõem entrada visual; não deslocam corte, ampliam `sourceRange`, prolongam fontes ou mudam áudio automaticamente. Se caem no meio da fala, priorize compreensão ou registre revisão deliberada. Imagens precisam de tempo para reconhecimento. Extração técnica continua hipótese até escuta. Não instalar BeatCut/Librosa ou stems por efeito deste guia.

<a id="transicoes-e-transformacao"></a>

## Transições e transformação

Dissolução pode sugerir passagem gradual; fade para cor separa segmentos; flash destaca evento; zoom/crop cria aproximação gráfica; overlay/colagem compara ou acumula. Escolha por função. Flash/glitch repetidos reduzem leitura e podem causar desconforto: evite pulsação intensa desnecessária e reveja a sequência.

`native.fade`, `native.flash`, `native.transform`, `native.reframe`, `native.overlay` e `native.collage` constam no [catálogo](../../resources/techniques/catalog.json), cujo suporte/parâmetros devem ser conferidos. Documentação não prova render. Escala exige resolução útil e recorte deliberado; não simula câmera física. Colagem de duas a quatro fontes precisa de hierarquia, margens e ponto principal. Pilha e grade são composições próprias, sem código BeatCut.

GL usa origem/destino e progresso 0→1. Consulte [famílias](graficos.md#familias-de-transicoes-gl) e [mapeamento individual](../../resources/gl-transitions/catalog.json). GLSL não prova suporte no Tesseract; adaptação/validação/smoke decidem disponibilidade. Preserve autoria/licença por shader; não substitua um efeito indisponível silenciosamente.

<a id="compatibilidade-das-fontes"></a>

## Compatibilidade das fontes

Confira metadados reais: dimensões, proporção, FPS constante/variável, duração, orientação, codec e áudio. Misturar formatos pode exigir ajuste explícito de enquadramento/relógio e nova revisão; não deformar a fonte para caber nem descartar som silenciosamente. Em sequência longa, examine sincronismo no começo/meio/fim para detectar deriva. Um arquivo decodificável pode conter frame repetido, corte deslocado ou áudio atrasado. Não presumir concatenação sem recompressão por compartilhar extensão MP4.

<a id="tempo-e-entrega"></a>

## Tempo e entrega

Técnicas usam `start_frame`/`duration_frames` no FPS da entrega; campos existentes do plano continuam em milissegundos. Confira arredondamento. A janela visual precisa existir nas fontes declaradas; duas fontes devem cobrir o intervalo. Não estenda, desloque corte ou mude áudio automaticamente. Mudança cria nova revisão/evidência; inspecione antes/durante/depois e escute emenda.

Confira dimensão real, FPS, duração e decodificação. 4K sem perfil verificado falha, sem ampliar pixels para ocultar limite. Entregue fonte editável e exportação correspondente, com limites Adobe e sem publicação automática.

Técnicas: [edit.cut](../tecnicas.md#editcut), [edit.rhythm](../tecnicas.md#editrhythm), [edit.jl](../tecnicas.md#editjl), [native.flash](../tecnicas.md#nativeflash), [native.fade](../tecnicas.md#nativefade), [native.transform](../tecnicas.md#nativetransform), [native.reframe](../tecnicas.md#nativereframe), [native.collage](../tecnicas.md#nativecollage).

Fontes: OpenMontage `skills/creative/video-editing.md`, `video-stitching.md`, `cinematic.md`; BeatCut `README.md`, `docs/plans/2026-03-04-sync-mode-design.md`; GL `README.md`. [Cobertura](../../reports/knowledge-coverage.md).
