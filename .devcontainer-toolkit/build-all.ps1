# ============================================
# 一键构建所有开发镜像
# 用法: .\build-all.ps1
#       .\build-all.ps1 -Only platformio    (只构建一个)
#       .\build-all.ps1 -Push               (构建并推送到仓库)
# ============================================
param(
    [string]$Only = "",           # 只构建某个镜像: base | platformio | arm-cortex-m | nrf-connect
    [switch]$Push = $false,      # 是否推送
    [string]$Registry = ""       # 私有仓库地址，如 registry.example.com/openedge
)

$ErrorActionPreference = "Stop"
$dockerDir = "$PSScriptRoot\docker"

$images = @(
    @{Name="openedge/base-embedded"; File="Dockerfile.base-embedded"},
    @{Name="openedge/platformio";     File="Dockerfile.platformio"},
    @{Name="openedge/arm-cortex-m";   File="Dockerfile.arm-cortex-m"},
    @{Name="openedge/nrf-connect";    File="Dockerfile.nrf-connect"}
)

Write-Host "=== OpenEdge 开发镜像工厂 ===" -ForegroundColor Cyan
Write-Host ""

foreach ($img in $images) {
    if ($Only -and $img.Name -notmatch $Only) { continue }

    Write-Host "[$(Get-Date -Format HH:mm:ss)] 构建 $($img.Name)..." -ForegroundColor Yellow

    $containerName = $img.Name -replace "/", "_" -replace ":", "_"

    docker build `
        -f "$dockerDir\$($img.File)" `
        -t $($img.Name) `
        "$dockerDir"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 构建失败: $($img.Name)" -ForegroundColor Red
        exit 1
    }

    if ($Push) {
        if ($Registry) {
            $fullName = "$Registry/$($img.Name)"
            docker tag $($img.Name) $fullName
            docker push $fullName
        } else {
            docker push $($img.Name)
        }
    }

    Write-Host "✅ $($img.Name) 完成" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== 构建完毕 ===" -ForegroundColor Cyan
Write-Host ""

# 列出所有镜像
docker images openedge/* --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
