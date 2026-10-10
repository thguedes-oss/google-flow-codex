# Tentativas e snapshots

O plano de revisão congelado também inclui `direction`, quando presente. Seu hash já faz parte de `plan_sha256`; não é necessário outro manifesto. A extração posterior usa essa cópia para `expected_direction`, inclusive sem `--enhanced`. Preserve a intenção original ao revisar uma tentativa antiga, mesmo que o planejamento atual tenha mudado. Veja [direção por plano](direcao.md).

Os comandos são locais e não enviam nada ao Flow. Use Python 3.12 e mantenha os cabeçalhos atuais de `attempts.csv` e `review.csv`.

## Antes do envio

1. Obtenha autorização real de produção no Flow, materiais aprovados, modelo/modo compatíveis e custo confirmado para a quantidade escolhida.
2. Confira a cena pelo Chrome: referências ou slots, prompt, duração, proporção, resolução e áudio. `generation.resolution` guarda a resolução vertical observada, como 720; `null` permanece pendente. `generation.audio` descreve a intenção (`ambient`, `dialogue`, `silent` ou `music`) e, para diálogo, `language`. Descrever silêncio não garante que o modelo não gere áudio.
3. Execute o preflight com `--scene ID`, registre o hash após a conferência da interface e exija prontidão. Data da documentação e data da inspeção são evidências distintas; não preencha uma a partir da outra.
4. Execute `scripts/attempt_snapshot.py freeze --project projects/meu-video --scene 01 --attempt tentativa-001`. O comando só escreve se a cena estiver pronta; cria snapshot e linha `pending` antes de qualquer envio. `--dry-run` apenas mostra os bloqueios, sem criar arquivos.
5. Execute `scripts/attempt_snapshot.py verify --project projects/meu-video --attempt tentativa-001`. Envie pelo Chrome somente `submitted_prompt.txt` do pacote, com os mesmos inputs conferidos. Uma alteração exige novo preflight e nova tentativa.

Depois de registrar pending, o preflight bloqueia novos envios. Isso é esperado: não execute freeze outra vez para “liberar” a mesma tentativa. Verifique o snapshot e conclua somente o envio já registrado. Se houver dúvida se ele ocorreu, marque unknown e reconcilie antes de qualquer reenvio.

## Depois do envio

Atualize no CSV apenas os dados posteriores: `status`, `charged_credits`, `output_file`, `defects` e `decision`. Preserve os campos originais congelados, incluindo `utc`, modelo, modo, cena, referência, custo esperado e `prompt_file`. O custo esperado é para a quantidade total de resultados daquela tentativa. O gasto observado pode ser diferente e deve ser reconciliado, nunca estimado silenciosamente.

O pacote fica em `outputs/attempts/ID/`. Contém manifesto, cena, prompts, referências, frames usados, storyboard, plano de revisão e evidências. `registered.json` sela o hash do manifesto; o manifesto lista hashes dos arquivos. Essa proteção detecta alterações acidentais e evita sobrescrita, mas não é armazenamento inviolável.

Operações usam um lock local. Se o processo for interrompido, pode haver lock, snapshot órfão ou registro sem selo. Preserve os arquivos, compare CSV, snapshot e estado no Flow e reconcilie explicitamente. Não apague evidências nem refaça o envio automaticamente. O preflight identifica snapshots órfãos e inconsistentes.

Execute `scripts/flow_review.py audit --project projects/meu-video` com Python 3.12 para examinar o histórico sem modificá-lo. A auditoria também identifica locks e decisões/evidências incompletas; ela não decide se um lock está obsoleto nem o remove. O procedimento de recuperação e backup está em [manutenção](manutencao.md).

## Histórico antigo e revisão

Tentativas anteriores sem snapshot continuam legíveis como `legacy_without_snapshot`. Não reconstruímos como fato um prompt antigo a partir do arquivo atual. A comparação exata exige snapshots.

Quando há snapshot, `review_clip.py` usa os estados e o plano de revisão congelados, mesmo que o projeto atual tenha sido editado. A mídia original continua sendo a indicada no CSV e deve existir dentro de `outputs/`.
