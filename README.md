# Google Flow com direção pelo Codex

Base reutilizável para dirigir vídeos no Flow, criar referências pelo gerador de imagens integrado do Codex, organizar uma biblioteca visual aprovada e revisar cada resultado. **Orçamento inicial no Flow: zero créditos. Nenhum vídeo ou imagem de produção foi gerado nesta configuração.**

O guia [google-flow-scripting-skill v1.6.0](https://github.com/agbelemi/google-flow-scripting-skill/releases/tag/v1.6.0) está em `vendor/google-flow-scripting-skill`, fixado no commit `2d6f1675c901d589300558cfd8a486046c9cdc47`. Sua licença MIT está preservada. `sources.lock.json` registra a origem; não instalamos uma skill global nem automação de terceiros.

## Baixar e preparar uma cópia

Este repositório é público: você pode compartilhar [o link do projeto](https://github.com/thguedes-oss/google-flow-codex) para leitura, download ou clonagem, sem convite.

No Windows, com Git, PowerShell e Python **3.12** instalados:

```powershell
git clone https://github.com/thguedes-oss/google-flow-codex.git
Set-Location google-flow-codex
```

Antes de executar `scripts/check.ps1`, siga o [guia de preparação de um checkout novo](workflow/instalacao.md) para recuperar as fontes nas versões de `sources.lock.json`. A pasta `vendor/`, as ferramentas portáteis em `.work/` e as mídias locais não acompanham o clone. O snapshot web histórico da wiki Claudia depende dos bytes preservados; baixar as páginas atuais pode não reproduzir seus hashes. Sem essas fontes, a verificação completa apontará pendências, mesmo que a documentação esteja disponível para consulta.

Depois da preparação, execute `.\scripts\check.ps1`. No exemplo incluído, o resultado esperado é `planning_passed=true, generation_ready=false`: não há referências aprovadas nem autorização para gastar créditos. Para trabalhar pelo Codex, abra a pasta clonada e peça a direção pelo chat, conforme as instruções abaixo.

As atribuições e licenças dos materiais de terceiros estão preservadas em seus arquivos e em `sources.lock.json`; a publicação não atribui uma licença única ao conjunto.

## Começar pelo chat

Peça ao Codex: **“Quero um vídeo sobre [ideia] para [público/destino]. Escolha a direção e prepare o que for possível sem gastar créditos.”** A [direção contextual](workflow/direcao-contextual.md) é o padrão: o Codex consulta o contexto, organiza narrativa, referências, planos, câmera, continuidade, som, gráficos e montagem. Escolhe técnicas pela função de cada cena, inclusive sem efeito, preenche os arquivos técnicos e apresenta as escolhas relevantes em linguagem comum. Para produzir, informe também o orçamento autorizado e forneça ou aprove os materiais visuais.

Você não precisa escolher shaders, preencher JSON ou calcular frames. Pedidos como **“mais sóbrio”**, **“mais dinâmico”** ou **“destaque o produto”** são traduzidos para mudanças concretas pelo Codex e demonstrados nas prévias disponíveis. O [plano editorial](templates/plano-editorial.md) distingue suas solicitações, escolhas do Codex, observações da mídia e aprovações reais. Projetos existentes conservam suas decisões e versões; detalhes ausentes continuam pendentes quando impedem a execução.

Quando houver um brief real, peça **“Crie as referências necessárias para este vídeo pelo seu gerador de imagens e apresente-as para minha aprovação; mantenha zero créditos no Flow.”** O Codex gera no chat, salva as imagens reais no projeto e registra candidatos. Só os materiais aprovados entram na biblioteca. Não há geração local, API própria, formulário local, Flow Tool ou modelos instalados.

- [Imagens pelo Codex](workflow/imagens-codex.md): criação, edição, inspeção e aprovação de referências.
- [Biblioteca visual](workflow/biblioteca.md): candidatos, versões aprovadas e cópias por vídeo.
- [Continuidade e frames](workflow/continuidade.md): cortes deliberados, slots e passagem entre clipes.
- [Direção por plano](workflow/direcao.md): intenção observável, identidade por enquadramento, decisões por cena e revisão contra o brief.
- [Direção contextual](workflow/direcao-contextual.md): escolhas e execução pelo Codex a partir do pedido, com plano editorial e revisão conforme o material real.
- [Tentativas congeladas](workflow/tentativas.md): preservar exatamente o que foi enviado.
- [Métricas](workflow/metricas.md): dados reais, custos desconhecidos e comparações.
- [Pós-produção com Tesseract](workflow/pos-producao.md): montagem local editável, textos, áudio, capas e exportação Adobe opcional; ferramentas isoladas e versões fixadas.
- [Entrega das sete melhorias](workflow/implementacao.md): dependências, validação e condições para produção real.

- [Exemplo de duas cenas](projects/exemplo-duas-cenas/README.md): duas cenas de 8 segundos, com a personagem Lia, um café e uma caneca; referências ainda pendentes.
- [Operação e preflight](workflow/operacao.md): preparação, vinculação real de referências no Chrome e registro de tentativas.
- [Capacidades verificadas](workflow/capacidades.md): documentação oficial de 6 de outubro de 2026, com diferenças em relação ao guia.
- [Revisão visual](workflow/revisao.md): critérios de aceitação e medição de continuidade.
- [Fichas visuais](workflow/fichas-visuais.md): modelos de personagem, cenário e objeto e preparação de referências.
- [Fontes complementares](workflow/fontes.md): cinco fontes de técnicas, notebook do Google e snapshot da wiki Claudia, com origem, atribuição, direitos e hashes.
- [Verificação local](reports/verification.json): resultado das checagens realizadas, separado da prontidão para gerar.
- [Manutenção e recuperação](workflow/manutencao.md): auditoria histórica, relatórios por execução, reconciliação e backup.

## Conhecimento e técnicas de produção

Consulte a adaptação em português das cinco fontes antes de escolher uma técnica: [pré-produção](workflow/conhecimento/pre-producao.md), [direção](workflow/conhecimento/direcao.md), [geração Flow](workflow/conhecimento/geracao-flow.md), [continuidade](workflow/conhecimento/continuidade.md), [montagem](workflow/conhecimento/montagem.md), [áudio](workflow/conhecimento/audio.md), [gráficos](workflow/conhecimento/graficos.md) e [revisão](workflow/conhecimento/revisao.md). O [brief](templates/creative-brief.md), as [32 fichas](workflow/tecnicas.md) e o [relatório de cobertura](reports/knowledge-coverage.md) ligam decisões a situações, limites e critérios de revisão.

O [catálogo nativo](resources/techniques/catalog.json) e o [catálogo individual de 125 transições GL](resources/gl-transitions/catalog.json) registram IDs/parâmetros; disponibilidade depende do estado e dos testes do formato real. Veja [exemplos de técnicas](workflow/pos-producao.md#tecnicas-em-janelas-existentes). Planejamento, catálogo e render não aprovam material nem autorizam geração; Flow permanece com orçamento inicial zero.

O [relatório da incorporação](reports/incorporation-final.md) reúne inventário, provas de execução, limitações e itens ainda incompletos. As [receitas locais](resources/techniques/README.md) ligam cada ID nativo aos casos de teste; a [biblioteca GL](resources/gl-transitions/README.md) registra licenças, parâmetros, publicação e particularidades de transparência.

## Verificar no Windows

No PowerShell, dentro desta pasta:

```powershell
.\scripts\check.ps1
```

O executor procura um Python **3.12** já instalado, inclusive os runtimes do uv. Se necessário, use `-Python 'C:\caminho\python.exe'`. Não instala dependências nem chama o Flow. O launcher `py -3.12` não encontrou o runtime Astral desta máquina; o executor usa o executável detectado diretamente.

```powershell
# Outro projeto, apenas suas checagens e a integridade da base:
.\scripts\check.ps1 -Project projects/meu-video -SkipUpstreamTests
# Exigir também todas as condições de prontidão:
.\scripts\check.ps1 -RequireReady
# Prontidão apenas de uma cena; validação estrutural de todo o projeto:
.\scripts\check.ps1 -Project projects/meu-video -Scene 01 -RequireReady
```

O exemplo deve passar nas checagens de planejamento e continuar com `generation_ready: false`. `-RequireReady` deve falhar enquanto referências, vinculações, custo, verificação da interface e orçamento estiverem pendentes. Cada execução preserva relatório e logs em `reports/runs/ID/`; `reports/verification.json` aponta para o último resultado completo. O check inclui integridade do histórico, sem reparar ou aprovar registros automaticamente.

Para auditar somente snapshots, decisões, selos e CSVs, sem escrever arquivos, use `scripts/flow_review.py audit --project projects/meu-video` com Python 3.12. Consulte [manutenção](workflow/manutencao.md) para interpretar erros, avisos e interrupções.

## Criar outro projeto

Copie `projects/exemplo-duas-cenas` para `projects/nome-do-video`. Ajuste o brief, as fichas e todos os campos do `project.json`, sem herdar aprovações ou evidências. Guarde as imagens reais em `assets/` e os resultados em `outputs/`; estes arquivos de mídia ficam fora do Git por padrão. Registre arquivos aprovados e seus hashes no manifesto.

O fluxo é **brief → imagens pelo Codex → aprovação e biblioteca → storyboard e prompts → tentativa congelada → geração autorizada no Flow → reprodução e revisão → ajuste específico**. Os prompts de storyboard existentes são textos preparados; nenhuma prancha visual foi gerada. Imagens pelo Codex e créditos do Flow são registrados separadamente.

No planejamento de cada cena, preencha `direction` no plano de revisão existente com função, ação/resultado, intenção da câmera e gráficos previstos ou ausentes. A direção acompanha o congelamento e aparece como `expected_direction` nas evidências; nesse caso, o fechamento exige uma observação humana em `intent_review`. Registros antigos sem direção continuam compatíveis. Use `templates/decisoes.md` para preservar decisões reais por cena.

Quando o pedido já abranger o vídeo final, o Codex segue para a montagem dos clipes elegíveis dentro do escopo autorizado, sem exigir outro comando ou aprovação de cada parâmetro. Para pedir somente uma montagem: **“Monte os clipes aprovados deste vídeo no Tesseract e apresente uma prévia.”** A pós-produção usa um plano separado, mantém a fonte `.tsrct` editável e exige revisão da montagem. Também permite animatics com imagens aprovadas e peças gráficas. O exemplo contém apenas `postproduction.json` pendente; a integração não produz piloto. Consulte o procedimento para os limites reais de resolução do motor 0.3.1.

## Reproduzir a cópia da base

Em um checkout novo, com `vendor/google-flow-scripting-skill` ainda ausente:

```powershell
git -c core.autocrlf=false clone --branch v1.6.0 --depth 1 https://github.com/agbelemi/google-flow-scripting-skill.git vendor/google-flow-scripting-skill
git -C vendor/google-flow-scripting-skill config --local core.autocrlf false
git -C vendor/google-flow-scripting-skill rev-parse HEAD
.\scripts\check.ps1
```

Confira o commit com `sources.lock.json`. A pasta `vendor/` contém cópias independentes ignoradas pelo Git deste projeto. No Windows, preserve finais de linha LF para que os bytes confiram com o `MANIFEST.json` original. Não regenere o manifesto para esconder diferenças. Reproduza também as fontes complementares, incluindo o snapshot web datado, conforme [fontes complementares](workflow/fontes.md) antes da verificação completa.

## Preparar a revisão de um clipe

Quando houver um vídeo local de uma tentativa real registrada como `completed`, peça: **“Prepare as evidências de revisão da tentativa [ID] do projeto [nome].”** O Codex executará a ferramenta local com Python 3.12, FFmpeg e FFprobe já disponíveis. Não há instalação de pacotes nem acesso ao Flow.

```powershell
# Use o executável Python 3.12 mostrado por scripts/check.ps1.
& 'C:\caminho\python.exe' scripts/review_clip.py --project projects/meu-video --attempt tentativa-001
```

Cada execução salva PNGs de início, aproximadamente 25%, meio, 75% e último frame real; uma prancha cronológica; e um JSON de metadados, timestamps e hashes em uma pasta nova dentro de `outputs/review/`. Clipes curtos podem ter menos de cinco imagens distintas. O vídeo, os CSVs, o orçamento e as aprovações permanecem intactos. A prancha auxilia a inspeção; reproduzir o clipe completo com áudio continua obrigatório. O exemplo ainda não possui tentativas ou vídeos para revisar.

## Limite da proposta

Os testes avaliam código e estrutura do pacote. Não medem a qualidade de vídeos. A combinação de referências, estados explícitos e revisão tem como objetivo reduzir variações evitáveis; sua eficácia só poderá ser avaliada depois de gerar e comparar clipes. O preflight é uma lista verificável, não um bloqueio técnico de gastos no site.
