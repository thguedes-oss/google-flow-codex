# Biblioteca visual compartilhada

As imagens são geradas no chat pelo Codex, conforme [imagens-codex](imagens-codex.md), ou fornecidas pelo usuário. Os utilitários abaixo só leem e copiam arquivos reais. Use Python 3.12, como nos outros comandos do projeto.

## Candidato, aprovação e importação

1. Copie `templates/registro-imagem.json` para o projeto e preencha os dados da imagem real. Cada input usa `path` relativo ao projeto, `sha256` e `role`. Material fornecido usa `tool: user-provided` e descreve sua origem no prompt. O custo informado pode continuar `null`.
2. Execute `scripts/asset_library.py candidate --project projects/meu-video --image C:\caminho\imagem.png --input projects/meu-video/registro.json`. O arquivo original permanece intacto. O candidato e os inputs são copiados para `assets/candidates/ID/VERSAO/`; PNG, JPEG e WebP estáticos são conferidos com FFprobe/FFmpeg.
3. Inspecione a imagem no chat, compare com o brief e registre uma aprovação real usando o modelo de aprovação. `approved: true`, `reviewer`, `at` e `evidence` devem refletir a decisão recebida, não uma previsão. A ferramenta verifica o registro, não a sinceridade da declaração.
4. Execute `scripts/asset_library.py promote --project projects/meu-video --candidate assets/candidates/ID/VERSAO/record.json --approval projects/meu-video/aprovacao.json`. Isso acrescenta uma versão ao catálogo; nunca substitui outra. Uma promoção interrompida exige reconciliação explícita.
5. Declare o handle e seu tipo no manifesto do vídeo de destino. Execute `scripts/asset_library.py import --project projects/outro-video --asset ID --version VERSAO --handle @Personagem`. O vídeo recebe uma cópia independente em `assets/library/`, com origem e aprovação. A importação invalida as vinculações daquele handle e o preflight da interface. Revise também ficha, prompts e estados.

Execute `scripts/asset_library.py verify` para conferir o catálogo, registros e bytes. Arquivos de mídia da biblioteca e dos projetos são ignorados pelo Git; mantenha um backup dos materiais reais. Metadados do catálogo não são suficientes para recuperar uma imagem perdida.

## Versões e limites

- Identificadores e versões usam até 80 letras sem acentos, números, `_` e `-`.
- Não atualize um vídeo automaticamente para a versão “mais recente”. Uma troca é uma decisão explícita e exige nova revisão.
- Mantenha especificação desejada e descrição observada distintas nas fichas. A importação registra a descrição observada no manifesto; ela não deve apagar o brief original.
- Imagens candidatas e testes técnicos não são referências aprovadas. Uma prancha ou uma folha com várias pessoas não deve ser tratada como imagem canônica de uma pessoa.
- Não há reconhecimento facial automático. Conferir codec, dimensões e hash não confirma identidade, anatomia ou adequação ao Flow.
