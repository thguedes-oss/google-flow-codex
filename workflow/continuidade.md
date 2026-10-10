# Continuidade, cortes e frames

`state_in` e `state_out` continuam sendo os estados planejados. A comparação padrão exige igualdade entre a saída e a entrada seguinte. Não altere o plano para justificar um defeito de um clipe.

Na [direção contextual](direcao-contextual.md), o Codex planeja esses estados e a relação entre cenas a partir da função narrativa, sem exigir que o usuário descreva cada mão ou objeto. Registre a escolha no editorial e transponha para o manifesto. Estado planejado não é observação nem aprovação; confrontar com frames reais e revisão da emenda continua obrigatório. Uma transição gráfica não corrige continuidade defeituosa nem libera o handoff.

## Corte com mudança deliberada

Uma cena com `transition: cut` pode declarar `continuity_changes`, uma lista com `field`, `before`, `after`, `reason`, `reviewer` e `evidence`. `field` é uma chave literal do estado, como `camera`. Declare exatamente todos os campos que mudaram, inclusive mudanças de coordenadas na imagem causadas por outro enquadramento. Valores e justificativa incorretos são erros estruturais; revisão ou evidência ausente bloqueiam prontidão.

Uma troca de roupa ou de aparência exige atualizar e aprovar a referência correspondente, além da declaração narrativa. A ferramenta verifica dados e arquivos; a coerência semântica entre imagem, ficha e prompt continua exigindo inspeção.

## Inputs conforme o modo

- Referências para vídeo: `bindings` por handle, cada um com `flow_asset`, `sha256` e `evidence`.
- Frame inicial: `frames.initial` com `path`, `sha256`, `approved` e `binding`.
- Frames inicial e final: também `frames.final` no mesmo formato.
- Um `binding` de frame contém `flow_asset` (nome/identificador observado do slot), `sha256` e `evidence` relativa ao projeto.

`required_references` continua identificando os ativos usados no planejamento; em Frames, não exige anexar cada retrato/objeto como Elemento. Confira o frame composto aprovado e sua ligação no slot. Use `scenes[].mode` apenas quando uma cena precisar de modo diferente do padrão do vídeo; a compatibilidade é checada por cena.

## Continuação

Continuação exige igualdade dos estados e modo `first-frame` ou `first-last-frame`. Registre em `handoff`:

```json
{
  "review_decision": "outputs/decisions/ID/REVISAO/decision.json",
  "frame": "assets/passagem/frame-final.png",
  "sha256": "SHA256_REAL",
  "frame_approval": {
    "approved": true,
    "reviewer": "RESPONSAVEL_REAL",
    "at": "DATA_REAL",
    "evidence": "REGISTRO_REAL_DA_APROVACAO"
  }
}
```

Esse exemplo é um formato, não uma aprovação. A decisão deve ser a revisão formal mais recente, aprovada, da cena anterior. O arquivo precisa ter os mesmos bytes do `last_frame` do relatório de evidências; `frames.initial.sha256` deve coincidir. A aprovação do clipe e a aprovação específica do frame são decisões reais. Uma revisão posterior que rejeite o clipe invalida o uso da decisão antiga.

Após gerar a continuação, reproduza os dois clipes em sequência e revise a emenda. Validar o input não aprova uma emenda que ainda não existe.

## Prontidão por cena

Use `scripts/check.ps1 -Project projects/meu-video -Scene 01 -RequireReady` ou `scripts/preflight.py projects/meu-video --scene 01 --require-ready`. A estrutura inteira continua validada; referências e inputs de cenas futuras não bloqueiam a prontidão da cena selecionada. Tentativas desconhecidas e gastos não reconciliados continuam bloqueando novos envios em todo o vídeo.

O hash retornado é específico da seleção. Registre esse hash em `generation.ui_plan_sha256` somente após a conferência real no Chrome. Não reaproveite um hash global ou de outra cena.
