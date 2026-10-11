#requires -Version 7.0
# Rime 恢复：清单不完整时在写入目标之前停止。
param(
    [string]$Source = $PSScriptRoot,
    [string]$Destination = (Join-Path $env:APPDATA 'Rime')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/config-common.ps1')

Assert-ApplicationStopped @('Weasel*')
$src = Join-Path $Source 'rime'
Assert-RequiredPaths $src @('default.custom.yaml', 'weasel.custom.yaml', 'rime_ice.schema.yaml')
if (Test-Path -LiteralPath (Join-Path $Source '.backup-incomplete')) { throw '该备份尚未完成，不能恢复。' }
Restore-Configuration @(@{ Source = $src; Destination = $Destination })
Write-Host '请通过小狼毫托盘菜单重新部署。'

