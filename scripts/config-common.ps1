#requires -Version 7.0
# 备份与恢复共用的目录检查、逐项复制和 LevelDB 清单校验。
$ErrorActionPreference = 'Stop'

function Assert-ApplicationStopped {
    param([string[]]$Name)
    if (Get-Process -Name $Name -ErrorAction SilentlyContinue) {
        throw "请先完全退出应用及后台进程：$($Name -join ', ')。"
    }
}

function Assert-RequiredPaths {
    param([string]$Root, [string[]]$RelativePath = @())
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "目录不存在：$Root"
    }
    foreach ($name in $RelativePath) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $name))) {
            throw "缺少必要文件或目录：$(Join-Path $Root $name)"
        }
    }
}

function Assert-SeparatePaths {
    param([string]$Source, [string]$Destination)
    $src = [IO.Path]::GetFullPath($Source).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $dst = [IO.Path]::GetFullPath($Destination).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if ($src.StartsWith($dst, [StringComparison]::OrdinalIgnoreCase) -or
        $dst.StartsWith($src, [StringComparison]::OrdinalIgnoreCase)) {
        throw '源目录和目标目录必须相互独立，不能相同或互相包含。'
    }
}

function Copy-DirectoryContents {
    param([string]$Source, [string]$Destination, [string[]]$Exclude = @())
    Assert-RequiredPaths $Source
    Assert-SeparatePaths $Source $Destination
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    foreach ($item in Get-ChildItem -LiteralPath $Source -Force) {
        if ($item.Name -in $Exclude) { continue }
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "无法安全复制链接目录或文件：$($item.FullName)"
        }
        $target = Join-Path $Destination $item.Name
        if ($item.PSIsContainer) {
            Copy-DirectoryContents -Source $item.FullName -Destination $target -Exclude $Exclude
        } else {
            Copy-Item -LiteralPath $item.FullName -Destination $target -Force -ErrorAction Stop
        }
    }
}

function Copy-SelectedItems {
    param([string]$Source, [string]$Destination, [string[]]$Name)
    Assert-RequiredPaths $Source
    Assert-SeparatePaths $Source $Destination
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    foreach ($entry in $Name) {
        $path = Join-Path $Source $entry
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $target = Join-Path $Destination $entry
        if (Test-Path -LiteralPath $path -PathType Container) {
            Copy-DirectoryContents $path $target
        } else {
            Copy-Item -LiteralPath $path -Destination $target -Force -ErrorAction Stop
        }
    }
}

function Assert-LevelDbManifests {
    param([string]$Root)
    foreach ($current in Get-ChildItem -LiteralPath $Root -Recurse -Force -File -Filter CURRENT) {
        $manifest = (Get-Content -LiteralPath $current.FullName -Raw -ErrorAction Stop).Trim()
        if ($manifest -notmatch '^MANIFEST-\d+$' -or
            -not (Test-Path -LiteralPath (Join-Path $current.DirectoryName $manifest) -PathType Leaf)) {
            throw "数据库备份不完整：$($current.DirectoryName) 的 CURRENT 对应清单缺失。请关闭应用后重新采集整份数据库。"
        }
        # 读取清单以发现进程占用，不能仅检查文件是否存在。
        $stream = [IO.File]::Open($current.FullName, 'Open', 'Read', 'Read')
        $stream.Dispose()
        $stream = [IO.File]::Open((Join-Path $current.DirectoryName $manifest), 'Open', 'Read', 'Read')
        $stream.Dispose()
    }
}

function New-BackupDirectory {
    param([string]$Destination)
    if (Test-Path -LiteralPath $Destination) { throw "备份目录已存在，拒绝合并旧快照：$Destination" }
    New-Item -ItemType Directory -Path $Destination | Out-Null
    Set-Content -LiteralPath (Join-Path $Destination '.backup-incomplete') -Value '备份尚未完成。' -Encoding utf8
}

function Complete-Backup {
    param([string]$Destination)
    Assert-LevelDbManifests $Destination
    # 删除对象是本次创建的备份目录中的完成标记。
    Remove-Item -LiteralPath (Join-Path $Destination '.backup-incomplete') -Force
    Write-Host "备份完成：$Destination"
}

function Restore-Configuration {
    param([hashtable[]]$Mapping)
    foreach ($pair in $Mapping) {
        Assert-RequiredPaths $pair.Source
        Assert-SeparatePaths $pair.Source $pair.Destination
        foreach ($other in $Mapping) {
            Assert-SeparatePaths $pair.Source $other.Destination
        }
        Assert-LevelDbManifests $pair.Source
    }
    # 所有源文件通过校验、全部现有配置备份成功后，才开始覆盖。
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fffffff'
    foreach ($pair in $Mapping) {
        if (Test-Path -LiteralPath $pair.Destination) {
            $backup = $pair.Destination.TrimEnd('\', '/') + ".before-restore-$stamp"
            $names = @(Get-ChildItem -LiteralPath $pair.Source -Force | Select-Object -ExpandProperty Name)
            Copy-SelectedItems $pair.Destination $backup $names
            Write-Host "原配置备份：$backup"
        }
    }
    foreach ($pair in $Mapping) {
        Copy-DirectoryContents $pair.Source $pair.Destination
        Assert-LevelDbManifests $pair.Destination
    }
    Write-Host '恢复完成。'
}
