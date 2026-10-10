# GL Transitions: biblioteca estática WGSL

125 transições do commit `b2dfdcfbec079af4a05306d32b9366aa495c5155`, com nomes, parâmetros, autoria e avisos originais preservados. `originals/` contém os bytes GLSL usados na portabilidade; `LICENSE` cobre os arquivos sem licença específica, enquanto os cabeçalhos individuais prevalecem (incluindo BSD de `InvertedPageCurl` e `StereoViewer`).

`catalog.json` é o contrato consumido em produção. Um efeito só recebe `enabled` depois de compilar e renderizar no motor portátil 0.3.1 e de passar pela publicação das três provas de formato. `implementation.sha256` sela o módulo WGSL. A ferramenta de portabilidade não faz parte da execução do pipeline e não faz downloads.

## Uniformes e fontes

- Ordem dos escalares: `progress`, `ratio`, depois os parâmetros na ordem do catálogo. Vetores viram componentes `_x`, `_y`, `_z`, `_w`. O bloco WGSL recebe preenchimento até múltiplo de quatro `f32`.
- `source_type` conserva o tipo GLSL, inclusive `ivec2`; o tipo público desses parâmetros é `vec2` com componentes inteiros. Inteiros e booleanos são convertidos explicitamente dentro do módulo.
- A textura da camada proprietária é a fonte de saída (`from`, binding 0); `texture_inputs[0]`, nome `to`, é a fonte de entrada (binding 1). `displacement` e `luma` exigem mais uma imagem de mapa, em binding 2. O sampler e o uniforme seguem as texturas.
- `sources_min` e `sources_max` são 2 nos efeitos comuns e 3 nos dois efeitos com mapa. Os mapas são recursos reais do plano; o catálogo não inventa material em produção.
- A portabilidade converte o eixo Y na entrada da função e na amostragem das texturas, preservando a orientação GL e a orientação visual nativa. A saída respeita alpha premultiplicado. Amostragem usa nível explícito para permitir os ramos dos shaders originais.
- O esquema instalado exige `setFxLayerEffectParamAnimator` com `layerId`, `effectId`, `paramName`, `animator.layerTimeJsCode` e `dependencies`. O relógio do efeito é relativo ao início da janela de entrada da camada proprietária, independente do recorte da origem. Nas cópias auxiliares, começa em zero na janela da transição; nas camadas originais, o compilador desconta `at_ms` da posição da técnica na composição.

## Desenvolvimento e prova explícita

Use Python 3.12 já instalado e o motor fixado por `config/tesseract.json`. Não execute scripts upstream nem altere a cópia vendorizada.

```powershell
# Recria WGSL e deixa os registros como incomplete até a prova nativa.
python scripts/port_gl_transitions.py
python scripts/smoke_gl_transitions.py --aspect landscape --report reports/gl-transitions-landscape.json
python scripts/smoke_gl_transitions.py --aspect portrait --report reports/gl-transitions-portrait.json
python scripts/smoke_gl_transitions.py --aspect square --report reports/gl-transitions-square.json
# Só publica se os três relatórios completos correspondem aos hashes atuais.
python scripts/smoke_gl_transitions.py --publish-catalog
python -m unittest discover -s tests -p test_gl_transitions.py
```

O porter é uma ferramenta local de desenvolvimento: tokeniza e analisa expressões, comandos, escopos e tipos, depois emite WGSL. Trata construtores/matrizes, sobrecargas, coerção escalar/vetor, atribuição de swizzles, operadores GLSL e parâmetros mutáveis. A emissão estática passa por compilação e render reais. Alterações invalidam a publicação até repetir a prova.

O smoke usa duas fontes sintéticas assimétricas em movimento, recortes de origem distintos e um mapa sintético adicional quando exigido. Amostra 0%, 25%, 50%, 75% e 100%, compara os extremos aos baselines nativos do mesmo canvas, detecta fallback/pass-through, registra preto intermediário e confere RGB de pixels transparentes. Os rótulos da filmstrip são excluídos das medições. Os três formatos usam 320×180, 180×320 e 240×240; estes testes de shader não substituem os perfis de exportação 720p/1080p/4K do pipeline.

Preto no meio pode ser parte do efeito original (`CircleCrop`, `Rectangle`, `RectangleCrop`, `SimpleFlip`, `StereoViewer`): é registrado e confrontado com os demais momentos. O smoke não altera o shader para esconder esse comportamento.

As métricas de orientação e proporção usam RGB; a diferença de alpha é registrada separadamente. `burn`, `flyeye`, `GlitchMemories`, `HSVfade`, `InvertedPageCurl`, `SimpleFlip` e `tangentMotionBlur` podem forçar opacidade, conforme as expressões originais. Portanto, usar uma fonte com transparência não garante saída transparente nesses efeitos. `AdvancedMosaic` mantém uma grade UV de 0,005 nos extremos e `tangentMotionBlur` mantém um desfoque residual `exp(-5)`; as pequenas diferenças observadas são preservadas e têm tolerância técnica específica, sem substituir os extremos por cortes artificiais.

Os fixtures, projetos e PNGs permanecem exclusivamente em diretórios temporários, cujos caminhos e hashes estão nos relatórios. São evidências técnicas; não são mídia de produção nem aprovação visual. Os relatórios não declaram reprodução completa ou escuta. Fidelidade subjetiva, desempenho em resoluções de entrega e todas as combinações de parâmetros continuam exigindo revisão da montagem real. Não houve chamada de geração nem gasto de créditos do Flow.
