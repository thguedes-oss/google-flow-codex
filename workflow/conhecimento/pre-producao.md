<a id="pre-producao-da-mensagem-ao-plano-filmavel"></a>

# Pré-produção: da mensagem ao plano filmável

Este guia adapta planejamento narrativo, comercial e de materiais; não inicia geração. Use [o brief](../../templates/creative-brief.md), [técnicas](../tecnicas.md) e o manifesto existente. Uma escolha de linguagem não equivale a orçamento, aprovação de referência ou prontidão.

A [direção contextual](../direcao-contextual.md) é o padrão de condução: o Codex preenche brief e [editorial](../../templates/plano-editorial.md), escolhe soluções rotineiras e só pergunta pelo indispensável. Origem das escolhas, observação e aprovação permanecem separadas; projetos existentes mantêm suas decisões.

<a id="publico-mensagem-e-evidencia"></a>

## Público, mensagem e evidência

Escreva uma frase com o que o público deve compreender ou fazer depois do vídeo. Identifique público concreto, conhecimento prévio, contexto de exibição, idioma, proporção e duração. Para quem desconhece o problema, mostre uma situação reconhecível; para quem conhece o produto, priorize demonstração e detalhe. Escolha uma mensagem principal e declare o que ficará fora: a duração limita as ideias e ações perceptíveis.

Separe afirmação, evidência fornecida e demonstração visual. Cena gerada ilustra; não comprova desempenho, história, estatística ou experiência pessoal. Testemunho exige palavras e experiência reais fornecidas e autorizadas; caso contrário, identifique publicidade roteirizada. Antes/depois exige estados verificáveis e diferença concreta, sem inventar causalidade. Números, datas, marcas e CTA precisam de origem e texto aprovado.

<a id="roteiro-estrutura-e-abertura"></a>

## Roteiro, estrutura e abertura

Planeje abertura → contexto → desenvolvimento/prova → resultado → fecho, retirando etapas que não sirvam ao brief. A abertura pode mostrar pergunta, problema ou resultado; não precisa ser estridente. Em explicação, apresente o elemento necessário antes da consequência e revele partes quando a fala as nomeia. Em narrativa, registre quem deseja o quê, ação que muda a situação e reação observável. Em anúncio, ligue benefício a uso ou detalhe verificável e reserve quadro final legível.

Escreva duas colunas, áudio e imagem, com intervalos estimados. Leia a fala em voz alta: palavras por minuto são aproximação, não prova de cabimento. Inclua respiração, compreensão, reação e leitura. Não imponha a mesma cadência a tutorial, aviso, diálogo e filme contemplativo. A soma dos planos precisa caber na entrega; a duração disponível de geração não determina automaticamente a duração de montagem.

Em vídeos longos, organize capítulos com pergunta, desenvolvimento e resultado próprios, mostrando por que o próximo importa. Retome a promessa inicial e permita pausas para consolidar informação. Em formatos curtos, retire explicações periféricas antes de acelerar fala. Interrupção de padrão, pergunta em aberto e mudança de escala só entram quando ajudam o conteúdo; percentuais de retenção e tempos fixos das fontes não são resultados verificados deste projeto.

Cada plano recebe ID, função, ação/resultado, duração, câmera, som, referência, estado inicial/final e relação com o próximo. Preencha os quatro campos de `direction` no plano de revisão existente; ausência de gráficos deve ser explícita. Storyboard textual não é imagem aprovada. Planeje poucas ações claras, sem movimento de câmera para preencher tempo.

<a id="b-roll-e-materiais"></a>

## B-roll e materiais

Percorra o roteiro e identifique local, processo, detalhe, evidência, reação ou diagrama necessários. Para cada inserção registre função, intervalo, ponto de vista, orientação, duração utilizável, origem e direitos. Um detalhe de caneca pode explicar a pega; imagem genérica de café não demonstra a mão. `plan.broll` é ID de técnica documental, não campo novo do manifesto.

Registro documental, tela real e arquivo histórico preservam origem; reconstrução não deve parecer prova real. Imagens novas usam somente o gerador integrado do Codex dentro do pedido autorizado, com apresentação de candidatos. Clipes novos usam Flow pelo Chrome e orçamento real. Não acione fallback automático de banco para geração ou outro provedor. Material ausente permanece pendência.

<a id="fichas-e-estados"></a>

## Fichas e estados

Prepare ficha por handle. Personagem: rosto, assimetrias observadas, cabelo, roupa, silhueta, postura e acessórios. Cenário: geometria percebida, portas/janelas, móveis, direção de luz e hora. Prop: forma, material, cor, escala relativa, quantidade, orientação e contato. Cada detalhe distingue desejado, observado e aprovado. Arquivo canônico aprovado, versão e hash definem identidade; texto não substitui imagem.

Frente, três quartos, perfil e costas ajudam quando o enquadramento exige; expressão, mãos e detalhes são opcionais. Não produza prancha completa por hábito. Derive vistas da origem aprovada preservando idade, pele, proporções, cabelo e roupa. Inspecione cada painel: pranchas podem conter identidades incompatíveis. Um painel pode virar referência depois de aprovação própria; a contact sheet inteira não é primeiro frame.

Registre posição, olhar, mão, quantidade, orientação e estado na entrada/saída. Exemplo apenas textual: Lia sentada, mão direita próxima da alça orientada à direita da imagem; ao final segura a caneca sem erguer. Próximo plano começa nesse estado ou declara elipse. Não adapte expectativas para justificar defeitos.

Guarde brief, roteiro, fichas, cenas, prompts e decisões juntos. Cor, textura, narração, música, gráficos e fecho refletem escolhas reais. Marque alternativas abertas e use [decisões](../../templates/decisoes.md), sem atribuir preferências inferidas ao usuário.

Técnicas: [plan.brief](../tecnicas.md#planbrief), [plan.sequence](../tecnicas.md#plansequence), [plan.broll](../tecnicas.md#planbroll), [identity.sheet](../tecnicas.md#identitysheet).

Fontes: Square-Zero `video-prompting/references/workflows/character-sheets.md`; fal `skills/storytelling/references/shot-planning.md`, `skills/marketing/references/campaign-patterns.md`, `skills/ugc/references/formats.md`; OpenMontage `skills/creative/storytelling.md`, `broll-planning.md`, `schemas/artifacts/brief.schema.json`. [Commits e cobertura](../../reports/knowledge-coverage.md).
