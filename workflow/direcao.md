# Direção por plano e intenção de revisão

Este procedimento adapta ideias da [wiki Claudia](https://claudia.gallery/wiki/), especialmente [storyboard](https://claudia.gallery/wiki/storyboard/), [pipeline](https://claudia.gallery/wiki/pipeline/) e [falhas](https://claudia.gallery/wiki/failures/). A fonte datada e seus limites de uso estão em [fontes](fontes.md). A adaptação atende vídeos em geral; não introduz ferramentas musicais ou outro provedor de geração.

## Do brief ao plano

Use [direção contextual](direcao-contextual.md) como padrão: o Codex escolhe e justifica a linguagem do vídeo e as soluções de cada cena a partir do pedido. O [plano editorial](../templates/plano-editorial.md) reúne visão geral, escolhas e pendências. Consulte decisões existentes antes de perguntar; o usuário não precisa fornecer enquadramento, técnica ou parâmetros.

Antes dos prompts, defina a mensagem observável, a função de cada plano e o que muda até seu final. Uma ação discreta pode ser suficiente: não acrescente drama, movimento ou personagens para preencher a duração. Descreva a ação e seu resultado, incluindo uma reação somente quando fizer parte do brief.

Escolha o enquadramento para mostrar o que será avaliado. Registre por que a câmera fica parada ou se move, com posição inicial, direção e posição final quando houver movimento. Preserve os estados de entrada e saída do manifesto. A intenção ajuda a avaliar o resultado, mas não substitui esses estados nem a imagem aprovada.

Use as preferências do usuário e os materiais fornecidos para cor e textura: aparência original, tratamento de cor ou textura específica. Na ausência de preferência, o Codex escolhe uma solução adequada à mensagem, registra sua justificativa e a apresenta na prévia disponível, sem solicitar autorização de cada ajuste rotineiro. Guarde referências visuais e decisões reais. Não aplique automaticamente a estética de outro vídeo, nem desature referências para depois exigir que o modelo restaure suas cores.

## Identidade e composição

Depois da aprovação visual, mantenha na ficha um bloco estável de identidade derivado do arquivo canônico. Reutilize os termos observados; mudanças de roupa, cenário ou estado precisam de decisão explícita. Enquanto não houver imagem aprovada, o bloco continua sendo especificação desejada e a aparência observada permanece pendente.

Adapte o detalhamento ao enquadramento sem mudar a identidade: em planos próximos, descreva os detalhes visíveis do rosto; em planos abertos, priorize silhueta, cabelo, roupa e posição. Não invente detalhes que a referência não mostra. Evite que uma descrição longa de rosto contradiga um plano distante e confira proporções no resultado real. A referência aprovada continua sendo a fonte de identidade nos dois casos.

Se houver texto ou gráficos, escolha o que eles explicam, o texto exato, o intervalo e uma região que não cubra rosto, mãos ou ação importante. Considere o tamanho de leitura no destino final. Declare quando o clipe não tiver gráficos. Títulos e gráficos editáveis podem ser feitos na [pós-produção](pos-producao.md); não acrescente comandos de renderização ao prompt enviado ao Flow.

## Plano de revisão e contrato aditivo

Use o arquivo já indicado por `scenes[].review_plan`. Em `schema_version: 1`, `direction` é opcional para registros antigos. Quando presente, é um objeto com quatro textos não vazios:

| Campo | Conteúdo |
|---|---|
| `purpose` | Função do plano no vídeo e o que o público deve perceber. |
| `action_result` | Ação prevista e resultado observável, coerentes com os estados do manifesto. |
| `camera_intent` | Enquadramento e motivo da escolha da câmera. |
| `graphics_intent` | O que os textos/gráficos explicam, ou declaração explícita de ausência. |

O [modelo de revisão](../templates/plano-revisao.json) contém campos de preenchimento, não decisões. Preencha-os a partir do brief antes de usar. `moments` mantém o formato existente; relacione os pontos escolhidos a evidências observáveis da ação e do resultado. A verificação confere estrutura e preenchimento, sem compreender ou aprovar a intenção narrativa.

O hash e o congelamento do plano de revisão já existentes incluem `direction`. Alterar esse arquivo invalida o preflight correspondente. Na extração de evidências, `expected_direction` vem da cópia congelada da tentativa quando ela existe, inclusive sem `--enhanced`. Sem direção, o campo é `null`. O modo ampliado continua sendo a opção que acrescenta momentos e alertas aos cinco pontos básicos.

Quando `expected_direction` existe, o fechamento exige `intent_review`: a observação real do responsável sobre o resultado em relação ao propósito, à ação, à câmera e aos gráficos planejados. Vale para aprovação e rejeição. Defeitos continuam registrados nos 12 critérios e nos timestamps existentes; não há nota narrativa automática nem aprovação inferida pelo preenchimento.

## Decisões, prévias e ajustes

Use [o modelo de decisões](../templates/decisoes.md) em `projects/nome-do-video/decisoes.md`. Registre a fala real do usuário, data, cenas afetadas e artefatos/versionamento aplicáveis. Uma nova decisão acrescenta outra entrada com referência à anterior, sem reescrever o histórico. Notas de planejamento e registros de implementação não são decisões criativas do usuário. Esse diário não substitui a autorização de orçamento, o manifesto ou as aprovações formais.

As escolhas autônomas do Codex ficam identificadas no editorial, junto de motivos, materiais necessários e técnica ou ausência dela. Registre observação e aprovação separadamente quando realmente existirem. Pedidos de ajuste em linguagem comum geram uma interpretação explícita do Codex, nova versão e alterações nos artefatos operativos afetados, conforme [o procedimento](direcao-contextual.md#material-real-prévias-e-ajustes).

Planeje a montagem antes da geração: ritmo, emendas, som, textos e quadro final. Com materiais já aprovados e dentro do trabalho autorizado, use um animatic ou uma prévia curta de um trecho representativo para conferir cor, textura, composição e ritmo antes de montar o restante. A prévia não aprova clipes ou a montagem, e este procedimento não cria um piloto automaticamente.

Compare cada tentativa com o brief, a direção congelada e as referências, além do prompt. Se o prompt for fraco, cumpri-lo não basta para alcançar a intenção. Registre o defeito, ajuste uma causa por vez e preserve a tentativa anterior. Se a origem visual mudar, revise seus derivados e prepare outra versão; não reutilize evidências antigas como se correspondessem à nova origem.

As opções da wiki por identidade só em texto, percentuais de presença da protagonista, cortes na batida, limites de janelas cantadas, preços e tratamentos específicos são relatos daqueles projetos e ferramentas. Não viram regras do Flow. Aprovações, referências visuais, compatibilidade e orçamento continuam seguindo os procedimentos locais e as decisões reais do usuário.
