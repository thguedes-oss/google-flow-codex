# Entrega da base reutilizável

As sete melhorias locais estão implementadas. A entrega prepara o trabalho pelo chat com o Codex e a operação manual supervisionada pelo Chrome. Não gera um piloto, não instala modelos ou serviços e não chama APIs de produção.

## Etapas e dependências

| Etapa | Entrega | Dependência | Validação local |
|---|---|---|---|
| 1. Imagens pelo Codex | Instruções para criar, editar, inspecionar e registrar candidatos; modelos de brief e registro | Brief e pedido real para criar mídia | Origem, prompt, inputs e hashes; nenhum candidato fictício na base |
| 2. Biblioteca visual | Candidatos, promoção com aprovação explícita, versões preservadas e importação independente por vídeo | Etapa 1 e aprovação real | Imagem decodificável, caminhos confinados, integridade e detecção de alteração |
| 3. Continuidade | Mudanças de corte declaradas, slots por modo, passagem por último frame aprovado e prontidão por cena | Referências aprovadas; clipe anterior para continuação | Estados, compatibilidade, inputs e invalidação de revisão substituída |
| 4. Tentativas congeladas | Pacote com texto exato, estados, referências e evidências; registro pending antes do envio | Etapa 3, autorização e preflight real do Chrome | Hashes, campos originais do CSV, interrupções e bloqueio de reenvio |
| 5. Revisão local | Extração padrão ou ampliada, alertas técnicos, decisões versionadas e comparação entre tentativas | Vídeo local completed; snapshot para comparação exata | Frames reais, taxa variável, preservação do vídeo, critérios e áudio |
| 6. Operação pelo Chrome | Procedimento de conferência, envio e reconciliação de resultados | Etapas 1–4, controles e recursos reais da conta | Registros e preflight local; operação real ainda pendente |
| 7. Métricas | Tentativas, revisão, defeitos, aprovação inicial e créditos por segundo selecionado | Tentativas reconciliadas e revisões da etapa 5 | Denominadores explícitos, custos desconhecidos e ausência de seleção duplicada |

Os comandos e formatos estão descritos em [imagens](imagens-codex.md), [biblioteca](biblioteca.md), [continuidade](continuidade.md), [tentativas](tentativas.md), [revisão](revisao.md), [operação](operacao.md) e [métricas](metricas.md).

## Critérios concluídos

- Fontes externas e licenças preservadas nos commits e hashes de `sources.lock.json`.
- `schema_version: 1` e cabeçalhos dos CSVs preservados; os campos novos são aditivos.
- Verificação integrada em `scripts/check.ps1`, com Python 3.12 e FFmpeg/FFprobe existentes.
- Testes locais com mídia técnica temporária, sem registrar fixtures como materiais do exemplo ou da biblioteca.
- Exemplo com planejamento válido, referências pendentes, `generation_ready: false`, orçamento zero e nenhum envio.
- Sem instalação global de skills, modelos, APIs próprias, extensões, serviços ou interfaces locais.

O resultado executado e os logs ficam em [verification.json](../reports/verification.json). Testes aprovados verificam contratos locais; não comprovam qualidade visual ou redução de alucinações.

## O que depende de uma produção real

Um brief e o pedido de imagens permitem criar os primeiros candidatos pelo gerador integrado do Codex. A aprovação visual permite promover versões à biblioteca. O custo ou limite desse gerador não é inferido nem contabilizado como crédito do Flow.

Gerar vídeo exige autorização real de orçamento e conferência dos recursos da conta no Chrome: modelo, modo, duração, proporção, resolução, áudio, quantidade e custo. A configuração inicial mantém zero créditos no Flow. Não há comprovação de operação da interface nesta entrega, nem atualização artificial da data de capacidades.

Clipes reais permitem validar identidade, movimento, áudio, emendas e eficácia do método. Até lá, taxas de aprovação e custo por segundo aprovado permanecem indisponíveis. Alertas de preto, silêncio e imobilidade auxiliam a revisão e precisam de interpretação conforme o brief.

As sete etapas acima não requerem GPU ou modelo local. A [pós-produção opcional com Tesseract](pos-producao.md) usa o renderizador local e recursos gráficos compatíveis, com ferramentas isoladas e versões fixadas. Tempo de processamento, memória e espaço para evidências de vídeos longos dependerão dos arquivos futuros; os testes técnicos não são um benchmark de capacidade do computador.
