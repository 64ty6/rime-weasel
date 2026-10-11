#requires -Version 7.0
# Rime 备份：停机采集整份用户词库，校验 CURRENT 与清单。
param(
    [string]$SourceDirectory = (Join-Path $env:APPDATA 'Rime'),
    [string]$Destination = (Join-Path $PSScriptRoot 'Backup' (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff'))
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/config-common.ps1')

Assert-ApplicationStopped @('Weasel*')
Assert-RequiredPaths $SourceDirectory @('default.custom.yaml', 'weasel.custom.yaml', 'rime_ice.schema.yaml')
Assert-SeparatePaths $SourceDirectory $Destination
Assert-LevelDbManifests $SourceDirectory
New-BackupDirectory $Destination
Copy-DirectoryContents $SourceDirectory (Join-Path $Destination 'rime') @('build', '.github', '.gitignore', 'rime-ice-main', 'LOCK', 'LOG', 'LOG.old')
Assert-ApplicationStopped @('Weasel*')
Complete-Backup $Destination

