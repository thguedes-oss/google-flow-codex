# Imagens criadas pelo Codex

O gerador de imagens integrado do Codex cria as referências deste projeto. Não há modelo instalado na máquina, API própria, formulário local ou Flow Tool. A primeira entrega é a base reutilizável; não gere um piloto nem preencha a biblioteca com imagens fictícias.

## Do brief à referência

1. Leia o brief, o manifesto e as fichas. Liste apenas os personagens, cenários e objetos necessários. Detalhes não definidos continuam pendentes na especificação; escolhas visuais de uma imagem candidata serão descritas como observações, não como fatos previamente aprovados.
2. Consulte a skill `imagegen` disponível na sessão. Use a ferramenta integrada `image_gen`; não use CLI, SDK, chaves de API ou fallback sem pedido explícito do usuário. Os scripts deste projeto apenas organizam arquivos, nunca chamam geradores.
3. Prepare um prompt por material: finalidade, sujeito, enquadramento, iluminação, invariantes e itens a evitar. Personagem: uma pessoa, rosto e roupa legíveis. Cenário: geometria clara, sem pessoas extras. Objeto: forma, material e orientação legíveis. Uma imagem de composição de cena é opcional.
4. Gere conforme o pedido de produção real. Inspecione a saída e mostre a imagem no chat. Para editar ou derivar uma vista de um arquivo local, carregue-o com `view_image` antes de usar o gerador. Inclua a referência canônica real e diga o que deve permanecer fixo. Não substitua geração por placeholders.
5. Copie o resultado real para a pasta do projeto antes de referenciá-lo. O gerador normalmente salva primeiro na área do Codex; não prometa um argumento de destino na chamada. Preserve a imagem anterior e crie uma versão nova.
6. Registre o candidato e apresente-o para aprovação. Só depois da aprovação explícita ele pode entrar como referência canônica na biblioteca.

Uma folha com várias vistas pode ajudar a discutir identidade, mas não deve entrar inteira no Flow. Prefira imagens individuais; um recorte ou edição terá arquivo, hash, versão e aprovação próprios. Nunca aprove por nome de arquivo, hash, tamanho ou sucesso da ferramenta.

## Orçamentos distintos

`generation.budget_credits` refere-se exclusivamente ao Google Flow. Continua em zero até autorização para produção no Flow. Pedidos de imagens pelo gerador integrado do Codex são tratados separadamente, conforme o brief e a quantidade solicitada. Não presuma gratuidade, preço ou saldo dessa ferramenta. Registre chamadas e resultados reais; custo não informado permanece desconhecido.

Implementar ou verificar esta base não autoriza gerar imagens. Para começar uma produção, um pedido como “Crie as referências deste brief usando seu gerador de imagens” define o trabalho. Respeite a autorização ao longo da produção, sem pedir confirmação novamente a cada imagem já incluída no pedido.

## Registro técnico

Use o modelo `templates/registro-imagem.json` para registrar uma saída real. `tool` será `image_gen` para o gerador integrado ou `user-provided` para material fornecido. Guarde o prompt final, a descrição observada e os inputs relativos ao projeto, com hash e papel. O comando `asset_library.py candidate` copia os bytes e registra dimensões e SHA-256; não gera nem aprova imagens.

O arquivo `templates/aprovacao-imagem.json` serve apenas de modelo de uma decisão real. Preencha responsável, data e evidência textual da aprovação; nunca transforme os campos pendentes em uma aprovação presumida. Veja [biblioteca](biblioteca.md).
