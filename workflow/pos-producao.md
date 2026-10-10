# Pós-produção local com Tesseract

Peça pelo chat: **“Monte os clipes aprovados do projeto [nome] no Tesseract, acrescente [textos/áudio/marca] e apresente uma prévia.”** O Codex lê o brief, as revisões e este procedimento, monta, inspeciona, ajusta e entrega o vídeo e a fonte editável. Você não precisa operar um editor. Para uma capa: **“Crie uma capa editável com os materiais aprovados desse vídeo.”**

Se o pedido já abrange o vídeo final, a [direção contextual](direcao-contextual.md) conduz também esta etapa dentro do escopo autorizado, quando as fontes forem elegíveis. O Codex escolhe os cortes, som, gráficos e efeitos, preenche o plano técnico e apresenta as escolhas relevantes e a prévia. O usuário pode pedir mudanças pela intenção, sem fornecer IDs, frames ou outro comando para cada etapa. Aprovações dos materiais e da montagem continuam reais e separadas.

O fluxo passa a ser **referências → Flow pelo Chrome → revisão dos clipes → Tesseract local → revisão da montagem → entrega**. Tesseract não gera filmagens, personagens, avatares, vozes ou transcrições. Um clipe do Flow continua sendo uma imagem em movimento, sem separar automaticamente rosto, cenário e objetos em camadas.

Planeje a montagem junto com a [direção dos planos](direcao.md): função de cada trecho, ritmo, som, textos/gráficos úteis e quadro final. Reserve composição legível e escolha cor/textura a partir de decisões reais. Com materiais aprovados e dentro do trabalho autorizado, um animatic ou uma prévia curta de trecho representativo ajuda a conferir essas escolhas antes da montagem completa. Cada prévia mantém seus próprios registros; preparar ou renderizar não aprova o resultado nem autoriza novas gerações.

## Ferramentas isoladas e diagnóstico

Use Python 3.12 encontrado por `scripts/check.ps1`. Nos exemplos abaixo, `python` representa esse executável, com UTF-8 ativado. A configuração `config/tesseract.json` fixa o motor 0.3.1 e o conversor 0.2.1. Binários, licenças, arquivos de distribuição e checksums ficam em `.work/tesseract/`, ignorada pelo Git. Não execute os instaladores globais da distribuição. O executável 0.2.0, o PATH e as skills avulsas existentes permanecem intactos.

```powershell
python -X utf8 scripts/tesseract_tools.py doctor
# Apenas instalação explícita faz downloads; versão existente é verificada, não sobrescrita.
python -X utf8 scripts/tesseract_tools.py install --tool all
```

A instalação compara os arquivos `.sha256` oficiais com os hashes fixados, extrai em uma pasta nova, verifica versão e sela os arquivos. Falhas deixam diagnóstico em pasta separada e não publicam uma instalação válida. Não há fallback para outro motor ou versão. Nunca contorne SmartScreen. A telemetria permanece desativada; o motor de produção recusa operar se estiver habilitada.

Consulte as skills **tesseract:tesseract-video**, **tesseract:tesseract-motion** e **tesseract:tesseract-design** do plugin 0.3.1. Evite misturar suas instruções com as skills avulsas 0.2.0. Os esquemas retornados pelo executável fixado e a saída real prevalecem sobre exemplos antigos, inclusive exemplos de `activeRange`: Video e Audio nesta versão usam `playback`, enquanto Image e Text usam `activeRange`.

## Plano separado da geração

Copie `templates/postproduction.json` para a pasta do vídeo. O exemplo contém apenas um plano pendente, sem materiais fictícios. `kind` é `edit`, `animatic` ou `design`; `title` identifica o trabalho. Nenhum comando altera o manifesto de geração, o orçamento, os CSVs ou decisões dos clipes.

- `delivery`: `width`, `height`, `duration_ms`; para vídeo também `resolution`, `fps` e `audio_expected`. As unidades temporais do plano são inteiros em milissegundos. Vídeos aceitam 16:9, 9:16 ou 1:1; peças estáticas aceitam canvas personalizado dentro dos limites do motor.
- `clips`: cada entrada usa `attempt_id`, `in_ms`, `out_ms` e `at_ms`; `volume` é ganho linear, padrão 1. A seleção depende de tentativa completed, decisão formal aprovada vigente, evidências íntegras e hash correspondente. A coluna `decision` do CSV sozinha não basta. Uma aprovação substituída invalida uma revisão preparada, mesmo se a nova decisão também aprovar o clipe.
- `resources`: arquivos locais com `id`, `kind` (`image`, `audio` ou `font`), `path` relativo ao vídeo, `sha256` e `origin`. Imagem e áudio exigem `approval` real com `approved`, `reviewer`, `at` e `evidence`. Fonte exige `license` e TTF/OTF/TTC existente; não procure uma fonte parecida para substituir silenciosamente a solicitada.
- `images`: `resource` de imagem ou `handle` aprovado do manifesto, `at_ms`, `duration_ms` e `fit` (`contain` ou `cover`). Podem formar um animatic de imagens aprovadas ou peças de design. Um animatic continua sendo prévia de ritmo, sem comprovar atuação ou continuidade de uma cena gerada.
- `texts`: `text`, `font` (ID do recurso), `position: [x,y]`, `box: [largura,altura]`, `font_size`, `at_ms` e `duration_ms`. Opções: `color` RGBA de 0 a 1, `align` e `fade_ms`. `role` é `title`, `label` ou `caption`. Legenda exige `transcript_evidence` com a origem real das palavras e dos tempos; o programa não transcreve.
- `rectangles`: `name`, `position`, `size`, `color`, `at_ms`, `duration_ms` e `fade_ms` opcional. São formas editáveis para fundos, destaques e diagramas.
- `audio`: `resource` de áudio, `in_ms`, `out_ms`, `at_ms` e `volume`. Preserve diálogo e som útil; evite reproduzir a mesma fala em duas camadas. Envelopes e efeitos adicionais podem ser feitos por ações nativas conferidas no esquema.
- `native_actions`: ações da API nativa para refinamentos, máscaras, animações e ajustes suportados. O Codex consulta os esquemas salvos na revisão; não inventa propriedades ou formatos. Ações não importam arquivos arbitrários nem substituem a declaração dos recursos.

Exemplo de corte **somente após existir uma tentativa realmente aprovada**: `{"attempt_id":"tentativa-001","in_ms":1000,"out_ms":6500,"at_ms":0,"volume":1}`. Isso seleciona 5,5 segundos da origem e coloca o trecho no início da montagem. Para fontes TTC, use `font_family` e `font_style` obtidos da importação quando houver várias faces.

Não fixe uma estética para todos os vídeos. Extraia marca e tipografia do brief e dos materiais aprovados; preserve UTF-8, acentos e glifos. Uma imagem de identidade permanece canônica; recortes e composições são derivados, não substituições automáticas da biblioteca.

<a id="tecnicas-em-janelas-existentes"></a>

## Técnicas em janelas existentes

Os guias de [montagem](conhecimento/montagem.md), [áudio](conhecimento/audio.md) e [gráficos](conhecimento/graficos.md) explicam finalidade e revisão; as [32 fichas](tecnicas.md), o [catálogo nativo](../resources/techniques/catalog.json) e o [catálogo GL](../resources/gl-transitions/catalog.json) descrevem IDs/parâmetros. Para planejar antes: [pré-produção](conhecimento/pre-producao.md), [direção](conhecimento/direcao.md), [geração](conhecimento/geracao-flow.md), [continuidade](conhecimento/continuidade.md) e [revisão](conhecimento/revisao.md).

`techniques` é uma lista opcional no plano, com `id`, `sources`, `start_frame`, `duration_frames` e `params`. Os frames usam FPS da entrega, enquanto seleção e posição de materiais continuam em milissegundos. Omitir técnicas conserva o fluxo anterior. Peça a alteração pelo propósito — por exemplo, entrada discreta de título ou comparação lado a lado — e confira uma prévia; não é necessário operar propriedades internas do motor.

A seleção parte da função da cena, ação, composição, cenas vizinhas, áudio, legibilidade e fontes reais; o Codex registra técnica ou **sem efeito** e seu motivo no editorial. Antes da preparação, confira catálogo/evidência atual, fontes e intervalos, parâmetros, transparência, proporção e conflitos. Se não couber, escolha outra solução que preserve a função ou deixe a necessidade pendente, com explicação; não aplique um fallback silencioso. O planejamento pode decidir novas seleções/sobreposições explicitamente, mas o compilador não as cria por conta própria.

Exemplo estrutural de flash branco por **dois frames a 24 fps**, aproximadamente 83,3 ms, começando em 500 ms:

```json
{"id":"native.flash","sources":[],"start_frame":12,"duration_frames":2,"params":{"color":[1,1,1,1]}}
```

Não aplicar o exemplo sem motivo e revisão de conforto/legibilidade. O flash não muda corte, áudio ou duração. A janela precisa caber na entrega; um plano estático `kind: design` não aceita técnicas em frames. Vídeo exige FPS 24, 30 ou 60.

Exemplo de dissolução GL, **somente após existirem duas tentativas realmente aprovadas e o ID estar habilitado com evidência**. O trecho selecionado de A cobre 0–4000 ms da montagem; B cobre 3000–7000 ms. A sobreposição 3000–4000 ms é uma decisão explícita do plano, não extensão criada pelo efeito:

```json
{
  "clips": [
    {"attempt_id":"tentativa-A-aprovada","in_ms":1000,"out_ms":5000,"at_ms":0,"volume":1},
    {"attempt_id":"tentativa-B-aprovada","in_ms":2000,"out_ms":6000,"at_ms":3000,"volume":1}
  ],
  "techniques": [
    {"id":"gl.fade","sources":["clip:0","clip:1"],"start_frame":72,"duration_frames":24,"params":{}}
  ]
}
```

É um fragmento de plano para entrega a 24 fps e pelo menos 7000 ms, não um projeto executável nem aprovação fictícia. Confira se as durações reais de A/B abrangem as seleções. O som dos clipes segue os ganhos e sobreposição explicitamente planejados; `gl.fade` é visual, não cria crossfade de áudio. Quando a sobreposição sonora não for desejada, a mudança de ganho/seleção de áudio precisa de decisão própria. O efeito usa somente a janela comum existente, sem ampliar origem ou deslocar cortes.

`gl.luma`/`gl.displacement` exigem terceira fonte visual de mapa, nomeada conforme `texture_inputs` do catálogo; o mapa é recurso real aprovado. Uma imagem de mapa fica ativa somente durante a janela do efeito. Demais IDs seguem a contagem declarada. Não presumir disponibilidade pela existência de shader: confira status e relatório de smoke por formato; não extrapole landscape para portrait/square.

Transform/reframe/overlay usam escala relativa ao tamanho já ajustado ao canvas (`[100,100]` mantém) e deslocamento relativo à posição planejada. Não são coordenadas/tamanhos absolutos. `native.audio-gain` usa `sources: ["audio:0"]`, `from_gain`/`to_gain` finais lineares de 0 a 4 e pelo menos dois frames; não duplica camada e restaura ganho original fora da janela. Veja [extração de candidatos de energia](conhecimento/audio.md#extracao-local-de-candidatos): o relatório sugere pontos para escuta, sem editar timeline.

O validador rejeita `native_actions` e `techniques` simultâneos, `fade_ms` na fonte que recebe técnica e técnicas sobrepostas na mesma fonte. Resolva conflitos em revisão separada, sem aceitar silenciosamente a última ação. Animações GL, fade, transform, reveals e ganho exigem pelo menos dois frames. A revisão congela receita, catálogos e shaders usados com hashes; mudar implementação requer nova preparação. Fontes continuam exigindo aprovação formal vigente, hash e estado completed.

## Preparação, prévia e render

```powershell
python -X utf8 scripts/tesseract_pipeline.py validate --project projects/meu-video --plan postproduction.json
python -X utf8 scripts/tesseract_pipeline.py prepare --project projects/meu-video --plan postproduction.json --revision montagem-v1
python -X utf8 scripts/tesseract_pipeline.py preview --project projects/meu-video --revision montagem-v1
python -X utf8 scripts/tesseract_pipeline.py render --project projects/meu-video --revision montagem-v1
```

Diagnóstico e validação apenas leem. Preparação cria uma pasta nova em `outputs/postproduction/REVISAO/`, importa os bytes, constrói uma composição nativa e salva `Project.tsrct`, plano congelado, ações, esquemas, inspeção e hashes. `layers[0]` é a frente. Cortes selecionam `sourceRange` independentemente da posição no tempo. Textos, formas, imagens e áudio permanecem separados e editáveis.

Prévias e renders ficam em subpastas novas dentro da revisão. Um render inclui PNG, filmstrip, MP4 e relatório; `design` entrega PNG e fonte editável, sem exportar vídeo. O programa confere metadados e decodificação; revisão visual e escuta continuam pendentes. Os esquemas e logs são arquivos de trabalho, não entregáveis de marca. O relatório geral de `check.ps1` mostra prontidão de pós-produção separada: um plano pendente não invalida o planejamento das cenas.

Para refinar, altere o plano/ações e prepare **outra revisão**. Não modifique uma fonte selada e depois apresente a exportação antiga como correspondente. Nenhuma revisão ou execução anterior é sobrescrita. Mídia ausente, alteração de aprovação ou falha deixam a saída parcial e `failure.json`; não há aprovação ou sucesso parcial automático. No motor 0.3.1, a posição da montagem também precisa estar em `playback.mapping.input.start`, e o início da origem em `playback.mapping.output.start`: apenas preencher `sourceRange.start` não selecionou o trecho no teste real. A integração preenche esses relógios e compara frames dos dois lados do corte no teste técnico.

### Resolução observada nesta versão

No Windows, os rótulos da CLI 0.3.1 escalam o canvas em vez de impor uma resolução absoluta. O mesmo canvas 1280×720 produziu 852×480 com `720p`, 1280×720 com `1080p` e 2560×1440 com `4k`; um canvas 1920×1080 com `4k` produziu 3840×2160. Mudar apenas o encoder não corrigiu a diferença. A integração usa o argumento `1080p` para preservar o canvas escolhido no plano e confere cada arquivo:

- Entrega 720p: canvas 1280×720, 720×1280 ou 720×720.
- Entrega 1080p: canvas 1920×1080, 1080×1920 ou 1080×1080.
- Entrega 4K: canvas 3840×2160, 2160×3840 ou 2160×2160. Confira os formatos efetivamente exercitados no relatório técnico; não deduza suporte apenas pelo rótulo da CLI.

Os perfis ficam na configuração e nos relatórios de render. Se a saída nativa divergir do perfil ou das dimensões planejadas, a execução falha; não redimensiona a exportação para esconder o problema. Dimensões de saída não inventam detalhe ou movimento ausentes nas fontes. Reveja esses perfis ao trocar de motor, sem atualizar a versão automaticamente.

## Revisão e entrega

Abra e inspecione PNGs e filmstrip; reproduza o vídeo completo com áudio. Avalie ritmo, emendas, cortes de fala, identidade, enquadramento, legibilidade, glifos, gráficos, volumes e quadro final. A inspeção técnica não equivale a escuta ou reprodução. Use `templates/revisao-montagem.json` com observações reais:

Confronte a montagem também com o brief, as decisões por cena e a função dos planos. Gráficos devem ajudar a mensagem e permanecer legíveis no destino final; movimento e cortes precisam servir ao conteúdo. Não imponha cortes na batida, porcentagem de presença de personagem ou uma estética musical a todo vídeo. Os campos textuais obrigatórios do fechamento não aceitam apenas espaços.

Registre quais escolhas editoriais ainda ajudam após observar o material real e quais foram revistas. Pedidos como “mais sóbrio” ou “mais dinâmico” viram alterações concretas pelo Codex, preservando compreensão, fala, identidade e versões anteriores. A explicação e a prévia não constituem aprovação formal; use o procedimento de [ajustes contextuais](direcao-contextual.md#material-real-prévias-e-ajustes).

```powershell
python -X utf8 scripts/tesseract_pipeline.py review --project projects/meu-video --revision montagem-v1 --run ID_DO_RENDER --input revisao-montagem.json
```

Uma aprovação de vídeo exige render completo, inspeção visual, reprodução e escuta do áudio existente. Uma peça estática exige inspeção visual; ausência de áudio deve ter justificativa. A decisão é versionada e ligada aos hashes do render e da montagem, sem aprovar novamente os clipes ou alterar a biblioteca. Entregue a exportação, o `.tsrct`, a prévia útil e as limitações reais no chat.

## Adobe opcional

```powershell
python -X utf8 scripts/tesseract_pipeline.py convert --project projects/meu-video --revision montagem-v1 --target premiere
python -X utf8 scripts/tesseract_pipeline.py convert --project projects/meu-video --revision montagem-v1 --target after-effects
```

Cada conversão cria outra pasta com o pacote completo, assets, projeto, logs e avisos. Os formatos têm suporte parcial; exportação AEP é experimental. Premiere pode incluir AEPs relacionados e precisar dos dois aplicativos. Não recortar o pacote ou descartar avisos. Sem inspeção no Adobe, o relatório usa `converted_adobe_unverified`, nunca “compatibilidade confirmada”.

No teste Windows com estas versões, o pacote After Effects com textos e formas foi criado, assim como o Premiere de cortes e áudio. A conversão híbrida para Premiere falhou ao validar `media/ae-0001/compositions.aep` como caminho portátil. Repetir com caminhos de entrada/saída sem acentos também falhou. Esse caso permanece uma falha do teste, com logs preservados; o fluxo pelo Codex continua usando a fonte nativa e o vídeo renderizado. Não descartar gráficos ou alterar metadados de versão silenciosamente para produzir um pacote diferente.

## Teste técnico e custos

`scripts/check.ps1` executa os testes de contratos locais sem renderizar automaticamente. O teste nativo completo é explícito:

```powershell
python -X utf8 scripts/smoke_tesseract.py
```

Ele usa mídia sintética em diretório temporário, sem registrar fixtures no projeto real ou na biblioteca. Gera um relatório técnico, não um piloto. `--keep-temporary` preserva a pasta temporária somente para inspeção dos testes. Os resultados reais e limitações ficam em `reports/tesseract-smoke.json`.

O teste confere seleção de origem e posição dos cortes contra frames codificados, pico de áudio, aparição de um título animado, PNG estático, reabertura e dimensões/FPS/duração/decodificação dos vídeos. Os pacotes Adobe são verificados estruturalmente. Uma limitação conhecida da conversão híbrida para Premiere produz `passed_with_limitations` no teste geral e continua registrada como **falha de conversão**, sem declarar seu pacote concluído. Falhas inesperadas encerram o teste com erro. Escuta, reprodução completa e fidelidade no Adobe não são inferidas dessas medições.

Montagem local não consome créditos de geração do Flow. Custos do agente, armazenamento e execução são separados; imagens geradas pelo Codex continuam seguindo seu próprio pedido e limite. Esta integração não autoriza produção no Flow ou geração de novas imagens.

Fontes: [Tesseract 0.3.1](https://github.com/mirage-hq/Tesseract/releases/tag/v0.3.1), [conversor 0.2.1](https://github.com/mirage-hq/Tesseract-Converter/releases/tag/v0.2.1), [compatibilidade Adobe](https://github.com/mirage-hq/Tesseract-Converter/blob/main/docs/formats/README.md).
