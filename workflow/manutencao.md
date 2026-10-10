# Manutenção, diagnóstico e recuperação

Use Python 3.12 já instalado. A manutenção não instala ferramentas, atualiza fontes, gera mídia ou autoriza créditos. Planejamento válido, prontidão para gerar e aprovação visual continuam sendo resultados distintos.

## Check geral e auditoria histórica

Execute `scripts/check.ps1 -Project projects/meu-video` para conferir a base, os testes, os prompts e o histórico daquele projeto. A checagem `record-integrity` executa a auditoria histórica. Erros de integridade fazem o check falhar; os bloqueios de produção continuam sendo apresentados separadamente. `-RequireReady` exige também prontidão para gerar.

Para inspecionar somente os registros, sem escrever relatório ou executar FFmpeg, Tesseract ou ferramentas de rede:

```powershell
# Use o executável Python 3.12 informado por scripts/check.ps1.
& 'C:\caminho\python.exe' scripts/flow_review.py audit --project projects/meu-video
```

O comando retorna JSON com `schema_version: 1`, `passed`, `counts`, `errors` e `warnings`. Cada ocorrência informa `code`, `path` relativo ao projeto e `message`. O código de saída é 0 sem erros e 1 quando há erros. Um histórico vazio é válido, com contagens zero; isso não comprova produção ou revisão.

A auditoria lê `attempts.csv`, `review.csv`, snapshots, decisões, selos, vídeos e evidências de revisão de clipes. Confere hashes, vínculos e cadeias de revisão, incluindo registros anteriores que não estejam selecionados. Não modifica CSVs, remove locks, recompõe selos, escolhe resultados ou acessa o Flow. A biblioteca tem sua checagem própria; planos, renders e pacotes de pós-produção continuam sujeitos aos verificadores de Tesseract antes de seu uso.

| Resultado | Interpretação |
|---|---|
| CSV ambíguo, hash divergente, pacote parcial, registro órfão ou lock existente | Erro; investigar a operação e preservar os arquivos |
| Tentativa pending/unknown ou gasto ausente | Aviso da auditoria; o preflight continua bloqueando novos envios |
| Tentativa antiga sem snapshot | Aviso de compatibilidade; não inventar um congelamento retroativo |
| Evidências sem fechamento formal | Aviso; nenhuma aprovação é inferida |
| Decisão substituída com cadeia íntegra | Aviso informativo; a decisão anterior é preservada e não é a vigente |
| Extração com `failure.json` válido | Aviso; arquivos parciais não são evidências concluídas |

Um erro pode aparecer em vários vínculos: alterar um PNG, por exemplo, invalida seu relatório e a decisão que o utiliza. Corrija a causa identificada, sem editar hashes para fazer a auditoria passar.

## Relatórios preservados por execução

Cada check usa uma pasta exclusiva `reports/runs/ID/`, com logs e `verification.json`. O ID inclui horário UTC e um componente aleatório; o relatório identifica o projeto e aponta para os logs daquela execução. Rodar o check de outro projeto não substitui esses arquivos.

`reports/verification.json` permanece como acesso à última execução completa publicada, inclusive quando o resultado das checagens for uma falha. A publicação é atômica e acontece depois de arquivar o relatório. Uma interrupção anterior à conclusão pode deixar uma pasta sem `verification.json`; ela não substitui o último resultado completo.

Relatórios anteriores ao versionamento são copiados, com seus logs existentes, para uma pasta `legacy-ID` antes da substituição do acesso à última execução. Seus campos de caminho mantêm o formato original; os logs planos antigos também permanecem no local anterior. Não use a data de um relatório antigo como comprovação de prontidão atual.

## Reconciliar uma interrupção

1. Preserve CSVs, pacote parcial, mídia, evidências e logs antes de editar qualquer registro. Identifique a tentativa e a última operação iniciada.
2. Se houver envio pendente, resultado desconhecido ou gasto ausente, confira o resultado real e o gasto no Flow pelo Chrome. Não reenvie para descobrir o que aconteceu.
3. Compare os arquivos congelados, os campos originais da tentativa e os selos. Um pacote incompleto não permite usar silenciosamente o manifesto atual. Não recrie um selo para esconder alteração de bytes.
4. Para `outputs/.records.lock`, confirme se existe uma operação ativa. O arquivo pode representar trabalho em andamento ou interrupção; sua presença não prova que esteja obsoleto. Só reconcilie sua remoção depois de esclarecer o estado dos registros.
5. Execute novamente a auditoria e o check. Uma mudança deliberada de prompt, referência ou plano pede uma nova versão/tentativa e novo preflight, conforme o procedimento operacional.

Uma tentativa com snapshot íntegro pode ser revisada mesmo se o `project.json` atual estiver ausente ou ilegível: a revisão usa o manifesto congelado verificado. Registros antigos sem pacote de congelamento dependem do manifesto atual. Isso não dispensa corrigir o manifesto para planejar novos envios.

Mudanças em aprovações usadas pela montagem exigem uma nova revisão de pós-produção. Preserve a fonte `.tsrct`, seus recursos e os pacotes Adobe completos; não ajuste a versão anterior para acomodar uma reprovação posterior.

## Backup e versionamento

O Git local ainda não tem commits, identidade ou remoto configurados. O checkup não configura identidade, cria repositório remoto ou publica arquivos. Até existir histórico versionado, preserve a cópia anterior às alterações, o manifesto de hashes e o diff em `.work/checkup-2026-10-08/`.

Uma cópia dentro da própria pasta ajuda a recuperar edições, mas não substitui um backup em destino separado sob controle do usuário. Inclua:

- Código, instruções, configuração, templates, manifestos, CSVs e relatórios arquivados.
- `projects/*/assets/`, `projects/*/outputs/` e `library/assets/`, com imagens, clipes, decisões, evidências e fontes editáveis.
- Snapshots fixados em `vendor/`, especialmente os bytes da wiki Claudia: URLs e hashes não recuperam uma página que mudou. Preserve atribuições e observe os direitos antes de redistribuir.
- Ferramentas portáteis, versões anteriores e materiais necessários em `.work/`; essa pasta contém mais que caches descartáveis.
- Pacotes Adobe completos, incluindo mídias, fontes, avisos e logs associados.

Não apague o destino anterior ao criar outra cópia. Compare hashes e confira os registros em uma cópia de restauração antes de considerá-la recuperável. Um catálogo ou hash isolado não recupera pixels, áudio ou vídeo perdido. Ao versionar futuramente, revise arquivos e direitos antes de enviar; mídias e fontes ignoradas precisam de backup separado.

## Limitação conhecida de exportação

Na combinação portátil Tesseract 0.3.1 / Converter 0.2.1, o smoke test existente registrou falha na conversão para Premiere de uma composição híbrida com texto/gráficos, envolvendo `media/ae-0001/compositions.aep`. Esse pacote parcial não é uma entrega válida. Conversões nativas mais simples e a exportação para After Effects tiveram verificações técnicas distintas; abertura e fidelidade nos aplicativos Adobe permanecem não verificadas.

Consulte [pós-produção](pos-producao.md) e preserve o relatório `reports/tesseract-smoke.json`. O checkup de registros não altera essas versões nem resolve a falha do conversor. Não elimine gráficos, amplie pixels ou substitua o pacote silenciosamente para apresentar uma conversão como bem-sucedida.
