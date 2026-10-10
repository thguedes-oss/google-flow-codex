# Métricas com dados reais

Use `scripts/metrics.py --project projects/meu-video` para ler o relatório JSON. Acrescente `--write` para salvar uma execução nova com JSON e Markdown em `outputs/metrics/`. O comando não altera tentativas, decisões, orçamento ou mídia.

- **Cobertura de revisão:** tentativas com fechamento formal válido dividido por todas as tentativas registradas. Sem tentativas: indisponível.
- **Aprovação na primeira tentativa:** primeira linha registrada por cena na ordem de anexação do CSV. Inclui falhas reconciliadas como resultado negativo e vídeos completed com revisão formal conclusiva. Tentativas pendentes, desconhecidas, sem custo reconciliado ou sem decisão conclusiva são excluídas; o relatório mostra denominador e exclusões.
- **Defeitos:** por critério, conta severidade 1 e 2 da revisão formal mais recente de cada tentativa; mostra também quantas observações não-NA existem. Ausência de revisão não significa ausência de defeitos.
- **Créditos por segundo aprovado:** todos os gastos conhecidos do projeto divididos pela duração real dos clipes aprovados explicitamente selecionados por cena. Nunca soma duas alternativas da mesma cena. Duas seleções simultâneas exigem reconciliação: feche uma nova revisão da alternativa antiga com `selected: false`, informando `supersedes`.
- **Dados incompletos:** gastos pendentes/desconhecidos ou duração selecionada ausente tornam a razão de custo indisponível. Créditos conhecidos são apresentados como parcela conhecida, não total final.
- **Imagens do Codex:** conta saídas `image_gen` efetivamente registradas como candidatas. Isso não mede quantidade de chamadas. Custos não informados continuam desconhecidos, separados dos créditos do Flow.

Compare produções de mesmo brief, modelo, proporção, duração, resolução, referências e plano de áudio. Mantenha uma mudança principal por tentativa. `scripts/flow_review.py compare --project projects/meu-video --left tentativa-001 --right tentativa-002` mostra condições congeladas, diff do prompt e decisões disponíveis; não escolhe vencedor nem gera versões.

Diferenças na condição invalidam uma comparação controlada. Mesmo condições registradas iguais não garantem determinismo do serviço. A versão interna do modelo e outros fatores podem não ser observáveis. Não atribua melhora ao projeto com base em testes de código, clipes sintéticos ou uma avaliação isolada.

O exemplo permanece sem tentativas e sem imagens. Seu relatório mostra valores indisponíveis onde faltam resultados. VBench, modelos de avaliação, serviços externos e novas dependências ficam fora desta implementação.
