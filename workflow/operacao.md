# Operação supervisionada

## 1. Brief e referências

Conduza o pedido conforme [direção contextual](direcao-contextual.md). O Codex consulta o contexto, preenche o [plano editorial](../templates/plano-editorial.md) e escolhe soluções rotineiras sem exigir decisões técnicas do usuário. Registre quais escolhas são do Codex, sem convertê-las em preferências, observações ou aprovações do usuário. Em retomadas, preserve decisões e versões existentes.

Defina objetivo, público, duração, proporção, idioma e o que será observável no resultado. Identifique personagens, cenário e objetos importantes. Use a pasta de um projeto por vídeo; mantenha os estados em `project.json`.

Siga [direção por plano](direcao.md): defina a função de cada plano, ação e resultado observável, motivo da câmera e composição para textos/gráficos. Registre a escolha real de cor/textura e preserve decisões por cena, usando `templates/decisoes.md`. Planeje ritmo, emendas e quadro final antes dos prompts; sem materiais aprovados, essa preparação continua textual.

Prepare imagens canônicas: personagem com rosto e roupa legíveis; cenário sem pessoas extras; objeto com forma e cor claras. Confira direitos e aprovação no contexto do material fornecido. Salve a versão e o SHA-256 do arquivo aprovado. Se não houver material aprovado, prepare apenas o plano das imagens e mantenha `approved: false`.

Use as [fichas visuais](fichas-visuais.md) para separar especificação desejada, aparência observada e aprovação real. Guarde fichas por handle em `fichas/` dentro do vídeo. O manifesto continua sendo o registro operacional; compare-o com as fichas e os prompts antes do envio. Imagens de cena e vistas adicionais são opcionais e precisam de orçamento e aprovação próprios. Confira as [fontes complementares](fontes.md) somente como referência, sem executar seus instaladores ou notebooks.

Para criar referências, use o [gerador integrado do Codex](imagens-codex.md) e a [biblioteca versionada](biblioteca.md). Esta base não cria mídia automaticamente. O pedido de imagens do vídeo real é separado do orçamento do Flow.

## 2. Storyboard e estados

Planeje geração e montagem juntas: função dos planos, composição, ação, som, textos, ritmo e passagem. A técnica pode ser **sem efeito**, com justificativa. Transponha a direção editorial para manifesto, storyboard e plano de revisão; o Markdown não altera esses arquivos por si só. Tempos finais e efeitos serão reconferidos após obter o material real.

Escolha poucas ações por clipe. Registre `state_in` e `state_out`, inclusive mão, orientação e quantidade dos objetos. Em um corte sem mudança narrativa, o estado final deve coincidir com a entrada seguinte. Mudanças deliberadas devem ser descritas e revisadas explicitamente; não esconda uma diferença alterando o estado esperado para acomodar um defeito.

Registre cortes deliberados, slots e passagem conforme [continuidade](continuidade.md). Prepare também momentos de revisão por cena. Use `-Scene ID` no executor quando a prontidão for de uma cena; a estrutura completa continua sendo validada.

No plano de revisão existente, `direction` reúne `purpose`, `action_result`, `camera_intent` e `graphics_intent`. Quando presente, os quatro campos exigem textos não vazios; declare a ausência de gráficos explicitamente. Relacione os momentos à intenção observável e confronte-a com os estados e o storyboard, sem inventar ações para completar o formulário. Registros antigos podem omitir `direction`.

Prepare o storyboard em JSON e seus prompts. O gerador upstream apenas escreve texto:

```powershell
# Use o executável Python 3.12 encontrado por scripts/check.ps1.
& 'C:\caminho\python.exe' vendor/google-flow-scripting-skill/scripts/generate_storyboard_prompt.py projects/meu-video/storyboards/cena-01.json --output projects/meu-video/storyboards/cena-01.md
```

A frase inicial desse prompt pede geração de uma imagem quando for enviada a um modelo. Preparar o arquivo não executa esse pedido. Com orçamento zero, revise os três painéis descritos; a imagem de storyboard continua pendente. Não anexe uma contact sheet inteira como frame inicial: selecione e aprove o painel correto.

## 3. Preflight local

Execute `scripts/check.ps1 -Project projects/meu-video`. Corrija problemas estruturais e examine os bloqueios de prontidão. O executor verifica commit, manifesto, compatibilidade documentada, estados de passagem, arquivos, hashes e lint dos prompts. Ele não confirma se o Flow recebeu as referências e não detecta alucinações visuais.

O check inclui a auditoria histórica de snapshots, decisões, selos e CSVs. Cabeçalhos duplicados e linhas com campos ausentes ou excedentes falham antes do cálculo de créditos. Campos obrigatórios de motivo, revisor, vinculação e idioma exigem texto real, não somente espaços; informações de revisão ainda pendentes continuam bloqueando prontidão. Relatórios e logs são preservados por execução conforme [manutenção](manutencao.md).

## 4. Preflight no Chrome

Quando houver autorização de produção:

1. Abra o projeto correto no Flow pelo Chrome. Confira as configurações atuais de vídeo e o custo para a quantidade total de resultados.
2. Vincule cada referência real usando Elementos/Adicionar ou o seletor de ativos por `@`. Compare as miniaturas/ativos selecionados com os arquivos aprovados. Registre em `bindings` um nome/identificador observável, SHA-256 do arquivo e evidência visual da seleção.
3. Em Frames, confirme os slots inicial e final. Em continuação, inspecione e registre o frame real de saída do clipe aprovado antes de colocá-lo no slot inicial. Uma descrição textual não substitui esse frame.
4. Confira que prompt, imagens, estados, proporção e ação não se contradizem. Registre data e evidência da interface, custo por resultado e resultados por tentativa. As evidências devem mostrar os controles e referências, sem expor dados de autenticação.
5. Registre a autorização real e o teto de créditos no manifesto. Execute o preflight local para a cena e copie seu `plan_sha256` para `generation.ui_plan_sha256` somente depois de conferir na interface aqueles arquivos e parâmetros, incluindo resolução e áudio. Execute `-Scene ID -RequireReady`. Congele a tentativa conforme [tentativas](tentativas.md), verifique o pacote e passe somente o `submitted_prompt.txt` ao Flow pelo Chrome.

Esses registros valem para os arquivos e configurações conferidos. Se trocar modelo, modo, referências ou quantidade, refaça o preflight correspondente.

Formato de uma vinculação registrada em `scenes[].bindings`: `"@Lia": {"flow_asset": "nome ou ID observado no Flow", "sha256": "hash do arquivo aprovado", "evidence": "outputs/preflight-cena-01.png"}`. `generation.ui_evidence` também aponta para uma evidência local, e `ui_verified_on` usa `AAAA-MM-DD` do dia da produção. Não preencha esses campos com valores fictícios.

## 5. Tentativas e revisão

Use o congelamento para criar a linha `pending` em `attempts.csv` antes de enviar, com prompt/referências usados e custo esperado. Use estados `pending`, `completed`, `failed` ou `unknown`. Depois, registre o gasto observado e o arquivo/ID do resultado. Um status desconhecido ou gasto em branco exige reconciliação antes de repetir. A verificação do snapshot não envia nem autoriza repetir a tentativa.

Reproduza o clipe, confira frames de início/meio/fim e a passagem para a cena seguinte. Preencha `review.csv` seguindo `revisao.md`. Dê prioridade a defeitos de identidade e cenário. Ajuste uma causa por tentativa para saber qual mudança ajudou. Aprovar uma nova tentativa não apaga as anteriores.

Compare também com o brief e a direção congelada da tentativa. Se o relatório contiver `expected_direction`, o fechamento exige `intent_review` com observação real sobre o resultado, mesmo em rejeição. Cumprir um prompt insuficiente não resolve automaticamente a intenção do plano.

Para organizar as evidências de uma tentativa `completed` com vídeo baixado em `outputs/`, use `scripts/review_clip.py --project projects/nome-do-video --attempt ID` com o Python 3.12. A ferramenta usa os índices e timestamps dos frames reais, preserva o arquivo original e escreve em uma nova subpasta de `outputs/review/`. Ela não confirma aprovação visual, gasto ou vinculação no Flow. Veja o procedimento detalhado em [revisão local](revisao.md#evidências-locais-com-ffmpeg).

Não gere lotes, variações automáticas ou refaça envios de resultado desconhecido. Gere uma tentativa por vez dentro do orçamento autorizado e custo confirmado.

## Arquivos e status

Depois da aprovação dos clipes, siga [pós-produção local](pos-producao.md) para montagem, texto, áudio, animações e peças gráficas. O plano `postproduction.json` e as revisões em `outputs/postproduction/` ficam separados dos dados de geração. Uma montagem renderizada ainda precisa de inspeção e decisão próprias.

Se o pedido já inclui a entrega do vídeo e a montagem está dentro do escopo autorizado, prossiga pelas etapas elegíveis e apresente prévias sem pedir outro comando. A autonomia para escolhas rotineiras não dispensa referências/aprovações reais, orçamento e reconciliação. Revise o editorial quando a mídia exigir outra solução e preserve a versão anterior.

- `plano-editorial-vN.md`: visão geral e decisões por cena, com origem dos registros; não é manifesto executável nem aprovação.
- `assets/`: arquivos visuais reais e aprovados, quando existirem.
- `fichas/`: especificação desejada, detalhes pendentes e inspeção dos materiais por handle.
- `storyboards/`: especificações e prompts preparados; mídia visual precisa de geração/autorização própria.
- `prompts/`: texto por cena com versão.
- `project.json`: modelo proposto, referências, estados, orçamento e evidências de preflight.
- `attempts.csv`: histórico de envios e créditos reais.
- `review.csv`: inspeção visual e decisões; nenhuma linha simulada é aprovação.
- `outputs/`: resultados e evidências locais.

`planning_passed` significa que as checagens locais de estrutura passaram. `generation_ready` exige também as condições registradas de produção. **Nenhum dos dois significa que um vídeo foi gerado ou aprovado visualmente.**
