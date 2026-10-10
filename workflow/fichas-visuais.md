# Fichas visuais e preparação de referências

As fichas separam três coisas: **o que desejamos**, **o que uma imagem real mostra** e **o que foi aprovado**. Uma descrição detalhada não é evidência de identidade visual. Na preparação desta base, materiais e aprovação continuam pendentes. Em uma produção real, crie imagens pelo gerador integrado do Codex conforme [imagens-codex](imagens-codex.md), mantendo separado o orçamento zero do Flow.

## Preparar uma ficha

Copie o modelo de [personagem](../templates/ficha-personagem.md), [cenário](../templates/ficha-cenario.md) ou [objeto](../templates/ficha-objeto.md) para `projects/nome-do-video/fichas/`. Use um arquivo por handle e preencha somente informações do brief, de materiais fornecidos ou de decisões reais. Escreva `PENDENTE` para detalhes ausentes; não complete altura, tom de pele, medidas ou marcas por suposição.

`project.json` continua sendo o registro operacional de referências, hashes, estados, configurações e orçamento. As fichas ajudam a inspecionar e preparar os prompts. Antes da produção, confronte ficha, manifesto, imagens e prompt; divergências precisam ser resolvidas explicitamente. Atualize os documentos juntos quando uma decisão mudar.

Mantenha em cada ficha a especificação inicial e a descrição observada no material aprovado. Se a imagem aprovada divergir do desenho inicial, registre a decisão e ajuste os prompts e estados; não esconda a diferença reescrevendo o histórico de revisão. Registre versão, caminho, SHA-256 e a aprovação real no manifesto e na ficha.

Depois da aprovação, prepare um bloco estável de identidade derivado da imagem real e reutilize seus termos. Ajuste o detalhamento ao enquadramento, preservando identidade e roupa: detalhes visíveis do rosto nos planos próximos, silhueta/cabelo/roupa nos planos abertos. Antes da aprovação, mantenha esses textos identificados como especificação desejada. A opção da wiki Claudia por identidade textual em Midjourney não substitui as referências aprovadas deste projeto.

Registre a função de personagem, cenário e objeto por cena, o motivo do enquadramento e as regiões que precisam permanecer legíveis. Se houver texto/gráfico, confira espaço real para ele sem encobrir rosto, mãos ou ação. Guarde a escolha de cor/textura como decisão do usuário, sem adotar automaticamente a estética de uma fonte. Consulte [direção](direcao.md).

## Selecionar imagens

- Personagem: rosto, cabelo e roupa legíveis; enquadramento neutro e uma única pessoa. Preserve particularidades da referência real, em vez de redesenhar o rosto a cada cena.
- Cenário: âncoras espaciais e direção da luz claras. Diferencie esquerda/direita da imagem de esquerda/direita da personagem.
- Objeto: forma, material, cor, quantidade e orientação. A escala em relação à mão ou ao cenário será conferida na imagem de cena e no vídeo.
- Vistas adicionais ou expressões são opcionais, conforme a necessidade e o orçamento. Se houver uma folha com várias vistas, selecione um recorte limpo, inspecione-o e registre seu próprio hash e aprovação antes do uso no Flow. Uma folha inteira pode induzir duplicação de personagens.

Depois de aprovar referências, uma imagem estática de cena pode servir para conferir composição, identidade, geometria, luz e posição das mãos antes do vídeo. Esta etapa é opcional e consome orçamento próprio quando usa geração. Se decidir usá-la como frame inicial, revise o modo e as capacidades atuais; o exemplo permanece em referências para vídeo.

Prepare os prompts de imagem separadamente dos prompts de movimento. Declare a quantidade de imagens e pessoas, o enquadramento e o que precisa permanecer fixo. Mantenha notas de operador, configurações e critérios de aprovação fora do bloco enviado ao modelo. Um handle digitado não substitui uma referência anexada.

## Aplicação ao exemplo

As fichas de [Lia](../projects/exemplo-duas-cenas/fichas/lia.md), [café](../projects/exemplo-duas-cenas/fichas/cafe.md) e [caneca](../projects/exemplo-duas-cenas/fichas/caneca.md) descrevem a especificação desejada já existente, com identidade observada pendente. Os [textos de referência e imagem de cena](../projects/exemplo-duas-cenas/prompts/referencias.md) são preparação; não foram enviados a um modelo.

Este método foi adaptado localmente das referências registradas em [fontes complementares](fontes.md). As fichas e os textos deste projeto são adaptações próprias; as cópias upstream e suas licenças permanecem intactas.
