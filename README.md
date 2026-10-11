# Rime 输入法配置备份

小狼毫 0.17.4、Rime 1.13.1、雾凇拼音配置备份。启用 `rime_ice` 和小鹤双拼 `double_pinyin_flypy`，皮肤为 `so_young`。软件安装目录沿用 `D:\Tools\xiaolanghao`，配置目录为 `%APPDATA%\Rime`。

## PowerShell 7 脚本入口

所有 PowerShell 命令均在 **PowerShell 7** 中执行。仓库脚本使用 `#requires -Version 7.0`，不支持 Windows PowerShell 5.1。

```powershell
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
pwsh -NoProfile -File .\backup.ps1
pwsh -NoProfile -File .\restore.ps1
```

自动操作优先使用以上脚本；下文手动步骤用于说明目录映射和还原后检查，不能绕过脚本的进程及完整性校验。

- 备份前完全退出应用及后台进程。缺少必要配置、文件被占用或复制失败时脚本报错停止，不打印成功。
- 导出目录内的 `.backup-incomplete` 表示快照尚未完成；存在该标记时禁止恢复。每次导出使用独立目录，不与旧备份合并。
- 恢复前先验证所有源目录，再把将要覆盖的现有配置复制到目标目录旁的 `*.before-restore-<时间戳>`。发生错误时可从该目录找回原文件；新复制的文件不会自动回滚。
- 目录按内容逐项复制，重复恢复不会产生同名子目录嵌套。数据库的 `CURRENT` 必须指向存在且可读取的 `MANIFEST-*`；数值命名的事务日志（如 `000003.log`）属于数据库内容，必须保留。
- 若在 Codex 等沙盒中操作，进程列表可能不完整。请先在宿主机确认应用退出；文件锁或复制错误仍会使脚本停止。


## 还原步骤

1. 在目标机安装小狼毫并确认安装目录。完全退出小狼毫，包括 `WeaselServer`；只切换输入法可能仍保持文件锁。
2. 在仓库根目录运行：

```powershell
pwsh -NoProfile -File .\restore.ps1
```

脚本验证关键配置及所有 `CURRENT` 对应清单，在写入目标前保存将被覆盖的原配置；缺少任何清单就停止。文件按目录内容复制，重复执行不会嵌套 `*.userdb`。脚本不会删除本机配置或自动重新部署。

3. 右键小狼毫托盘菜单选择“重新部署”。随后确认雾凇、小鹤双拼、皮肤及常用自造词可用。

若读取配置到其它路径，可使用 `-Source <仓库根目录>` 和 `-Destination <目标Rime目录>`。

## 更新备份

完全退出小狼毫后执行：

```powershell
pwsh -NoProfile -File .\backup.ps1
```

输出位于 `Backup\<时间戳>\rime\`。脚本校验数据库清单、严格处理复制错误，排除 `build/` 编译缓存、`LOCK`、`LOG` 等诊断及锁文件，保留数值命名的事务日志和数据库表文件。复制成功、清单校验通过后才移除未完成标记。

更新仓库时，从这个完整快照替换整个 `rime/` 或整个需要更新的 `*.userdb/`，在仓库暂存副本中操作；不要把单个新 `MANIFEST` 与旧数据库表文件拼接。

## 用户词库快照

历史快照的 `rime_ice.userdb/CURRENT` 指向不存在的 `MANIFEST-000423`，不能可靠恢复。已在 **2026-10-11** 经用户授权，用本机完整快照替换整份雾凇用户词库：

- 当前清单：`MANIFEST-001249`。
- 数据库表：`001243.ldb`、`001245.ldb`。
- 事务日志：`001250.log`。
- 采集时小狼毫已退出，复制前后对源文件及快照进行了 SHA256 一致性校验，采集完成后已重新启动小狼毫。

本仓库公开，用户词频、自造词会随词库公开；再次更新词库前应确认发布范围。

## 目录映射与注意事项

| 仓库内容 | 目标及用途 |
|---|---|
| `rime/` | `%APPDATA%\Rime\`，配置目录 |
| `*.schema.yaml`、`*.dict.yaml`、`cn_dicts/`、`en_dicts/` | 输入方案和词典 |
| `default.custom.yaml`、`weasel.custom.yaml` | 方案列表和皮肤 |
| `lua/`、`opencc/`、`custom_phrase.txt` | 过滤器、转换和自定义短语 |
| `*.userdb/` | 学习词频、自造词，必须按整份数据库备份 |
| `installation.yaml`、`user.yaml` | 原机安装与部署信息 |

保留原来的 `installation_id`，不手动编辑数据库文件。重新部署会生成 `build/`，无需把它纳入备份。跨机使用前检查词频、自造词、输入方案及皮肤，而不能只看文件复制是否完成。


## 私有迁移数据（2026-10-11）

最新个人配置和状态存放在私有仓库 `64ty6/wezterm-yazi-nushell-starship` 的 `migration/data/
rime-weasel
`，本公开仓库保留脚本与可公开配置。完整恢复请参照私有仓库 `migration/README.md`，使用 `migration/restore-all.ps1`。单独调用此仓库的 `restore.ps1` 时，传入 `-Source <私有迁移快照目录>`。大型运行环境另存私有 Release 附件。

旧个人数据在当前分支已移除；此前公开提交的历史不在本次重写范围内。
