# Textos preparados para futuras imagens

**Orçamento: zero. Nenhum bloco abaixo foi enviado a um modelo.** Gerar estas imagens depende de autorização de orçamento própria. Os detalhes descrevem a especificação desejada, não uma identidade já aprovada. Pontos ausentes das fichas permanecem pendentes.

Prompts em inglês por convenção deste exemplo; isso não comprova desempenho superior. Os handles são identificadores de planejamento. Configurações de geração, arquivos selecionados e vinculação real serão conferidos na interface antes do envio.

## Referência de Lia

Destino planejado: `assets/lia-v1.png`. Uma imagem e uma vista; não exige uma folha de corpo inteiro nem definição de medidas ainda desconhecidas. Depois de produzir com autorização, inspecionar o rosto e a roupa e obter aprovação antes de registrar o arquivo e hash.

```text
NO TEXT IN THE IMAGE: no captions, labels, logos or watermarks.
Create exactly one photographic reference image of @Lia, one fictional adult woman around thirty, in a single frontal upper-body view. She has an oval face, brown eyes and straight black shoulder-length hair with a centre part. She wears one plain navy long-sleeved shirt and no jewellery. Use a neutral expression, a simple neutral background, soft even light and an eye-height camera. Keep the face, hair and visible shirt clearly readable. The image contains one person and one view, with no props or scene elements.
```

## Referência do café

Destino planejado: `assets/cafe-v1.png`. Aprovar âncoras espaciais e luz. A referência não contém Lia; a composição com a personagem será avaliada separadamente.

```text
NO TEXT IN THE IMAGE: no captions, labels, logos, signs or watermarks.
Create exactly one photographic reference image of @Cafe, an empty quiet cafe. A rectangular wooden table occupies the foreground. A window is on image-left. The rear wall is pale green, with one plant in the rear image-right corner. Soft diffuse daylight enters from image-left. Use a frontal eye-height camera and keep the table, window, rear wall and plant clearly readable in one landscape composition. The image contains no people or additional hero objects.
```

## Referência da caneca

Destino planejado: `assets/caneca-v1.png`. Aprovar forma, cor e alça. A escala em relação à mão continua pendente até inspeção da composição real.

```text
NO TEXT IN THE IMAGE: no captions, labels, logos or watermarks.
Create exactly one photographic reference image of @Caneca, one plain white ceramic mug with exactly one handle facing image-right. Show the complete mug clearly against a simple neutral background under soft even light. The image contains one mug, with no hands, people, decorations or additional objects.
```

## Imagem opcional de abertura da cena

**Requer os três materiais reais aprovados e anexados. Eles ainda não existem.** Este texto descreve a entrada planejada comum às duas cenas; não comprova a emenda entre vídeos reais. Destino futuro: uma imagem separada por uso, com versão, hash e aprovação próprios. Se usada como frame inicial, revisar modelo/modo e preflight; não alterar silenciosamente o modo atual `references-to-video`.

```text
NO TEXT IN THE IMAGE: no captions, labels, logos, signs or watermarks.
CHARACTER REFERENCE: @Lia
LOCATION REFERENCE: @Cafe
PROP REFERENCE: @Caneca
Create exactly one photographic still of one adult woman, @Lia, seated facing forward at the rectangular wooden table in @Cafe. Preserve the facial identity, straight shoulder-length black hair with a centre part and plain navy long-sleeved shirt of the attached character reference. Her expression is neutral and she wears no jewellery. Her right hand holds exactly one plain white ceramic @Caneca at chest height, its single handle facing image-right; her left hand rests on the table. Preserve the attached mug shape and the attached cafe geometry: window on image-left, pale green rear wall, one plant in the rear image-right corner. Soft diffuse daylight enters from image-left. Use a static frontal medium composition at eye height, showing her head, chest, both hands, mug and set anchors. The image contains no other people or hero objects, no drinking and no transfer of the mug between hands.
```

Critérios fora dos blocos: comparar imagens reais com as três fichas; conferir identidade, mãos, escala, quantidade, geometria e luz; registrar discrepâncias. Se uma saída inventar características ainda pendentes, elas só se tornam canônicas depois de decisão e aprovação explícitas. Preparar estes textos não muda `approved`, orçamento, modelo ou prontidão.

Adaptação local dos métodos de [fichas de identidade e referências do Veo](../../../workflow/fontes.md); nenhum texto upstream foi executado como instrução operacional.
