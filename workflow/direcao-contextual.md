# Direção contextual pelo Codex

Este é o padrão para produções novas no FLOW. O usuário descreve o que deseja comunicar; o Codex conduz as escolhas criativas e técnicas, preenche os arquivos e usa as ferramentas existentes. Este procedimento orienta o agente no chat: os executáveis recebem planos explícitos, sem interpretar sozinhos o significado das cenas.

## Entrada e retomada

Leia as instruções do projeto, [operação](operacao.md), o brief, o manifesto do vídeo e seus registros antes de perguntar. Para um projeto novo, crie sua pasta a partir dos modelos, sem herdar aprovações. Para um existente, consulte decisões, referências, tentativas e revisões vigentes antes de propor mudanças. Não reescreva históricos, pacotes congelados ou decisões anteriores para adequá-los ao novo procedimento.

Extraia mensagem, público, tom, duração, idioma, destino, proporção e restrições. Reutilize marca, materiais e preferências já fornecidos. Uma escolha rotineira ausente, como enquadramento ou transição, fica a cargo do Codex. Na ausência de estética definida, escolha linguagem adequada à mensagem e registre sua interpretação; não atribua a escolha ao usuário. Formato/duração ainda incertos podem ser propostas de trabalho claramente marcadas, sem autorizar geração.

Pergunte quando faltar algo que impeça uma decisão responsável: objetivo indeterminado, informações factuais indispensáveis, instruções incompatíveis, identidade cuja alteração afete material aprovado ou autorização de gasto ainda inexistente. Enquanto aguarda, avance no planejamento independente. Não peça ao usuário para escolher shader, preencher JSON ou calcular frames. Não invente data, preço, marca, depoimento, direito de uso ou resultado para completar o brief.

Um pedido amplo de vídeo autoriza o planejamento e as escolhas rotineiras desse trabalho. A criação de imagens segue o pedido próprio já autorizado; a geração no Flow segue orçamento e preflight reais. Confiança para dirigir não aprova referências, clipes ou montagem. Não repita pedidos de autorização já cobertos pela conversa.

## Plano editorial e origem dos registros

Preencha [o modelo editorial](../templates/plano-editorial.md) na pasta do vídeo como `plano-editorial-v1.md`. Acrescente versões quando houver mudança relevante, indicando a anterior e o motivo. Ele contém visão geral e decisões por cena. Use também o [brief](../templates/creative-brief.md) e o [registro de decisões](../templates/decisoes.md), mantendo uma referência entre os documentos para evitar versões contraditórias.

Mantenha quatro origens separadas:

| Registro | Como preencher | O que não significa |
|---|---|---|
| Pedido do usuário | Fala real, contexto/data e decisões já fornecidas | Não extrapolar autorização de orçamento ou mídia |
| Escolha do Codex | Solução, justificativa, cenas afetadas, alternativas relevantes e versão | Não atribuir preferência ou aprovação ao usuário |
| Observação da mídia | Arquivo/hash, trecho/frame, aparência/ação/som realmente inspecionados | Não preencher a partir do roteiro ou de material ainda ausente |
| Aprovação real | Responsável, registro e decisão vigente no mecanismo correspondente | Proposta, render ou aprovação estrutural não substituem a decisão |

Sem mídia, escreva “observação pendente”; sem decisão, “aprovação pendente”. É possível escolher a direção antes de produzir, mantendo os requisitos de execução pendentes. Não preencha o diário de falas do usuário com decisões técnicas do Codex.

## Direção do vídeo inteiro

Planeje antes de redigir prompts:

1. **Narrativa:** mensagem principal, abertura, desenvolvimento, demonstração ou prova disponível, resultado e fecho. Escolha somente as etapas que servem ao conteúdo; preserve palavras, números e afirmações fornecidos.
2. **Materiais:** personagens, cenários, objetos e inserções necessários; arquivos aprovados existentes, referências canônicas e lacunas. Escolha vistas adicionais apenas quando um plano exigir, conforme [fichas](fichas-visuais.md) e [imagens](imagens-codex.md).
3. **Planos:** função, ação/resultado, enquadramento, câmera/foco, luz/cor, som e gráficos. Descreva poucas ações observáveis, com tempo de percepção e leitura. Identidade vem das referências aprovadas; estética não justifica alterá-las.
4. **Passagens:** estados de entrada/saída, eixo, olhar, mão/objetos, direção do movimento e relação sonora. Distinga corte, mudança deliberada e continuação conforme [continuidade](continuidade.md).
5. **Montagem:** seleções, duração, ritmo, pausas, textos exatos, música/ambiente, técnicas e quadro final. Reserve a composição para informação legível, sem cobrir a ação importante.
6. **Revisão:** o que precisa aparecer, quando inspecionar e quais divergências invalidariam a cena ou a emenda. Confronte o resultado com a intenção, além do prompt.

Distribua o trabalho entre geração e pós-produção: sujeito, atuação, ação, cenário e câmera previstos entram no prompt; títulos exatos, formas, gráficos e efeitos editáveis podem ficar no Tesseract. Não transforme um comando de renderização em instrução ao Flow. O planejamento geral antecipa a montagem; os tempos finais dependem dos materiais realmente obtidos.

## Escolha de técnicas por cena

Para cada cena e passagem, responda: o que precisa ser percebido, o que muda, como se relaciona com os trechos vizinhos, o que já está claro na imagem/som e o que uma intervenção acrescenta? Registre a solução e seu motivo. **Sem efeito** é uma escolha válida e pode ser a melhor solução para qualquer tipo de vídeo.

Considere a ação, a composição, o áudio, a legibilidade, as referências e o material disponível. Não decida apenas por palavra-chave, gênero, duração fixa, batida detectada ou contagem de técnicas. Estas são possibilidades para avaliar, não presets obrigatórios:

| Necessidade concreta | Solução possível | Conferência antes de escolher |
|---|---|---|
| Tornar uma instrução compreensível | Detalhe da ação, rótulo ou diagrama progressivo | Ordem, prova visível, texto exato e tempo de leitura |
| Manter atenção numa fala ou reação | Sustentar o plano ou usar corte discreto | Palavras inteiras, expressão, pausa e som |
| Explicar diferença entre materiais/estados | Planos correspondentes ou colagem | Escala comparável, origem e fidelidade da comparação |
| Marcar passagem narrativa | Corte, ponte sonora ou transição visual justificada | Significado da passagem, continuidade e conteúdo que pode ficar oculto |
| Acentuar evento pontual | Avaliar som, mudança de plano ou flash breve | Instante observado, legibilidade, conforto e coerência do conjunto |
| Dar destaque a produto ou detalhe | Enquadramento/inserção, reenquadramento ou gráfico útil | Forma, rótulo, material, resolução e ausência de alegação inventada |

Consulte as [fichas](tecnicas.md), o [catálogo nativo](../resources/techniques/catalog.json), o [catálogo GL](../resources/gl-transitions/catalog.json) e suas evidências. Confira o estado habilitado e a correspondência dos hashes, os parâmetros/tipos, as fontes requeridas e o formato. Um shader compilável ou uma técnica documental não basta para declarar suporte operacional. Conteúdo incompleto permanece indisponível; não escreva conversor ou shader improvisado durante a produção.

Planeje fonte, posição e duração concretas na janela existente. Efeitos animados exigem os frames mínimos do contrato; fontes precisam cobrir a janela. Planeje sobreposições de duas fontes explicitamente, com decisão sonora própria; transição visual não cria crossfade de áudio. Não amplie material nem desloque corte pelo compilador. Confira restrições de técnicas sobrepostas/contíguas na mesma fonte, `native_actions` concorrentes e `fade_ms`, conforme [pós-produção](pos-producao.md#tecnicas-em-janelas-existentes).

Avalie transparência e ordem das camadas, recorte/proporção, conteúdo perdido nos intermediários, texto legível e identidade nas bordas. Shaders que forçam opacidade ou conservam resíduos nos extremos têm [limites específicos](../resources/gl-transitions/README.md). Marcadores RMS são candidatos: sincronização musical exige escuta. Uso automático da ferramenta não torna a escolha artística ou a aprovação automáticas.

Se a técnica não couber, escolha outra solução que preserve a função ou mantenha a necessidade pendente, explicando o impacto. Não troque silenciosamente por um efeito parecido. O Codex pode revisar seleções/cortes dentro do trabalho autorizado, com registro explícito e nova revisão; nova geração continua sujeita ao orçamento. Não é necessário consultar o usuário sobre cada alternativa técnica rotineira.

## Do plano à execução

| Destino existente | O que o Codex transpõe | Verificação |
|---|---|---|
| Brief e decisões | Mensagem, restrições, preferências reais e escolhas atribuídas corretamente | Sem afirmações/autorizações inventadas |
| Manifesto, fichas e storyboard | Referências, ação, sequência, estados e mudanças deliberadas | Coerência com arquivos aprovados e cenas vizinhas |
| Plano de revisão | `direction`: função, ação/resultado, câmera e gráficos/ausência; `moments` observáveis | [Contrato atual](direcao.md), sem novos campos obrigatórios em JSON |
| Prompt e preflight | Cena autossuficiente, configuração compatível e referências reais vinculadas | Chrome, custo/saldo e autorização; congelar antes do envio |
| `postproduction.json` | Fontes aprovadas, cortes/posição em ms, textos, áudio e `techniques` em frames | Catálogos, intervalos, aprovação vigente e validação do pipeline |
| Revisão formal | Observações, defeitos, reprodução/escuta e decisão reais | [Revisão dos clipes](revisao.md) e [da montagem](pos-producao.md#revisão-e-entrega) |

O editorial é um documento de direção, não um novo manifesto executável. Transponha suas decisões operativas antes de validar/congelar; não suponha que escrever no Markdown alterou o Flow ou a composição. Os selos existentes cobrem os arquivos transpostos e as receitas/shaders utilizados, não congelam automaticamente o editorial inteiro. Registre no editorial as versões/pacotes reais aos quais ele corresponde. Nos planos de revisão, `moments.seconds` é local ao clipe, relativo ao primeiro frame decodificado; se o editorial indicar tempo na montagem, converta e associe cada expectativa ao instante correspondente, sem reunir eventos de momentos distintos num único frame. Para um trecho recortado, considere também a entrada selecionada da origem ao localizar o momento no clipe completo.

Execute as etapas elegíveis sem interromper para aprovar cada escolha de lente, corte ou parâmetro. A geração de imagens usa o gerador integrado do Codex no pedido autorizado e apresenta candidatos. Flow permanece no Chrome, uma tentativa registrada por vez; resultado/gasto desconhecido exige reconciliação antes de repetir. A montagem usa os executáveis portáteis fixados e fontes elegíveis; confiança para dirigir não dispensa aprovação formal dos clipes.

Sem autorização de geração ou com orçamento Flow zero, mantenha as gerações no Flow bloqueadas e conclua o planejamento possível. Imagens pelo Codex seguem seu pedido próprio autorizado, separado dos créditos Flow; orçamento Flow zero não cancela esse pedido. Materiais ausentes permanecem pendentes, sem inventar substitutos ou aprovações. Com materiais aprovados e montagem autorizada, prepare prévia/animatic e revisão local conforme o plano, inclusive com orçamento Flow zero. A adoção deste procedimento, sozinha, não autoriza piloto ou geração. Um render não aprova os materiais ou o vídeo final.

## Material real, prévias e ajustes

Depois de obter mídia, inspecione o clipe completo, seus momentos relevantes, referências e emendas; escute o áudio. Registre separado o que foi observado e compare com a direção congelada. O efeito previsto pode deixar de ajudar porque o movimento, a fala ou o espaço para texto vieram diferentes. Replaneje a montagem em outra versão, preservando intenção e evidências anteriores. Não altere estados esperados ou faça efeito ocultar defeito de identidade/física para aceitar o clipe.

Apresente uma explicação breve das escolhas importantes e a prévia disponível, com pendências reais. O usuário pode revisar a intenção em linguagem comum; o Codex faz a tradução e registra quais cenas/artefatos mudaram:

| Pedido | Interpretação possível, a registrar como escolha do Codex |
|---|---|
| “Mais sóbrio” | Reduzir intervenções que competem com conteúdo, estabilizar hierarquia e transições; não desaturar referências canônicas automaticamente |
| “Mais dinâmico” | Rever progressão, pontos de corte e variedade útil, mantendo compreensão, fala e leitura; não acelerar tudo ou adicionar flashes por hábito |
| “Dê mais destaque ao produto” | Dar tempo/enquadramento ao detalhe relevante e ajustar inserções/gráficos, preservando identidade e afirmações verificáveis |

Consulte o usuário se a interpretação alterar mensagem, fatos, identidade aprovada ou exigir autorização nova. Escolhas técnicas rotineiras dentro da revisão autorizada podem ser executadas e demonstradas na próxima prévia. Uma mudança relevante cria nova versão editorial e novos artefatos operativos/revisões quando afetados; não invalide mídia ou decisões anteriores silenciosamente.

Feche revisões somente com decisões reais, reprodução e inspeção exigidas. Entregue resultado/fonte editável quando disponíveis, escolhas relevantes, pendências e custos reais. Testes de estrutura, catálogos e exercícios fictícios comprovam organização técnica nas condições registradas; não demonstram qualidade criativa, redução de alucinações ou economia de créditos.
