# Capacidades e evidências

Documentação conferida pelo Chrome em **6 de outubro de 2026**: [modelos e recursos do Flow](https://support.google.com/flow/answer/16352836?hl=pt-BR) e [criação de vídeos e boas práticas](https://support.google.com/flow/answer/16353334?hl=pt-BR). Revalidar no início de uma produção; disponibilidade regional e controles da conta podem limitar o que aparece.

| Modelo no Flow | Texto / frame inicial / inicial e final | Elementos / referências | Extensão |
|---|---|---|---|
| Veo 3.1 Lite | 4, 6 ou 8 s | 8 s | Operação Lite sobre clipes Veo elegíveis de 8 s |
| Veo 3.1 Fast | 4, 6 ou 8 s | 8 s | Usar Lite para um clipe elegível |
| Veo 3.1 Quality | 4, 6 ou 8 s | Não compatível | Usar Lite para um clipe elegível |
| Gemini Omni Flash 1.1 | 4, 6, 8 ou 10 s | 4, 6, 8 ou 10 s | Lançamento futuro |

As duas proporções estão documentadas para esses modos. Omni também oferece edição de vídeo de até 10 segundos. Edição exige outro preflight com inspeção do vídeo de origem e não é coberta pelo exemplo de cenas novas. Consulte a documentação antes de usar voz, edição ou recursos regionais; não transfira limites da Gemini API para o Flow.

## Ajustes sobre a v1.6.0

O upstream trata Quality como 8 s e frames inicial/final do Omni no Flow como futuros. A documentação atual inclui Quality de 4/6/8 s e frames inicial/final do Omni. Os testes históricos permanecem intactos: são regressões daquela versão, não prova de capacidades atuais.

O executor local usa o linter com `surface/model/mode=unspecified`, mantendo as verificações de texto, referências e intervalos. A compatibilidade é checada separadamente por `config/flow-capabilities.json`. Não usamos o linter como avaliador semântico de imagens.

O Google recomenda referências limpas, aparência consistente entre imagens e texto que complemente as entradas visuais. Os nomes com `@` devem corresponder a ativos selecionados no projeto; é necessário conferir a vinculação na interface. [Práticas oficiais](https://support.google.com/flow/answer/16353334?hl=pt-BR).

## Inspeção da interface

A tela inicial e o compositor de um projeto existente foram inspecionados pelo Chrome, com sessão conectada. A interface mostrou Frames, Elementos, 16:9/9:16, quantidades x1 a x4 e as famílias Omni 1.1 Flash e Veo 3.1 Lite/Fast/Quality. Apenas os menus foram abertos; nenhum parâmetro, ativo ou projeto foi alterado e não houve geração.

O custo exibido nessa inspeção correspondia à configuração de Frames já selecionada no projeto existente. Não foi transferido para o exemplo com Elementos. A disponibilidade da combinação específica e o custo por resultado precisam ser confirmados com os materiais do novo vídeo, antes de produção. Registre a inspeção em `project.json` (`ui_verified`, `ui_evidence`, `cost_per_result_credits`, `ui_plan_sha256` e `bindings`).

O exemplo propõe **Veo 3.1 Fast / referências / 8 s / 16:9 / um resultado por cena**: combinação compatível com a documentação. Ainda não há referências aprovadas ou anexadas, nem custo confirmado, nem autorização de geração.
