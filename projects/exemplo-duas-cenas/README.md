# Exemplo: Lia no café

**Preparação local: duas cenas de 8 segundos. Zero créditos autorizados.** Nenhuma imagem, prancha visual ou vídeo existe ainda. O exemplo é um exercício de continuidade com uma personagem fictícia, um cenário fixo e um objeto.

Cena 1: Lia olha para a janela e volta o olhar para a frente. Cena 2: após um corte, ela sorri suavemente, olha a caneca e volta a olhar para a frente. Durante os dois clipes, fica sentada e mantém a caneca na mão direita, na altura do peito.

## Ficha fixa

- **@Lia**: mulher adulta fictícia, cerca de 30 anos; rosto oval, olhos castanhos, cabelo preto liso até os ombros com risca central; camisa azul-marinho de mangas longas; sem joias. A imagem aprovada terá precedência sobre essa descrição inicial.
- **@Cafe**: café vazio; mesa retangular de madeira no primeiro plano; janela à esquerda da imagem; parede verde-clara ao fundo; uma planta à direita do fundo. Luz diurna difusa vindo da janela. Uma câmera frontal fixa na altura dos olhos.
- **@Caneca**: uma única caneca de cerâmica branca, lisa, sem marca; alça voltada à direita da imagem; sustentada pela mão direita de Lia, perto do peito. Mão esquerda repousando na mesa.

## Materiais preparados

| Material | Arquivo | Situação |
|---|---|---|
| Referências e estados | `project.json`, `assets/README.md` | Imagens, aprovação e hashes pendentes |
| Fichas visuais | [Lia](fichas/lia.md), [café](fichas/cafe.md), [caneca](fichas/caneca.md) | Especificação desejada; aparência observada e aprovação pendentes |
| Textos para imagens | [Referências e imagem de abertura](prompts/referencias.md) | Apenas prompts preparados, sem envios |
| Storyboard da cena 1 | `storyboards/cena-01.json` e `.md` | Três painéis descritos; nenhuma prancha gerada |
| Storyboard da cena 2 | `storyboards/cena-02.json` e `.md` | Três painéis descritos; nenhuma prancha gerada |
| Prompts | `prompts/cena-01.md`, `prompts/cena-02.md` | Textos autossuficientes; preflight no Flow pendente |
| Momentos de revisão | `review-plans/cena-01.json`, `review-plans/cena-02.json` | Pontos planejados para a extração ampliada; nenhuma evidência produzida |
| Direção por plano | `direction` nos mesmos planos de revisão | Função, ação/resultado, câmera fixa e ausência de gráficos; apenas planejamento |
| Tentativas e revisão | `attempts.csv`, `review.csv` | Apenas cabeçalhos, sem resultados simulados |
| Pós-produção | `postproduction.json` | Plano separado pendente, sem clipes, recursos ou entrega definidos |

## Passagem entre cenas

O corte mantém a entrada da cena 2 igual à saída planejada da cena 1: Lia sentada, cabeça frontal, expressão neutra, caneca na mão direita à altura do peito, mão esquerda na mesa. Não há troca de mão ou deslocamento de objetos.

Antes da cena 2, compare a saída **real** da cena 1 com esse estado. Se houver defeito, rejeite ou ajuste a cena 1. Não declare continuidade apenas porque os dois prompts coincidem. Se escolher uma passagem contínua por frame inicial em vez do corte com referências, revise modo, materiais e storyboard antes de gerar.

O perfil proposto é Veo 3.1 Fast / Elementos / 8 s / 16:9 / um resultado por tentativa. Os nomes @Lia, @Cafe e @Caneca são identificadores locais; crie/selecione os ativos correspondentes e confira sua ligação real no Flow. Modelo, custo e slots da conta continuam pendentes de conferência.

O manifesto já descreve intenção de áudio ambiente; a resolução permanece pendente. As [sete melhorias da base](../../workflow/implementacao.md) estão disponíveis para futuros projetos, sem transformar este exemplo em piloto produzido.

A [direção por plano](../../workflow/direcao.md) explicita somente a intenção deste exercício de continuidade. A direção será congelada junto com cada tentativa e aparecerá em `expected_direction` nas evidências; o fechamento então exigirá `intent_review` real. Não há decisão visual, preferência estética nova ou aprovação inferida desses textos.

Depois de existir material aprovado, a [pós-produção com Tesseract](../../workflow/pos-producao.md) permite pedir pelo chat montagem, títulos, legendas conferidas, áudio e capas editáveis. A montagem recebe suas próprias versões e revisão; o plano pendente deste exemplo não autoriza produção.

## Preparar evidências depois da produção

Quando houver uma tentativa real `completed` e um vídeo dentro de `outputs/`, peça ao Codex a extração de evidências daquele ID. A [ferramenta local](../../workflow/revisao.md#evidências-locais-com-ffmpeg) prepara frames reais e prancha, preservando vídeo, tentativas e decisões. Até lá, não crie linhas simuladas neste exemplo nem use os fixtures técnicos dos testes como referências.
