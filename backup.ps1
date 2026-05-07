# Rime + 小狼毫 + 雾凇 配置备份

$dest = Join-Path $PSScriptRoot "Backup" (Get-Date -Format "yyyyMMdd-HHmmss")

Write-Host "=== Rime 配置备份 ===" -ForegroundColor Cyan
Write-Host "→ $dest`n"
Write-Host "建议先切换到其他输入法再备份" -ForegroundColor Yellow

$src = "$env:APPDATA\Rime"
$dst = Join-Path $dest "rime"

if (Test-Path $src) {
    # 复制全部，排除编译缓存
    Copy-Item $src -Destination $dst -Recurse -Force
    Remove-Item "$dst\build" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "完成: $dst" -ForegroundColor Green
}

Write-Host "`n=== 备份完成 ===" -ForegroundColor Cyan
