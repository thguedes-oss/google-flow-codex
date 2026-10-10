<a id="revisao-observar-comparar-diagnosticar-e-decidir"></a>

# Revisão: observar, comparar, diagnosticar e decidir

Validade estrutural, prontidão, qualidade e aprovação formal são estados diferentes. Use [revisão operacional](../revisao.md), [métricas](../metricas.md) e [pós-produção](../pos-producao.md). Campo preenchido não comprova julgamento humano, escuta ou reprodução.

<a id="evidencia-e-inspecao"></a>

## Evidência e inspeção

Identifique cena, tentativa, mídia/hash, prompt/revisão congelados, referências aprovadas e decisões vigentes. Sem mídia real não conclua fidelidade. Tentativa real `completed` pode ter evidências por `review_clip.py`; `--enhanced` acrescenta momentos/alertas sem aprovar. Preserve tudo. Fixtures ficam temporárias, fora de projeto/biblioteca.

1. Reproduza inteiro com som, avaliando compreensão, ação, ritmo e resultado contra o brief. Registre defeitos antes de presumir causas.
2. Compare início/meio/fim e momentos críticos com referências: rosto, cabelo, roupa, mãos, quantidade/orientação, contato, cenário/luz. Acrescente frames quando gesto/defeito cair entre amostras.
3. Reveja movimento/emendas: trajetória, foco, geometria, flicker, duplicação, salto temporal e velocidade. Fim real e começo real precisam ser vistos também em sequência.
4. Escute palavras, idioma, voz, ambiente, efeitos, música e fecho. Confira boca, clicks, masking e legenda; waveform/pico não substituem escuta.

Na montagem confira glifos, texto, contraste, leitura, regiões de UI, hierarquia, dados e quadro final. Transição exige início/intermediários/fim com as fontes reais. Metadados/decodificação verificam arquivo, não narrativa.

<a id="intencao-e-diagnostico"></a>

## Intenção e diagnóstico

Compare brief, `expected_direction`, estados e prompt. Prompt seguido ainda pode falhar na mensagem; texto insuficiente não é critério final. Quando houver direção congelada, `intent_review` registra observação humana sobre função, ação/resultado, câmera e gráficos. Nunca simule observação para fechar revisão.

Descreva timestamp, esperado, observado, consequência e evidência. Diferencie identidade, continuidade, ação, câmera, escrita, áudio e processamento. Considere arquivo/vínculo errado, contradição, complexidade, suporte ausente ou falha do modelo. Registre incerteza, sem apresentar hipótese como causa comprovada.

Mude uma causa: simplificar gesto, esclarecer orientação, corrigir slot ou remover movimento conflitante. Compare versões pelo mesmo trecho/critério; sem comparação não declare melhoria. Não reescreva estado, prompt congelado ou evidência para acomodar defeito.

<a id="decisao-e-entrega"></a>

## Decisão e entrega

Decisão real usa procedimento formal, revisor, evidência e hashes. `flow_review.verify_decision` confirma aprovação vigente de clipe antes da montagem. Montagem exige decisão própria com reprodução/escuta; aprovação de fontes não aprova corte final. Rejeição preserva histórico; decisão substituída invalida dependências conforme fluxo existente.

Relate créditos/tentativas reais e desconhecidos. Esta adaptação não gera mídia. Entregue exportação real/fonte correspondente, sem suporte Adobe presumido ou 4K sem perfil. Shader falho, material ausente e áudio não conferido permanecem limites explícitos.

Técnicas: [review.compare](../tecnicas.md#reviewcompare), [review.diagnose](../tecnicas.md#reviewdiagnose), [gl.transition](../tecnicas.md#gltransition), [audio.mix](../tecnicas.md#audiomix).

Fontes: OpenMontage `skills/meta/reviewer.md`, `skills/creative/video-understand-usage.md`, `schemas/artifacts/final_review.schema.json`; fal `skills/storytelling/SKILL.md`, `skills/character-design/references/anchor-system.md`; GL `README.md`. [Cobertura](../../reports/knowledge-coverage.md).
