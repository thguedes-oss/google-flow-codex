# Preparar um checkout novo no Windows

Use Git, PowerShell e Python **3.12** já instalados. Abra o PowerShell na raiz do clone de `google-flow-codex`. Os comandos abaixo recuperam material de consulta; não executam instaladores, notebooks ou scripts das fontes, não conectam contas e não geram mídia.

O clone inclui a documentação, os scripts, os templates, o exemplo e os registros técnicos versionados. Não inclui `vendor/`, `.work/`, imagens, vídeos ou arquivos de áudio locais. Os resultados de verificações anteriores descrevem a máquina em que foram produzidos; rode uma verificação própria depois de preparar as fontes.

O `.gitattributes` preserva os bytes versionados sem conversão automática de finais de linha: inventários, prompts e evidências usam hashes de arquivo. As cópias externas têm sua configuração LF própria, conforme o bloco abaixo.

## 1. Recuperar os clones fixados

Execute este bloco somente quando as pastas de destino ainda não existirem. Ele lê os commits do registro, mantém finais de linha LF e evita downloads de conteúdo Git LFS e inicialização de submódulos. Se uma operação falhar, pare e inspecione a pasta parcial antes de repetir; o bloco não apaga nem substitui cópias existentes.

```powershell
$lockData = Get-Content -Raw -LiteralPath 'sources.lock.json' | ConvertFrom-Json
$gitSources = @($lockData) + @($lockData.supplements | Where-Object { $_.type -eq 'git' })
$previousLfsSkip = $env:GIT_LFS_SKIP_SMUDGE
try {
    $env:GIT_LFS_SKIP_SMUDGE = '1'
    foreach ($source in $gitSources) {
        if (Test-Path -LiteralPath $source.directory) {
            throw "Destino já existe: $($source.directory). Confira a cópia antes de continuar."
        }
        git -c core.autocrlf=false clone --depth 1 --no-checkout --no-recurse-submodules $source.repository $source.directory
        if ($LASTEXITCODE -ne 0) { throw "Falha ao clonar $($source.repository)." }
        git -C $source.directory config --local core.autocrlf false
        if ($LASTEXITCODE -ne 0) { throw "Falha ao configurar finais de linha." }
        git -C $source.directory fetch --depth 1 origin $source.commit
        if ($LASTEXITCODE -ne 0) { throw "Commit fixado indisponível: $($source.commit)." }
        git -C $source.directory checkout --detach $source.commit
        if ($LASTEXITCODE -ne 0) { throw "Falha ao selecionar o commit fixado." }
    }
} finally {
    $env:GIT_LFS_SKIP_SMUDGE = $previousLfsSkip
}
```

A base e os cinco clones complementares permanecem independentes deste repositório. Não atualize commits, inventários ou hashes para aceitar outra versão. Consulte [fontes complementares](fontes.md) para os direitos e o conteúdo esperado de cada cópia.

## 2. Recuperar o notebook de referência do Google

Este snapshot tem dois arquivos: a licença e um notebook, ambos obtidos do commit registrado. O bloco salva os bytes e compara seus hashes; não executa o notebook. Use somente com a pasta de destino ausente.

```powershell
$notebookSource = $lockData.supplements | Where-Object { $_.id -eq 'veo-reference-notebook' }
if (Test-Path -LiteralPath $notebookSource.directory) {
    throw "Snapshot já existe; confira os arquivos antes de continuar."
}
New-Item -ItemType Directory -Path $notebookSource.directory -ErrorAction Stop | Out-Null
foreach ($entry in $notebookSource.files) {
    $sourceUrl = "https://raw.githubusercontent.com/GoogleCloudPlatform/generative-ai/$($notebookSource.commit)/$($entry.source_path)"
    $destination = Join-Path $notebookSource.directory $entry.path
    Invoke-WebRequest -Uri $sourceUrl -OutFile $destination -ErrorAction Stop
    if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) {
        throw "Hash diferente do registro: $($entry.path). Não altere o hash esperado."
    }
}
```

## 3. Limitação do snapshot web da wiki Claudia

O registro aponta para nove arquivos históricos em `vendor/claudia-wiki-2026-10-08`, com URLs, data de consulta e SHA-256. Não foi identificada licença explícita para os textos, e essa cópia local não é redistribuída neste repositório. A permissão de uso da personagem não foi tratada como licença documental.

Para reproduzir a verificação integral, é necessário recuperar os mesmos bytes de uma cópia histórica disponível e cujo uso seja permitido. As URLs registradas permitem consultar as fontes, mas as páginas atuais podem ter mudado. Sem o snapshot exato, a verificação de integridade das fontes falhará; não invente arquivos, substitua hashes ou marque a cópia como verificada. A documentação e os templates do projeto continuam disponíveis para leitura e planejamento.

## 4. Verificar a sua cópia

```powershell
.\scripts\check.ps1
# Se a detecção automática não encontrar o seu Python 3.12:
.\scripts\check.ps1 -Python 'C:\caminho\python.exe'
```

Com as fontes completas e íntegras, o exemplo deve retornar `planning_passed=true, generation_ready=false`. Os relatórios da sua execução ficam em `reports/runs/`; não representam aprovação visual nem autorização de gastos. `-RequireReady` deve falhar enquanto faltarem referências, preflight e orçamento reais. Pular os testes upstream não dispensa a integridade dos snapshots.

FFmpeg/FFprobe são necessários para operações com áudio e vídeo; Tesseract é necessário para a pós-produção. Essas ferramentas e as skills do Codex não acompanham o clone. Para preparar a edição, siga [pós-produção](pos-producao.md), usando somente os executáveis portáteis e as versões de `config/tesseract.json`. Não instale ou atualize ferramentas como efeito colateral de clonar o projeto.

Para começar um vídeo, abra a pasta no Codex, leia o [README](../README.md) e faça o pedido pelo chat. O exemplo permanece com zero créditos autorizados no Flow e sem mídia de produção aprovada.
