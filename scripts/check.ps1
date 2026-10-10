[CmdletBinding()]
param(
    [string]$Python,
    [string]$Project = 'projects/exemplo-duas-cenas',
    [string]$Scene,
    [switch]$SkipUpstreamTests,
    [switch]$RequireReady
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$pythonCandidates = @()
if ($Python) {
    $pythonCandidates = @($Python)
} else {
    $uvRuntimeRoot = Join-Path $env:APPDATA 'uv\python'
    if (Test-Path -LiteralPath $uvRuntimeRoot) {
        $pythonCandidates += Get-ChildItem -LiteralPath $uvRuntimeRoot -Directory -Filter 'cpython-3.12.*-windows-x86_64-none' |
            Sort-Object Name -Descending | ForEach-Object { Join-Path $_.FullName 'python.exe' }
    }
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCommand) { $pythonCandidates += $pythonCommand.Source }
}
$selectedPython = $null
foreach ($candidate in $pythonCandidates) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $runtimeVersion = & $candidate --version 2>&1
        if ($LASTEXITCODE -eq 0 -and "$runtimeVersion" -match '^Python 3\.12\.') {
            $selectedPython = $candidate
            break
        }
    }
}
if (-not $selectedPython) {
    throw 'Python 3.12 nao encontrado. Use -Python com o caminho de um executavel 3.12 ja instalado.'
}
$verifyArguments = @((Join-Path $PSScriptRoot 'verify.py'), '--project', $Project)
if ($SkipUpstreamTests) { $verifyArguments += '--skip-upstream-tests' }
if ($RequireReady) { $verifyArguments += '--require-ready' }
if ($Scene) { $verifyArguments += @('--scene', $Scene) }
$previousUtf8 = $env:PYTHONUTF8
Push-Location $workspaceRoot
try {
    $env:PYTHONUTF8 = '1'
    Write-Output "Python: $selectedPython"
    & $selectedPython @verifyArguments
    $verificationExitCode = $LASTEXITCODE
} finally {
    $env:PYTHONUTF8 = $previousUtf8
    Pop-Location
}
exit $verificationExitCode
