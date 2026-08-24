param(
    [Parameter(Mandatory = $true)]
    [string]$PptxPath
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$PptxDestino = Join-Path $RepoRoot "apresentacao\Apresentacao_Tarefa4_Engenharia_Dados.pptx"
$Evidencia = Join-Path $RepoRoot "evidencias\39_finalizacao_artefatos_binarios.txt"

if (-not (Test-Path -LiteralPath $PptxPath)) {
    throw "Arquivo PPTX não encontrado: $PptxPath"
}

Write-Host "=== 1. Validando PPTX de origem ==="
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $PptxPath))
try {
    $slideCount = @($zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' }).Count
    if ($slideCount -ne 15) {
        throw "PPTX inválido ou inesperado: foram encontrados $slideCount slides; esperado = 15."
    }
}
finally {
    $zip.Dispose()
}

Write-Host "PPTX válido: 15 slides."

Write-Host "=== 2. Subindo PostgreSQL ==="
docker compose up -d postgres

Write-Host "=== 3. Construindo imagens ==="
docker compose build ingest dbt

Write-Host "=== 4. Executando ingestão RAW ==="
docker compose run --rm ingest

Write-Host "=== 5. Executando dbt build ==="
docker compose run --rm dbt dbt build

Write-Host "=== 6. Exportando Parquet ==="
docker compose run --rm `
    -v ./data/trusted:/data/trusted `
    -v ./data/delivery:/data/delivery `
    ingest python scripts/export_parquet.py

Write-Host "=== 7. Validando cardinalidades dos Parquets ==="
$validationCode = @'
import pandas as pd

checks = {
    "/data/trusted/reclamacoes.parquet": 918,
    "/data/trusted/enquadramento.parquet": 1459,
    "/data/trusted/glassdoor.parquet": 39,
    "/data/delivery/tabela_final.parquet": 918,
}

for path, expected in checks.items():
    found = len(pd.read_parquet(path))
    print(f"{path}: {found} linhas")
    if found != expected:
        raise SystemExit(
            f"Cardinalidade incorreta em {path}: encontrado={found}; esperado={expected}"
        )

print("VALIDAÇÃO PARQUET: OK")
'@

docker compose run --rm `
    -v ./data/trusted:/data/trusted `
    -v ./data/delivery:/data/delivery `
    ingest python -c $validationCode

Write-Host "=== 8. Atualizando apresentação ==="
Copy-Item -LiteralPath $PptxPath -Destination $PptxDestino -Force

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
@"
FINALIZAÇÃO DOS ARTEFATOS BINÁRIOS
Data: $timestamp

PPTX:
- apresentacao/Apresentacao_Tarefa4_Engenharia_Dados.pptx
- 15 slides validados

PARQUET:
- trusted.reclamacoes: 918 linhas
- trusted.enquadramento: 1459 linhas canônicas
- trusted.glassdoor: 39 linhas
- delivery.tabela_final: 918 linhas

DBT:
- dbt build executado com sucesso antes da exportação
"@ | Set-Content -LiteralPath $Evidencia -Encoding UTF8

Write-Host "=== 9. Preparando commit ==="
git add `
    data/trusted/reclamacoes.parquet `
    data/trusted/enquadramento.parquet `
    data/trusted/glassdoor.parquet `
    data/delivery/tabela_final.parquet `
    apresentacao/Apresentacao_Tarefa4_Engenharia_Dados.pptx `
    evidencias/39_finalizacao_artefatos_binarios.txt

$staged = git diff --cached --name-only
if (-not $staged) {
    Write-Host "Nenhuma alteração binária pendente para commit."
    exit 0
}

Write-Host "Arquivos preparados:"
$staged | ForEach-Object { Write-Host " - $_" }

Write-Host "=== 10. Commit e push ==="
git commit -m "Sincroniza apresentação e Parquets finais"
git push origin main

Write-Host "=== FINALIZAÇÃO CONCLUÍDA ==="
Write-Host "PPTX e Parquets foram validados, versionados e enviados ao GitHub."
