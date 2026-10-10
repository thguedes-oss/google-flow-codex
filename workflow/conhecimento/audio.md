<a id="audio-inteligibilidade-presenca-e-sincronizacao"></a>

# Áudio: inteligibilidade, presença e sincronização

Planeje fala, ambiente, sons de ação, música e silêncio com funções distintas. Use [geração](geracao-flow.md) para áudio nativo confirmado no Flow e [pós-produção](../pos-producao.md) para recursos locais aprovados. Tesseract não gera voz, música ou transcrição. Não invoque TTS, lipsync, WhisperX, bancos ou serviços por efeito deste guia.

<a id="fala-e-edicao"></a>

## Fala e edição

Leia o roteiro no idioma solicitado, confira pronúncia e tempo de leitura. Identifique emissor, palavras exatas, desempenho pretendido e se há rosto falando. Prefira fala principal clara; turnos exigem revisar boca, voz e personagem. Confira depois as palavras realmente ouvidas, omissões, invenções e idioma. Roteiro é intenção, não transcrição do resultado.

Preserve palavras, respirações necessárias e contexto. J-cut começa som seguinte antes da mudança visual; L-cut mantém anterior depois. Defina intervalos de imagem/som separadamente com origem e ganho, sem duplicar fala em camadas. Examine clicks, timbre, corte de palavra e sincronismo. Emenda não torna fala defeituosa aceitável automaticamente.

<a id="ambiente-foley-e-silencio"></a>

## Ambiente, Foley e silêncio

Ambiente corresponde a lugar/momento; som de ação corresponde a causa, material, distância e instante. Um toque de caneca não pode soar antes do contato sem intenção explícita. Saltos de ruído/reverberação denunciam quebra entre imagens semelhantes. Fundo contínuo usa material aprovado, sem extrair/criar som por conta própria.

Silêncio pode preparar compreensão ou fecho. Ausência de música difere de ausência de todo som: registre ambiente remanescente. Não cubra cada pausa com impacto/whoosh; som precisa de função.

<a id="musica-e-medidas"></a>

## Música e medidas

Escolha função, seção, energia e direitos da faixa. Letra compete com narração; instrumental pode favorecer compreensão. Reduza música/efeitos quando mascaram fala e escute em volume moderado e alto-falante pequeno. `volume` do plano é ganho linear: não é dB nem LUFS.

LUFS descreve loudness; pico/true peak trata amplitude; dinâmica descreve variação. Tabelas de plataformas nas fontes são datadas, não padrões atuais de entrega. Registre meta confirmada no brief e medição real; ausência de medida permanece desconhecida. Evite clipping/bombeamento. EQ, compressão, limiter, ducking e envelopes só são executados quando esquema fixado e evidência de teste confirmarem; receitas de outro motor não provam suporte nativo.

## Envelope nativo de ganho

`native.audio-gain` atua na camada `audio:N` existente, sem duplicar áudio. `from_gain` e `to_gain` são ganhos finais lineares entre 0 e 4, com pelo menos dois frames na janela selecionada. O ganho planejado originalmente é restaurado fora dela. A rampa não muda palavras, origem, posição ou duração da faixa. Confira clicks, clipping, inteligibilidade e níveis antes/durante/depois. O exemplo e contrato estão na [ficha](../tecnicas.md#nativeaudio-gain); nenhum marcador aplica essa rampa automaticamente.

<a id="extracao-local-de-candidatos"></a>

## Extração local de candidatos

Para um recurso de áudio aprovado e usado em exatamente uma camada do plano validável, execute com Python 3.12 já disponível:

```powershell
python -X utf8 scripts/audio_markers.py --project projects/meu-video --plan postproduction.json --resource trilha --output reports/postproduction/audio-markers/candidatos-v1.json
```

`--resource` é o ID do recurso, não `audio:0`. A saída é nova e relativa à pasta do vídeo; não sobrescreve relatório existente. Opções: `--sample-rate` 8000/16000, `--hop-ms` 10–20, `--sensitivity` positivo (multiplicador da média RMS) e `--min-distance-ms` positivo. Consulte `--help`. São parâmetros de extração, sem alegação de sensibilidade musical universal.

O relatório `audio_energy_candidates` registra plano/hash, recurso/camada, origem/hash antes/depois, entrada/saída da origem, posição na timeline, parâmetros e `markers`. Cada candidato `energy_peak_candidate` contém `source_ms`, `timeline_ms`, RMS e `confirmed: false`; o relatório mantém `timeline_modified: false`. Escute os eventos antes de propor cortes ou entradas visuais. O extrator não detecta batida/melodia/percussão nem autoriza alteração editorial; não instala BeatCut, Librosa ou modelos.

<a id="marcadores-e-legendas"></a>

## Marcadores e legendas

Batida, percussão, ataque melódico e energia são categorias diferentes. Um marcador orienta composição sem autorizar alterar áudio, corte ou duração da fonte. Confira evento ouvido no arquivo/hash correto, timestamp/frame e motivo. Fecho tem cauda ou término deliberado, sem frase truncada.

Legenda exige palavras/tempos conferidos no áudio real e `transcript_evidence`. Quebre por sentido e confira acentos, nomes, emissor, leitura e sons relevantes. Sincronização palavra a palavra não dispensa revisão. [Gráficos](graficos.md) trata posição e contraste.

Técnicas: [prompt.audio](../tecnicas.md#promptaudio), [audio.mix](../tecnicas.md#audiomix), [audio.markers](../tecnicas.md#audiomarkers), [edit.jl](../tecnicas.md#editjl), [graphic.caption](../tecnicas.md#graphiccaption).

Fontes: OpenMontage `skills/creative/sound-design.md`, `video-editing.md`, `skills/core/subtitle-sync.md`, `skills/meta/voice-performance-director.md`; BeatCut `docs/plans/2026-03-04-sync-mode-design.md`; Square-Zero `video-prompting/references/models/veo3/prompting.md`. [Cobertura](../../reports/knowledge-coverage.md).
