# Rime + 小狼毫 + 雾凇 配置还原

param([string]$Source = $PSScriptRoot)

Write-Host "=== Rime 配置还原 ===" -ForegroundColor Cyan

$src = Join-Path $Source "rime"
$dst = "$env:APPDATA\Rime"

if (Test-Path $src) {
    if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }

    # 还原除 build/ 以外的所有文件
    Get-ChildItem $src | ForEach-Object {
        $target = Join-Path $dst $_.Name
        Copy-Item $_.FullName -Destination $target -Recurse -Force
    }

    Write-Host "已还原到 $dst" -ForegroundColor Green
    Write-Host "`n请右键托盘 → 小狼毫 → 重新部署" -ForegroundColor Yellow
} else {
    Write-Host "未找到 rime/ 目录" -ForegroundColor Red
}
