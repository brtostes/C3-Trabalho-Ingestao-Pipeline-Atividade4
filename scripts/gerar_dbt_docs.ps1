param(
    [switch]$Serve,
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================"
Write-Host "ATIVIDADE 4 - GERACAO DA DOCUMENTACAO DBT"
Write-Host "============================================================"

# 1. Verifica se o Docker Engine esta disponivel.
Write-Host "`n[1/6] Verificando Docker..."
docker version | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Docker nao esta disponivel. Abra o Docker Desktop e tente novamente."
}

# 2. Garante que o PostgreSQL esteja em execucao.
Write-Host "`n[2/6] Iniciando PostgreSQL..."
docker compose up -d postgres
if ($LASTEXITCODE -ne 0) {
    throw "Falha ao iniciar o PostgreSQL."
}

# 3. Aguarda o healthcheck do PostgreSQL.
Write-Host "`n[3/6] Aguardando PostgreSQL ficar healthy..."
$healthy = $false
for ($i = 1; $i -le 30; $i++) {
    $status = docker inspect --format='{{.State.Health.Status}}' trabalho04-postgres 2>$null
    if ($status -eq "healthy") {
        $healthy = $true
        break
    }
    Start-Sleep -Seconds 2
}

if (-not $healthy) {
    throw "O PostgreSQL nao ficou healthy dentro do tempo esperado."
}

Write-Host "PostgreSQL: healthy"

# 4. Executa o build antes da documentacao.
Write-Host "`n[4/6] Executando dbt build..."
docker compose run --rm dbt dbt build
if ($LASTEXITCODE -ne 0) {
    throw "dbt build apresentou erro. A documentacao nao sera gerada."
}

# 5. Gera a documentacao e salva uma evidencia textual.
# O comando e executado por cmd.exe porque o Docker Compose pode escrever
# mensagens informativas no stderr mesmo quando termina com codigo 0.
# No Windows PowerShell, redirecionar stderr diretamente para o pipeline
# pode transformar essas mensagens em NativeCommandError quando
# $ErrorActionPreference = 'Stop'.
Write-Host "`n[5/6] Executando dbt docs generate..."
$evidenciaDocs = Join-Path $PSScriptRoot "..\evidencias\40_dbt_docs_generate.txt"
$evidenciaDocs = [System.IO.Path]::GetFullPath($evidenciaDocs)

$docsCommand = "docker compose run --rm dbt dbt docs generate > `"$evidenciaDocs`" 2>&1"
cmd.exe /d /c $docsCommand
$docsExitCode = $LASTEXITCODE

if (Test-Path $evidenciaDocs) {
    Get-Content $evidenciaDocs
}

if ($docsExitCode -ne 0) {
    throw "dbt docs generate apresentou erro. Consulte $evidenciaDocs."
}

# 6. Registra os arquivos gerados no target como evidencia.
Write-Host "`n[6/6] Registrando arquivos gerados..."
$targetPath = Join-Path $PSScriptRoot "..\dbt\target"
$evidenciaArquivos = Join-Path $PSScriptRoot "..\evidencias\41_dbt_docs_arquivos_gerados.txt"

if (-not (Test-Path $targetPath)) {
    throw "A pasta dbt\target nao foi encontrada apos dbt docs generate."
}

Get-ChildItem $targetPath |
    Select-Object Name, Length, LastWriteTime |
    Format-Table -AutoSize |
    Out-String |
    Set-Content -Path $evidenciaArquivos -Encoding UTF8

Write-Host "`nDocumentacao gerada com sucesso."
Write-Host "Evidencia: $evidenciaDocs"
Write-Host "Evidencia: $evidenciaArquivos"
Write-Host "Pasta gerada: $targetPath"

if ($Serve) {
    Write-Host "`nIniciando dbt docs serve na porta $Port..."
    Write-Host "Abra no navegador: http://localhost:$Port"
    Write-Host "Mantenha esta janela aberta enquanto consultar a documentacao."

    docker compose run --rm `
        -p "${Port}:${Port}" `
        dbt `
        dbt docs serve `
        --host 0.0.0.0 `
        --port $Port
}
