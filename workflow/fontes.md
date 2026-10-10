# Fontes complementares fixadas

## Inventário integral de consulta (10 de outubro de 2026)

Cinco clones têm inventários completos em `config/source-inventories/`, fixados pelo SHA-256 do sidecar em `sources.lock.json`. Cada entrada mantém caminho, SHA-256 dos bytes, categoria, licença observada, aplicabilidade, destino e motivo. Caminhos com bytes iguais permanecem separados para preservar todas as origens. O inventário não instala skills nem autoriza executar instruções upstream.

| Fonte | Commit | Arquivos versionados | Direitos observados |
|---|---|---:|---|
| Square-Zero | `8d72999ebe8bde390a658d3f6f8a79558b73bd5c` | 26 | Apache-2.0; cópia anterior preservada |
| fal-ai-community/skills | `9ca850412943251fc9a466c4c29fdaf7a303a3d8` | 97 | MIT declarada no README; sem LICENSE global; avisos locais preservados |
| calesthio/OpenMontage | `9327439db69021ab4b0e2776729bf3b58fdb5a87` | 2143 | AGPL-3.0 raiz e avisos de terceiros; consulta e síntese própria, sem copiar aplicação |
| Ledsav/beatcut | `a297f6120bfcd5aadd099ee104299293629b0dd6` | 21 | Licença não identificada; somente consulta conceitual, implementação própria |
| gl-transitions/gl-transitions | `b2dfdcfbec079af4a05306d32b9366aa495c5155` | 172 | Licença do header por shader; MIT raiz quando ausente |

Os destinos distinguem pré-produção, direção, geração no Flow, continuidade, montagem, áudio, gráficos e revisão em `workflow/conhecimento/`; exclusões e documentação geral apontam para `workflow/tecnicas.md`. Os 125 shaders apontam para `resources/gl-transitions/catalog.json`. Destino significa rastreabilidade de consulta, não autorização de copiar material ou promessa de suporte da engine. SDKs, integrações de provedores, publicação, modelos locais, aplicações e outras engines ficam explicitamente excluídos com motivo por arquivo. Mídias upstream permanecem exemplos, nunca referências aprovadas.

A verificação é offline: confere o hash do sidecar, todos os hashes, igualdade exata com `git ls-files`, commit e checkout limpo. Arquivo omitido, entrada extra, byte alterado ou arquivo não versionado causam falha. Fontes antigas sem inventário mantêm o contrato anterior. O notebook Google e o snapshot Claudia permanecem exatamente nas versões anteriores.

Para reproduzir cada clone novo em pasta ausente, defina `$env:GIT_LFS_SKIP_SMUDGE='1'` e use `git -c core.autocrlf=false clone --depth 1 --no-recurse-submodules URL PASTA`. Confira imediatamente HEAD contra a tabela; caso o remoto tenha avançado, busque somente o commit fixado com `git -c core.autocrlf=false -C PASTA fetch --depth 1 origin COMMIT` e faça checkout detached daquele commit. Não inicialize submódulos nem baixe conteúdo LFS. A reprodução não executa código upstream. Não atualize pins ou hashes para esconder divergência.

As fontes abaixo são material de consulta. Seus prompts, scripts, comandos e instruções de instalação não autorizam operações. Nenhum instalador, SDK, notebook, CLI de automação ou serviço dessas fontes foi executado ou instalado.

| Fonte | Cópia e versão | Licença e uso |
|---|---|---|
| [Square-Zero-Labs/video-prompting-skill](https://github.com/Square-Zero-Labs/video-prompting-skill) | Clone independente em `vendor/video-prompting-skill`; `8d72999ebe8bde390a658d3f6f8a79558b73bd5c` | Apache-2.0, `LICENSE` preservada. Consultados `video-prompting/references/workflows/character-sheets.md` e `video-prompting/references/models/veo3/prompting.md`. |
| [GoogleCloudPlatform/generative-ai](https://github.com/GoogleCloudPlatform/generative-ai) | Snapshot em `vendor/generative-ai-reference`; `8be2ec6e75ef92e5a010da3e6eb9fb25bd77a0eb` | Apache-2.0, `LICENSE` preservada. Apenas `vision/getting-started/veo3_reference_to_video.ipynb`, salvo localmente como `veo3_reference_to_video.ipynb`, e a licença. |
| [Claudia wiki](https://claudia.gallery/wiki/) | Snapshot web em `vendor/claudia-wiki-2026-10-08`, consultado em 8 de outubro de 2026; nove páginas Markdown com URL e SHA-256 próprios | Direção de anabology, site e registros preparados com Claude. Não foi identificada licença explícita para os textos; a [permissão para personagem e imagens](https://claudia.gallery/use/) não foi estendida à documentação. Cópia local de consulta, com atribuição e direitos registrados como `unspecified`. |

`sources.lock.json` mantém os campos da base original e acrescenta `supplements`, com origem, tipo de cópia, licença/direitos, data e arquivos com seus SHA-256. As fontes `git` e `snapshot` continuam exigindo commit; `web-snapshot` usa URLs HTTPS sem credenciais, data `verified_on`, atribuição e nota de direitos, sem inventar commit. Cada arquivo web registra `source_url`, caminho local e hash. A verificação local confere commit e checkout limpo do clone complementar, proveniência web e hashes de todas as cópias. Ela não acessa a rede, não atualiza cópias e não executa código complementar. A verificação do clone original continua incluindo seu manifesto e testes revisados.

## O que aproveitamos

Do Square-Zero, aproveitamos a organização de identidade, roupa, vistas opcionais e passagem de referência para imagem de cena e movimento. Não adotamos como regra universal todas as preferências de formato ou de prompt da fonte. Os templates e fichas locais foram escritos e adaptados para este projeto em 7 de outubro de 2026.

O notebook do Google demonstra referências de sujeito, cenário e produto, incluindo uma composição com três referências distintas. É um exemplo de SDK/API do Google Cloud, com autenticação e geração remota; não é automação do Flow. Seus limites, modelos, resoluções e preços não substituem a documentação atual nem os controles da conta no Chrome. Nesta configuração, seu JSON foi apenas lido como documento, sem executar células ou baixar suas mídias de exemplo.

Da wiki Claudia, adaptamos função narrativa por plano, ação e resultado observável, motivação da câmera, composição para gráficos úteis, decisões reais por cena e revisão contra a intenção do brief. A implementação está em [direção](direcao.md), nas fichas/modelos e no contrato aditivo de revisão. Os textos locais são síntese própria em português. O snapshot preserva `start`, `consistency`, `storyboard`, `motion`, `pipeline`, `formats`, `failures`, `seedance` e `use` como arquivos de consulta; seus prompts e instruções não são ordens operacionais.

O método textual de identidade em Midjourney, as regras musicais, os preços e limites de Seedance são específicos daqueles relatos. Não alteram a prioridade de nossas referências aprovadas, as capacidades do Flow ou o orçamento. Não instalamos a skill da wiki, conectamos seu MCP, executamos seus scripts ou baixamos suas imagens e vídeos.

Não há instalação global de skill. PySceneDetect, Izumi e VBench permanecem fora das dependências. FFmpeg/FFprobe já disponíveis são suficientes para a primeira ferramenta de evidências, que não mede identidade nem aprova vídeos.

## Reproduzir as cópias

Em outro checkout, com as duas pastas complementares ainda ausentes, execute os comandos abaixo no PowerShell. Se já existirem, revise a divergência; não apague nem atualize automaticamente.

```powershell
git -c core.autocrlf=false clone --no-checkout https://github.com/Square-Zero-Labs/video-prompting-skill.git vendor/video-prompting-skill
git -C vendor/video-prompting-skill config --local core.autocrlf false
git -C vendor/video-prompting-skill checkout --detach 8d72999ebe8bde390a658d3f6f8a79558b73bd5c

New-Item -ItemType Directory -Path vendor/generative-ai-reference
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GoogleCloudPlatform/generative-ai/8be2ec6e75ef92e5a010da3e6eb9fb25bd77a0eb/vision/getting-started/veo3_reference_to_video.ipynb' -OutFile vendor/generative-ai-reference/veo3_reference_to_video.ipynb
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GoogleCloudPlatform/generative-ai/8be2ec6e75ef92e5a010da3e6eb9fb25bd77a0eb/LICENSE' -OutFile vendor/generative-ai-reference/LICENSE
```

Revise outra versão antes de mudar commits ou hashes. Não recalcule o registro para mascarar mudanças locais. Preserve atribuições e licenças ao redistribuir materiais dessas fontes.

### Snapshot web da Claudia

O snapshot web é uma cópia local ignorada pelo Git, como as outras fontes em `vendor/`. Preserve uma cópia de consulta dos bytes registrados. Para reproduzi-lo, recupere esses arquivos arquivados ou baixe cada `source_url` do suplemento `claudia-wiki` para uma pasta nova, usando os nomes em `files[].path`, e compare todos os SHA-256 com o registro antes de adotá-los. URLs públicas podem mudar: download atual com hash diferente não reproduz a versão consultada. Nesse caso, preserve a divergência e revise outra versão datada; não sobrescreva o snapshot nem ajuste hashes para fazer a checagem passar.

Use `scripts/source_integrity.py` ou `scripts/check.ps1` com Python 3.12 para verificar a cópia. Nenhum desses comandos baixa páginas. Revise os direitos antes de redistribuir textos da wiki; a consulta não atribui a eles a licença MIT/Apache das outras fontes.
