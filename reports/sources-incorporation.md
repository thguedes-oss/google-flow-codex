# Incorporação de fontes — 10 de outubro de 2026

Foram preservados os pins e registros anteriores do Google Flow, Square-Zero, notebook Google e snapshot Claudia. Os clones fal-ai-skills, OpenMontage e BeatCut foram obtidos com shallow clone, `core.autocrlf=false`, `GIT_LFS_SKIP_SMUDGE=1`, sem submódulos; HEAD corresponde exatamente aos pins aprovados. GL foi obtido pelo agente responsável e conferido pelo mesmo contrato de integridade.

Os cinco sidecars em `config/source-inventories/` cobrem 2459 arquivos versionados: Square-Zero 26; fal 97; OpenMontage 2143; BeatCut 21; GL 172, incluindo 125 shaders. Cada arquivo possui hash, categoria, licença observada, aplicabilidade, destino e motivo. Origens duplicadas por hash continuam preservadas. A licença do shader é lida no header, com fallback explícito à MIT raiz; BeatCut permanece consulta sem cópia de código; fal declara MIT no README sem licença global; OpenMontage conserva AGPL e avisos locais de terceiros.

A classificação separa técnicas de pré-produção, direção, geração Flow, continuidade, montagem, áudio, gráficos e revisão. Integrações de provedores, outras engines, instalação, publicação e modelos locais não se tornam requisitos. Arquivos de aplicação e mídias não são promovidos a ativos aprovados. As classificações são triagem documental: o destino indica rastreabilidade de consulta, não aprovação jurídica, qualidade visual ou compatibilidade técnica demonstrada.

Verificação executada em Python 3.12.13: o novo teste de sidecar falhou inicialmente (hash alterado era aceito); após implementação, os 8 testes `test_source_integrity.py` passaram. Cobrem snapshots e web legados, hashes, arquivos ausentes, caminhos externos, Git commit/dirty, hash de inventário, cobertura, duplicatas e metadados. `scripts/source_integrity.py` passou para as 7 fontes complementares, offline, incluindo cobertura integral dos cinco inventários. Confere também arquivos extras locais, inclusive ignorados pelo Git, além de `git ls-files` e checkout limpo.

Nenhum código de fonte complementar foi executado, nenhuma skill upstream instalada, nenhum modelo ou mídia de produção gerado e nenhum crédito Flow consumido. Não houve commit. O orçamento e as aprovações de produção permanecem inalterados.

## Complemento: duplicações explícitas

`config/source-inventories/duplicates.json` registra 437 grupos SHA-256 repetidos e 947 origens completas (`source_id`, caminho e destino), preservando duplicatas dentro de uma fonte e entre fontes. O campo aditivo `duplicate_inventory` fixa seu SHA-256 no lock. A verificação principal compara os grupos exatamente aos cinco sidecars; omissões, grupos extras, entradas repetidas, hash de grupo/sidecar alterado ou origem divergente falham. Locks legados sem o campo mantêm compatibilidade. Dois testes adicionais falharam pela ausência do verificador e depois passaram; agora dez testes de fontes passaram e o CLI offline aprovou os sete suplementos mais o inventário de duplicações.
