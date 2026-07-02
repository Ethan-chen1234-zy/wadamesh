# ============================================
# 一键初始化新工程 — 从模板生成 .devcontainer/
# 用法:
#   .\new-project.ps1 -Path D:\Code\MyWisBlock -Type platformio
#   .\new-project.ps1 -Path D:\Code\MeshCore   -Type platformio
#   .\new-project.ps1 -Path D:\Code\nRF54-App  -Type nrf-connect
#   .\new-project.ps1 -Path D:\Code\M55M1-FW   -Type arm-embedded
# ============================================
param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [Parameter(Mandatory=$true)]
    [ValidateSet("platformio", "arm-embedded", "nrf-connect")]
    [string]$Type
)

$ErrorActionPreference = "Stop"
$templatesDir = "$PSScriptRoot\templates"
$source = Join-Path $templatesDir $Type

if (-not (Test-Path $source)) {
    Write-Host "❌ 模板不存在: $Type" -ForegroundColor Red
    Write-Host "可用模板:"
    Get-ChildItem $templatesDir -Directory | ForEach-Object { Write-Host "  - $($_.Name)" }
    exit 1
}

# 创建目标目录
$targetDir = Join-Path $Path ".devcontainer"
if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

# 复制模板文件
Copy-Item -Path "$source\.devcontainer\*" -Destination $targetDir -Recurse -Force

Write-Host ""
Write-Host "✅ 已创建: $targetDir" -ForegroundColor Green
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "  1. code $Path" -ForegroundColor White
Write-Host "  2. VSCode 左下角 >< → Reopen in Container" -ForegroundColor White
Write-Host "  3. 如果镜像还没构建: 先运行 build-all.ps1" -ForegroundColor White
Write-Host ""

Get-ChildItem $targetDir
