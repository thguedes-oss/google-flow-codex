# Revisão e medição

Reproduza o clipe completo com áudio. Pause no início, no meio e no fim; inspecione os intervalos onde rosto, mãos ou objetos se movem. Compare com os arquivos canônicos aprovados e com a cena anterior, incluindo a emenda em reprodução contínua.

Confira também o brief e a [direção do plano](direcao.md). Avalie se a função, a ação/resultado, a câmera e os gráficos planejados aparecem no resultado, mesmo quando o prompt foi cumprido literalmente. Preserve as expectativas planejadas ao registrar defeitos.

Use o editorial da [direção contextual](direcao-contextual.md) para separar escolha planejada do Codex, observação real e decisão de aprovação. Reavalie a utilidade de efeitos, cortes, gráficos e som no resultado e nas cenas vizinhas; inclusive a decisão de não usar efeito. Mudança de montagem pode atender a intenção em outra versão, mas não deve esconder defeito de identidade/física nem reescrever o esperado da tentativa. Previews e justificativas não dispensam os critérios e o fechamento formal abaixo.

| Critério | O que conferir | Defeito a registrar |
|---|---|---|
| Rosto e cabelo | Identidade, formato, idade aparente, cabelo e detalhes | `face`, `hair` |
| Roupa | Peças, cores, cortes e acessórios | `wardrobe` |
| Cenário | Posição relativa de janela, planta, mesa e parede; luz | `set`, `lighting` |
| Objetos | Forma, cor, contagem, mão, posição e orientação | `prop`, `hands` |
| Ação | Ordem, causalidade, movimento possível e ausência de ações extras | `action`, `physics` |
| Texto e áudio | Texto solicitado/indesejado, vozes, sincronização, ruído | `text`, `audio` |
| Passagem | Estado final/inicial, eixo, direção do olhar, ritmo do corte | `handoff` |

Para cada critério aplicável, registre `0` (sem defeito observado), `1` (pequeno defeito aceitável conforme o brief) ou `2` (rejeitar). Use `NA` com justificativa quando não se aplicar. Um rosto diferente, roupa trocada, objeto mudando de mão sem ação ou geometria incompatível exige rejeição. Não compense um problema de identidade com qualidade estética.

`review.csv` usa uma linha por critério e tentativa: inclua timestamps/frames examinados, observação e decisão. Se ainda não houver vídeo, o arquivo permanece apenas com cabeçalho.

## Evidências locais com FFmpeg

Pré-requisitos: Python 3.12, FFmpeg e FFprobe no PATH; projeto dentro de `projects/`; ID de tentativa único, até 80 letras sem acentos, números, `_` ou `-`; status `completed`; `scene_id` correspondente ao manifesto; `output_file` relativo, existente dentro de `outputs/`. Estados `pending`, `failed` e `unknown` devem ser reconciliados antes deste procedimento. A ferramenta aceita somente arquivos locais; não baixa mídia ou acessa serviços.

```powershell
# Use o mesmo executável Python 3.12 mostrado por scripts/check.ps1.
& 'C:\caminho\python.exe' scripts/review_clip.py --project projects/meu-video --attempt tentativa-001
```

O processo lê os frames decodificados do primeiro stream de vídeo que não seja imagem de capa. Seleciona o primeiro e o último frames exatos e os mais próximos de 25%, 50% e 75% do intervalo entre seus timestamps. Não calcula o último frame subtraindo um FPS estimado da duração. Em taxa variável, os índices intermediários podem ser diferentes das frações da contagem total. Amostras repetidas são deduplicadas; um vídeo de um frame terá uma imagem.

Cada execução usa uma pasta nova em `outputs/review/ID/` e produz:

- `frame-NNNNNN.png`: frames em resolução decodificada, com a orientação aplicada pelo FFmpeg; índice começando em zero.
- `contact-sheet.png`: miniaturas da esquerda para a direita, em ordem cronológica, sem distorcer proporções. A prancha não é referência canônica nem deve ser anexada inteira como frame inicial.
- `review.json`: hash do vídeo e dos PNGs, metadados de vídeo/áudio, índices, timestamps absolutos e relativos, percentuais associados, tentativa, cena, estados esperados e `expected_direction` (ou `null`). Os nomes em `samples` correspondem à ordem da prancha; timestamps não são impressos sobre as imagens.

Use `first_frame` e `last_frame` do JSON para localizar as imagens de ponta. Compare-as com as referências aprovadas e com as fichas; reproduza também o vídeo completo com áudio, incluindo movimentos entre as amostras e a emenda com a cena anterior. A extração registra áudio nos metadados, mas não o escuta nem o aprova. Preencha `review.csv` manualmente com evidências e decisão.

Um frame final extraído continua sendo evidência pendente até o clipe passar na revisão visual. Para continuação, depois da aprovação, registre uma cópia desse PNG como ativo de passagem, com caminho, versão e SHA-256 próprios, e confira o slot inicial no Flow. Não use a prancha ou um clipe defeituoso como fonte de identidade.

O utilitário não escreve em `project.json`, `attempts.csv` ou `review.csv`, não altera o vídeo e não aprova referências ou gastos. Se o arquivo original mudar durante o processo, a execução falha. Erros após criar a pasta deixam `failure.json` e eventuais PNGs parciais; eles não constituem uma revisão concluída. Novas execuções preservam a pasta anterior.

Sem um vídeo real, mantenha os registros apenas com cabeçalhos. Os testes usam exclusivamente fixtures técnicas em diretórios temporários, sem aprovação visual nem crédito do Flow.

## Revisão ampliada

Acrescente `--enhanced` ao comando de extração. O comportamento sem essa opção continua sendo as cinco amostras originais. O modo ampliado mantém esses pontos e acrescenta momentos de `scenes[].review_plan` e eventos técnicos, deduplicados por índice de frame, com máximo de 25 PNGs. Primeiro entram os pontos básicos, depois os momentos planejados na ordem do arquivo, depois os eventos cronológicos. Excedentes são contados no relatório. A prancha cresce em linhas de até cinco imagens.

Use `templates/plano-revisao.json`: `schema_version: 1`, `moments` como lista de objetos, `seconds` numérico finito não negativo e `expected` textual não vazio. `criterion` é opcional para compatibilidade; quando informado, deve ser um dos 12 critérios de revisão. O preflight valida esses campos antes da produção; valores booleanos não são timestamps. Planos antigos podem continuar sem direção ou sem critério por momento.

O instante é relativo ao primeiro frame decodificado; seleciona-se o frame mais próximo. Um momento fora do trecho disponível aproxima-se da ponta, sem inventar frames. No modo ampliado, `planned_moment_warnings` registra os instantes que excedem a duração efetiva, a duração disponível e `sampling: nearest_endpoint`. Compare também duração e ação solicitadas com o resultado real.

O mesmo plano aceita `direction` opcional com quatro textos não vazios: `purpose`, `action_result`, `camera_intent` e `graphics_intent`. O relatório inclui essa direção mesmo sem `--enhanced`, usando a cópia congelada quando existir. Alterações posteriores no plano atual não mudam a direção da tentativa anterior. Registros antigos sem esse objeto permanecem compatíveis; veja [o contrato](direcao.md#plano-de-revisão-e-contrato-aditivo).

Detectores usam `scdet=threshold=10`, `blackdetect=d=2:pix_th=0.10:pic_th=0.98`, `freezedetect=n=-60dB:d=2` e `silencedetect=n=-60dB:d=2`. Parâmetros e eventos são gravados no JSON. Silêncio é analisado na primeira trilha de áudio; sem trilha, não há essa análise. Eventos menores que os limiares podem passar despercebidos. Preto, silêncio e imobilidade podem ser intencionais: alertas não são decisões de rejeição. A inspeção completa de todas as trilhas relevantes continua sendo responsabilidade da revisão.

## Fechamento explícito e versionado

Faça três passagens: identidade/composição; ação/continuidade; áudio/intenção narrativa. Use os 12 critérios `face`, `hair`, `wardrobe`, `set`, `lighting`, `prop`, `hands`, `action`, `physics`, `text`, `audio` e `handoff`. `NA` precisa de justificativa na observação; uma passagem inexistente pode ser NA. Cada linha informa severity, timestamps e observation.

Preencha `templates/fechamento-revisao.json` com a decisão real. `evidence_report` aponta para o `review.json` relativo ao projeto. `criteria` contém objetos com `criterion`, `severity`, `timestamps` e `observation`. `reviewer` identifica o responsável. `playback_completed` e `audio_review` registram o que foi realmente inspecionado. Áudio existente exige `reviewed`; vídeo sem áudio exige `not_applicable` e `audio_reason`.

Quando as evidências contiverem `expected_direction`, preencha `intent_review` com a observação real sobre o propósito e o resultado, tanto para aprovação como rejeição. Defeitos continuam nos critérios/timestamps existentes. Campos obrigatórios exigem texto, não somente espaços. Não há julgamento narrativo automático: a ferramenta verifica preenchimento e integridade; a revisão humana continua responsável pela decisão. Evidências antigas sem direção não exigem `intent_review`.

Execute `scripts/flow_review.py close --project projects/meu-video --attempt ID --input projects/meu-video/fechamento.json`. Aprovação exige todos os critérios, nenhum 2 e reprodução completa. Rejeição pode registrar os defeitos já suficientes para interromper a aprovação. `selected: true` é a escolha para montagem/contagem de segundos e só vale para aprovação; não é inferida automaticamente.

O comando acrescenta observações ao CSV existente e cria decisão e selo em pasta nova. A primeira revisão usa `supersedes: null`; uma correção informa o `decision_id` atual. A revisão antiga fica preservada e deixa de valer para liberar continuação. Não edite fechamentos anteriores nem suas linhas no CSV. Registros interrompidos precisam de reconciliação, não repetição cega.

Use `scripts/flow_review.py verify --project projects/meu-video --decision outputs/decisions/ID/REVISAO/decision.json` para verificar o vínculo com vídeo, relatório, PNGs, prancha e observações. Os dados são declarações do responsável: a ferramenta não prova que alguém reproduziu ou aprovou de fato. Para continuação, siga também [continuidade](continuidade.md).

Use `scripts/flow_review.py audit --project projects/meu-video` para conferir o histórico completo de geração e revisão de clipes, incluindo pacotes parciais, locks e decisões substituídas. A auditoria apenas lê e relata; veja [manutenção e recuperação](manutencao.md). Quando existe pacote de congelamento, a revisão usa seu manifesto verificado antes do atual; um pacote parcial ou adulterado não permite fallback para registros antigos.

## Comparar resultados

Para avaliar eficácia, compare execuções equivalentes do mesmo brief/modelo: taxa de clipes aprovados na primeira tentativa, defeitos por categoria e créditos por segundo aprovado. Mantenha prompts, referências e decisões. Registre tentativas falhas, inclusive gastos sem resultado. Uma avaliação manual pequena é evidência limitada; não é prova geral de redução de alucinações.
