# Marcadores locais de energia do áudio

Implementação própria em `scripts/audio_markers.py`, somente biblioteca padrão e FFmpeg/FFprobe existentes. Não copia BeatCut, executa fontes externas ou chama APIs. O plano real passa por `tesseract_pipeline.validate_plan()` antes e depois da leitura; o áudio precisa de aprovação vigente registrada, origem e hash corretos. O plano e a mídia são conferidos novamente por SHA-256, e alterações impedem gravar evidência. Somente o áudio selecionado é decodificado; validar o plano completo preserva o contrato de recursos e aprovação já existente.

Exemplo (exige plano real válido e recurso aprovado):

```powershell
& 'C:/Users/thgue/AppData/Roaming/uv/python/cpython-3.12.13-windows-x86_64-none/python.exe' scripts/audio_markers.py --project projects/meu-video --plan postproduction.json --resource trilha --output reports/postproduction/audio-markers/trilha-v1.json --sample-rate 8000 --hop-ms 20 --sensitivity 1.5 --min-distance-ms 200
```

A extração usa PCM mono s16le de 8 ou 16 kHz, lendo blocos com hop entre 10 e 20 ms para RMS. O limiar é a média RMS da janela multiplicada pela sensibilidade finita positiva; valores maiores deixam menos candidatos. Picos locais são filtrados por distância mínima em milissegundos, priorizando maior energia. Silêncio não produz candidatos. Janela máxima: oito horas; timeout de decodificação: 120 segundos. O PCM temporário fica fora do projeto e é removido; a leitura é em blocos, com apenas energias por janela em memória.

Cada candidato tem `source_ms`, `timeline_ms`, `type: energy_peak_candidate` e `confirmed: false`. O relógio é `timeline_ms = at_ms + source_ms - in_ms`, limitado à seleção `in_ms <= source_ms < out_ms`. O relatório inclui `audio_at_ms`, hashes antes/depois e parâmetros. Exige exatamente uma camada para o recurso no plano; múltiplos usos pedem planos de análise separados. O arquivo deve ser JSON novo em `reports/postproduction/audio-markers/`; não sobrescreve evidências, mídia, manifestos ou CSVs.

Picos de energia não comprovam batidas ou andamento: voz, transientes e ruídos também podem originá-los. A ferramenta não confirma candidatos, alinha cortes, altera planos nem aprova áudio. Ouvir e decidir continua sendo trabalho humano.

TDD: os três primeiros testes falharam por ausência do módulo; após implementação passaram. Testes ampliados verificaram WAV sintético temporário com impulsos periódicos, silêncio, limites, parâmetros inválidos, aprovação/hash incorretos, janela fora de fonte/timeline, mapeamento e imutabilidade. Uma mutação simulada depois da leitura impede gravar relatório. Ajustada a fixture técnica de retângulo para respeitar o contrato real de cor RGBA.

Comando de verificação executado:

```powershell
& 'C:/Users/thgue/AppData/Roaming/uv/python/cpython-3.12.13-windows-x86_64-none/python.exe' -m unittest discover -s tests -p test_audio_markers.py
```

Resultado: seis testes passaram, incluindo decodificação real pelo FFmpeg. Nenhuma mídia de produção, aprovação real ou crédito foi criado. Fixtures e decisões sintéticas existem somente no diretório temporário dos testes. Sem commits e sem novas dependências.
