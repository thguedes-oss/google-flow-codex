# Incorporação das cinco fontes ao FLOW

Entrega em 10 de outubro de 2026. As cinco fontes foram inventariadas e reconciliadas com o fluxo local. A biblioteca executável contém **125 transições WGSL e dez receitas nativas habilitadas**, com evidências atuais no motor portátil Tesseract 0.3.1. Conteúdo editorial, suporte executável e aprovação de produção permanecem avaliações separadas.

## Fontes e cobertura documental

| Fonte | Commit fixado | Arquivos inventariados | Direitos observados |
|---|---|---:|---|
| fal-ai-community/skills | `9ca850412943251fc9a466c4c29fdaf7a303a3d8` | 97 | MIT declarada no README; ausência de LICENSE global registrada |
| OpenMontage | `9327439db69021ab4b0e2776729bf3b58fdb5a87` | 2143 | AGPL e avisos individuais preservados; redação editorial própria, sem runtime importado |
| GL Transitions | `b2dfdcfbec079af4a05306d32b9366aa495c5155` | 172 | Licença/autoria por shader; MIT raiz quando não há cabeçalho específico |
| BeatCut | `a297f6120bfcd5aadd099ee104299293629b0dd6` | 21 | Licença explícita não identificada; conceitos reescritos e implementação independente, sem trechos copiados |
| Square-Zero | `8d72999ebe8bde390a658d3f6f8a79558b73bd5c` | 26 | Apache-2.0; clone existente preservado |

Os quatro clones novos são independentes, rasos, com finais LF preservados e sem download automático de submódulos/LFS. O upstream principal, o pin Square-Zero, o notebook Google e o snapshot Claudia foram preservados. Não foram executados instaladores, skills ou aplicativos dessas fontes complementares.

Os [cinco inventários](../config/source-inventories/) registram **2459 arquivos**, cada um com caminho, hash, categoria, licença observada, aplicabilidade, destino e justificativa. Classificação: 519 itens de consulta ligados à adaptação, 125 shaders ligados ao catálogo individual e 1815 exclusões justificadas, principalmente infraestrutura/aplicativos, dependências, serviços e artefatos fora do fluxo autorizado. [Duplicações](../config/source-inventories/duplicates.json): 437 grupos e 947 origens preservadas. A [integridade offline](../scripts/source_integrity.py) confere checkout, pin, arquivos extras/ausentes, bytes, sidecars e grupos exatos, sem atualizar fontes.

Foram entregues oito guias em português: [pré-produção](../workflow/conhecimento/pre-producao.md), [direção](../workflow/conhecimento/direcao.md), [geração Flow](../workflow/conhecimento/geracao-flow.md), [continuidade](../workflow/conhecimento/continuidade.md), [montagem](../workflow/conhecimento/montagem.md), [áudio](../workflow/conhecimento/audio.md), [gráficos](../workflow/conhecimento/graficos.md) e [revisão](../workflow/conhecimento/revisao.md). As [32 fichas](../workflow/tecnicas.md) incluem finalidade, situações, limitações, requisitos, exemplo, execução e revisão. Há modelos de [brief](../templates/creative-brief.md) e [ficha](../templates/technique-fiche.md), conectados aos procedimentos existentes. A [matriz documental](knowledge-coverage.md) detalha consolidações e exclusões por assunto/arquivo.

## Suporte executável

O plano de pós-produção aceita `techniques` opcional. Planos anteriores continuam válidos; tempos antigos permanecem em ms. Novos efeitos visuais usam `start_frame`/`duration_frames`, fontes como `clip:0`/`image:0` e parâmetros tipados dos catálogos. Não há extensão de fontes, deslocamento de cortes ou mudança de áudio silenciosa. Aprovação formal vigente por `flow_review.verify_decision`, hash e status `completed` continuam exigidos. Cada revisão congela também compilador, catálogos e shaders utilizados.

| Recurso | Estado e evidência |
|---|---|
| Flash, fade, transform, reenquadramento, overlay, colagem, texto e formas | Receitas nativas, verificadas nos formatos horizontal, vertical e quadrado |
| Brilho, contraste, saturação e vinheta | Shader local independente; três formatos e alpha sem duplicação |
| Envelope de áudio | Ganho linear na camada original, sem duplicação; ganho externo restaurado |
| Candidatos de sincronização | `audio_markers.py`, RMS local com fonte/hash/tempos; `confirmed: false`, confirmação por escuta |
| GL Transitions | Todos os 125 arquivos avaliados, portados individualmente para WGSL estático e habilitados; zero entradas incompletas/incompatíveis no catálogo GL |

Consulte [receitas e evidências por ID](../resources/techniques/README.md), [catálogo GL](../resources/gl-transitions/catalog.json) e [exemplos de uso](../workflow/pos-producao.md#tecnicas-em-janelas-existentes). `luma`/`displacement` exigem terceira fonte para o mapa. O tradutor GLSL é ferramenta de desenvolvimento; produção carrega módulos locais versionados, sem conversão arbitrária ou download. Nomes, parâmetros, autoria, fontes e licenças originais estão preservados.

## Verificação concluída

- `scripts/check.ps1` com Python **3.12.13**, execução `20261010T112801445562Z-28e7a5e7`: código 0, **140 testes locais e 70 upstream passaram**, integridade e linters passaram com `--beat-mode coverage`. [Resultado](verification.json), [logs preservados](runs/20261010T112801445562Z-28e7a5e7/verification.json). `planning_passed=true`; `generation_ready=false`, como esperado para exemplo sem referências/aprovações e orçamento zero.
- [GL](gl-transitions-summary.json): **375 casos, 1875 frames amostrados** (125 × três formatos × cinco progressos). Fontes assimétricas em movimento e recortes distintos; mapas adicionais quando necessários; compilação, extremos, orientação, proporção, preto intermediário, fallback/pass-through e RGB transparente avaliados. Os resultados por formato têm hashes e correspondem aos WGSL atuais.
- [Receitas nativas](techniques-smoke.json): **33 casos passaram**, incluindo oito receitas visuais nos três formatos. Flashes de um e dois frames foram contados nos MP4 exportados em 24, 30 e 60 fps: índices `[3]` e `[3,4]`. Envelope de áudio verificado por RMS antes/durante/depois, com restauração.
- [Pipeline completo](technique-pipeline-smoke.json): duas fontes móveis com entradas e posições diferentes, janela isolada e gráfico frontal. Frames externos tiveram MAE **0** contra baseline; extremos 0 e 0,176/255; gráfico frontal 1,667/255, dentro da tolerância de codificação 2/255. Áudio decodificado **idêntico byte a byte**, helpers com volume zero. PNGs com alpha 127 mantiveram alpha 127 em `gl.fade` e `native.color`, sem duplicação das fontes originais. Manifesto/CSV reais e fixtures de geração permaneceram inalterados.
- [Perfis nativos](tesseract-smoke-incorporation.json): cortes, texto, áudio, animatic e design reabertos/renderizados; dimensões reais **1280×720, 720×1280, 720×720, 1920×1080 e 3840×2160** verificadas. Canvas de entrega preservado; isso não aumenta detalhe de fonte de resolução menor.
- [Gate de cobertura](incorporation-coverage.json): passou com hashes atuais das implementações, receitas, shaders e relatórios. Testes rejeitam evidências ausentes/alteradas e incluem controle positivo sem substituir hashes. [Revisão independente](incorporation-code-review.md): nenhum defeito reproduzível aberto; dois P2 encontrados foram corrigidos e rechecados (ordem de camadas e vínculo das evidências à implementação).
- Documentação final: 19 arquivos e 298 links locais/âncoras conferidos, sem caminhos ausentes ou âncoras explícitas repetidas.

Os arquivos de evidência são versionáveis; vídeos, PNGs de fixtures e projetos nativos de teste permanecem em diretórios temporários identificados nos relatórios. Foram inspecionadas pranchas de InvertedPageCurl, fade vertical, integração com gráfico frontal e transparência. Métricas/inspeções pontuais não equivalem a reprodução completa, escuta humana, equivalência integral ao WebGL original ou aprovação de produção.

<a id="limites-e-itens-incompletos"></a>

## Limites e itens incompletos

| Conteúdo | Classificação explícita | Limite concreto/destino |
|---|---|---|
| Alpha em `burn`, `flyeye`, `GlitchMemories`, `HSVfade`, `InvertedPageCurl`, `SimpleFlip`, `tangentMotionBlur` | Habilitado com limitação observada | Expressões originais podem forçar opacidade; não usar como garantia de transparência. [Detalhes](../resources/gl-transitions/README.md) |
| Extremos de `AdvancedMosaic` e `tangentMotionBlur` | Habilitado com limitação observada | Grade UV 0,005 e desfoque `exp(-5)` originais produzem resíduos; preservados, sem snaps artificiais |
| Grão, sépia/LUT, halation/bloom e pilha fotográfica pronta | Conhecimento coberto; conveniências reutilizáveis **incompletas** | Não há receita específica habilitada. `native.color` oferece somente seus quatro parâmetros; `native.collage` é grade. Sobreposições/transformações permitem autoria explícita de pilha em plano próprio, sem preset testado |
| Máquina de escrever, animação por palavra, máscaras arbitrárias, partículas, tracking e 3D | Conhecimento coberto; suporte específico **não verificado/incompleto** | Reveals entregues são opacidade/deslocamento de texto/retângulo; não declarar incompatibilidade sem investigar a API e testar uma implementação |
| EQ, compressão, limiter, ducking automático, análise de melodia/percussão, detecção facial e transcrição automática | Consulta; automação local específica **não implementada** | Ganho/RMS não substituem DSP, beat tracking, reconhecimento ou transcrição. Nenhum motor/modelo/dependência externo foi instalado; decisões manuais seguem os guias |
| Técnicas contíguas/sobrepostas na mesma fonte; técnicas junto de `native_actions` ou fade concorrente | Restrição concreta do contrato entregue | Validação rejeita combinações ambíguas; novas revisões/reestruturação explícita, sem composição silenciosa de animações |
| Premiere com texto/gráficos híbridos | Limitação preexistente reconfirmada | Conversor falha na validação do pacote `media/ae-0001/compositions.aep`; saída parcial não é entrega. Pacote de cortes/áudio nativos e pacote After Effects foram criados; abertura em Adobe não verificada |
| Parâmetros não padrão, equivalência visual WebGL e desempenho de cada shader em 4K | Evidência adicional **incompleta** | Prova GL cobre parâmetros/amostras registrados; perfis 4K do pipeline não provam desempenho ou qualidade de todas as combinações |
| APIs, modelos locais, serviços remotos, publicação e sintaxes específicas de outras engines | Excluídos da integração operacional | Não cabem no Flow pelo Chrome/Tesseract fixado ou não têm compatibilidade confirmada; conceitos editoriais gerais foram consolidados nos guias |

Esses itens permanecem identificados, sem virar recursos habilitados por analogia. Os 125 portes GL e as dez receitas habilitadas têm prova de funcionamento; a cobertura documental integral não implica execução automática de toda variante editorial das fontes.

## Estado preservado

**Zero gerações, zero créditos Flow e nenhuma nova aprovação de mídia de produção.** Telemetria permanece desativada, executáveis/perfis fixados e versões anteriores/pacotes Adobe preservados. Não houve instalação global, publicação ou criação de piloto. O repositório principal continua no checkout original `codex/claudia-wiki`, sem commit inicial; os arquivos foram mantidos no workspace, sem criar commit que incluísse toda a base preexistente.

Para repetir a verificação, use Python 3.12 já instalado:

```powershell
& .\scripts\check.ps1 -Python '<caminho-do-python-3.12.exe>'
python scripts/technique_coverage.py --report reports/incorporation-coverage.json
# Provas explícitas: somente fixtures temporárias, nunca mídia de produção.
python scripts/smoke_techniques.py --keep-temporary
python scripts/smoke_technique_pipeline.py --keep-temporary
python scripts/smoke_tesseract.py --keep-temporary --report reports/tesseract-smoke-incorporation.json
```

Os comandos GL e a política de republicação após alteração estão no [README da biblioteca](../resources/gl-transitions/README.md). Nenhum desses checks autoriza o botão Gerar ou aprova uma montagem real.
