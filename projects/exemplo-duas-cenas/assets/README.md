# Referências pendentes

Nenhuma imagem foi criada ou aprovada nesta configuração. Prepare os três arquivos abaixo antes de gerar, mantendo o estilo fotográfico e a luz compatíveis:

Consulte as [fichas desejadas](../fichas/lia.md) e os [textos preparados](../prompts/referencias.md). Eles não são evidência visual. As demais fichas estão em `fichas/cafe.md` e `fichas/caneca.md`; detalhes ausentes permanecem pendentes.

1. `lia-v1.png`: retrato e roupa de Lia legíveis, fundo simples, uma única pessoa, sem texto. Aprovar rosto, cabelo e camisa.
2. `cafe-v1.png`: cenário vazio no enquadramento frontal descrito no brief. Janela à esquerda da imagem, planta à direita do fundo, parede verde-clara e mesa de madeira. Sem pessoas, marcas ou cartazes.
3. `caneca-v1.png`: caneca branca lisa, com uma única alça, em fundo simples; sem mãos ou objetos extras. Conferir escala e orientação quando usada na cena.

Não basta criar arquivos com esses nomes: inspecione e obtenha aprovação. Registre em `project.json` o caminho relativo, `approved: true` e o SHA-256 dos **bytes reais** aprovados. Depois confira a vinculação de cada imagem no Flow e registre a evidência. Se os slots da interface exigirem outra composição, revise o plano sem descartar silenciosamente uma referência.

As imagens de identidade não devem ser substituídas por resultados que já apresentam deriva. Para obter o hash no PowerShell: `Get-FileHash -Algorithm SHA256 caminho-da-imagem`.
