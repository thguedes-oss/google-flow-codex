<a id="geracao-no-flow-tentativa-verificavel"></a>

# Geração no Flow: tentativa verificável

A base mantém zero créditos autorizados. Preparar prompts e inspecionar controles não permite gerar. Use [operação](../operacao.md), [capacidades](../capacidades.md), configuração local e documentação oficial atual antes do envio autorizado. API e outros modelos nas fontes não descrevem automaticamente o Flow.

<a id="prompt-autossuficiente"></a>

## Prompt autossuficiente

Reúna enquadramento/câmera, sujeito/identidade observada, ação, contexto, luz/estilo e áudio. Nomeie cena e handles conforme formato local; não escreva apenas “igual à anterior”. Em imagem para vídeo, a imagem ancora composição/identidade; priorize o que muda, conservando âncoras necessárias ao contrato local. Não invente detalhes invisíveis ou incompatíveis com a escala.

Descreva começo e resultado: mão direita alcança alça, dedos fecham, caneca permanece apoiada. Identifique objeto, posição, quantidade e orientação. Evite transformações, troca de roupa, órbita e falas simultâneas desnecessárias. Exclua concretamente: ambiente vazio com uma mesa e uma caneca, sem pessoas adicionais. “Qualidade perfeita” não é condição observável.

Beats cobrem a duração sem lacunas/sobreposição, usando `--beat-mode coverage`; um intervalo pode abranger vários segundos. Tempos são intenção, sem garantia de sincronização. Modelo, modo, resolução, proporção e quantidade são configurações externas; preserve os campos de especificação exigidos pelo linter local. A preferência Square-Zero por linha única não prevalece sobre o contrato estruturado deste projeto.

<a id="audio-fala-e-escrita"></a>

## Áudio, fala e escrita

Declare ambiente, efeitos de ação, música prevista e fala ou sua ausência. Identifique emissor, idioma e palavras exatas entre aspas. Preserve português solicitado mesmo quando o restante estiver em inglês. Narração sobre imagem difere de pessoa falando no quadro. Boca, turno de falantes e palavras requerem inspeção e escuta. Não peça áudio nativo em modo sem suporte confirmado na UI. Se o som for montado depois, registre decisão e recurso real aprovado.

Título, rótulo e legenda exatos devem ser camadas editáveis na pós-produção: o modelo pode escrever incorretamente. Escrita gerada não é legenda verificada. Não envie comandos Tesseract, shaders ou campos de API ao Flow.

<a id="modo-e-referencias"></a>

## Modo e referências

Texto para vídeo descreve composição; referências para vídeo exige ativos selecionados/vinculados; frames exige slots reais compatíveis. Primeira/última imagem coerentes orientam trajeto, sem garantir ação intermediária. Final não deve exigir mudança impossível no tempo. Uma ficha multi-vista não é automaticamente frame inicial.

Handle é só texto até comprovar seleção no Chrome. Continuação começa pela inspeção do último frame real do clipe aprovado; confira integridade, direção e estado e selecione esse arquivo no slot compatível. Não use tentativa defeituosa como referência canônica, nem miniatura como último frame. Veja [continuidade](continuidade.md).

<a id="preflight-e-historico"></a>

## Preflight e histórico

Confirme projeto, modelo, modo, duração, proporção, resolução, áudio, referências/slots, quantidade total, custo observado e orçamento restante. Guarde evidência sem credenciais. Autorização real e dados coerentes são necessários; validação não controla Gerar. Mudança de parâmetro/arquivo exige nova conferência correspondente.

Cheque por cena, congele com `scripts/attempt_snapshot.py`, confirme integridade e envie somente `submitted_prompt.txt`. Registre `pending` antes do envio, depois estado/gasto observados. Resultado ou gasto desconhecido vira `unknown` e exige reconciliação antes de repetir. `pending` não autoriza reenvio. Preserve entradas, versões e mídia para comparar uma variável por vez.

Técnicas: [prompt.observable](../tecnicas.md#promptobservable), [prompt.audio](../tecnicas.md#promptaudio), [identity.handoff](../tecnicas.md#identityhandoff).

Fontes: Square-Zero `video-prompting/SKILL.md`, `references/models/veo3/prompting.md`; fal `skills/storytelling/references/workflows.md`, `skills/genmedia-workflow/references/pipeline-patterns.md`; OpenMontage `skills/creative/prompting/veo-prompting.md`, `video-gen-prompting.md`. Consulta somente, sem SDK/CLI. [Cobertura](../../reports/knowledge-coverage.md).
