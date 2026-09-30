# Rime 输入法配置备份

本仓库是小狼毫（Weasel）+ Rime 引擎 + 雾凇拼音（rime-ice）的完整配置备份；新电脑上 clone 本仓库后，按本文档即可把输入法还原到与备份时一致的状态（方案、皮肤、词典、用户词频）。

- 仓库：`github.com/64ty6/rime-weasel`
- 小狼毫（Weasel）0.17.4 — Windows 前端，安装目录 `D:\Tools\xiaolanghao`
- Rime 引擎 1.13.1
- 输入方案：雾凇拼音 `rime_ice`，并启用了小鹤双拼 `double_pinyin_flypy`（见 `rime/default.custom.yaml`）
- 皮肤：`so_young`（见 `rime/weasel.custom.yaml`）

## 前置要求

在开始还原之前，确认以下条件：

1. **已安装小狼毫 0.17.4**，安装目录为 `D:\Tools\xiaolanghao`（若装在别处，见下文「注意事项」中的说明）。
2. **已退出小狼毫**：还原前必须退出小狼毫，或切换到其它输入法。否则运行中的 `WeaselServer` 会独占 `rime_ice.userdb`，写入可能失败或残留旧状态。
3. **可以访问 `%APPDATA%`**（即 `C:\Users\<用户名>\AppData\Roaming`）——配置的目标目录是 `%APPDATA%\Rime`。
4. 本仓库已 clone 到本机（AI 需要知道仓库根目录的绝对路径，下文记为 `<repo>`）。
5. 若 `%APPDATA%\Rime` 已存在（本机此前装过/配过 Rime），第 3 步会先改名备份，不会直接覆盖丢失。

## 还原步骤（AI 操作指引）

> **写给 AI**：请严格按顺序执行以下步骤，每一步都先确认「期望结果」再继续下一步。任何一步结果与预期不符，**必须停下来向用户报告并询问**，不要擅自跳过或猜测。本文档以 PowerShell 命令为主；仓库根的 `restore.ps1` 是备选一键方式（见第 6 步），**不要默认使用它**，优先执行下面的手动步骤以便逐步校验。

### 步骤 0：定位仓库路径

- 目的：确定 `<repo>` 的实际绝对路径，供后续命令使用。
- 命令：
  ```powershell
  # 在仓库根目录执行；或直接使用已知路径
  (Get-Location).Path
  ```
- 期望结果：得到形如 `C:\Users\xwd\projects\rime-weasel` 的路径，且该目录下存在 `rime\` 子目录与 `restore.ps1`。
- 不满足时：说明 clone 不完整，请用户确认仓库位置后重试。

### 步骤 1：确认小狼毫已安装

- 目的：确保目标机器已装好 0.17.4，避免还原后无程序可用。
- 命令：
  ```powershell
  Test-Path 'D:\Tools\xiaolanghao\WeaselServer.exe'
  (Get-Item 'D:\Tools\xiaolanghao\WeaselServer.exe').VersionInfo.FileVersion
  ```
  > 可执行文件名以实际安装为准，若 `WeaselServer.exe` 不存在，请列出 `D:\Tools\xiaolanghao` 目录内容确认（**此文件名需确认**）。
- 期望结果：第一行返回 `True`；第二行版本号以 `0.17.4` 开头。
- 不满足时：**停止**。请用户先从官方渠道安装小狼毫 0.17.4 到 `D:\Tools\xiaolanghao`，再继续。若用户装在其它目录，还原本身仍可进行，但请记录下来并提醒：托盘菜单/部署命令的路径需相应调整。

### 步骤 2：确认 WeaselServer 未运行

- 目的：避免小狼毫进程锁定词库（`*.userdb`），导致还原不完整或失败。
- 命令：
  ```powershell
  Get-Process WeaselServer -ErrorAction SilentlyContinue
  ```
- 期望结果：**没有任何输出**（进程不存在）。
- 不满足时：**先不要继续**。请用户执行以下任一操作后重新运行本步骤确认：
  - 右键任务栏托盘的小狼毫图标 → 退出；
  - 或切换到其它输入法（如微软拼音）并使用一段时间。
  - 若用户明确同意，也可运行 `Stop-Process -Name WeaselServer -Force`（**需先征得用户同意**）。
- 说明：`luna_pinyin.userdb` 可完整直接恢复；`rime_ice.userdb` 对进程锁更敏感，因此这一步必须确认干净。

### 步骤 3：备份本机已有的 `%APPDATA%\Rime`（若存在）

- 目的：保留用户本机原有配置，便于回滚。
- 命令：
  ```powershell
  $dst = "$env:APPDATA\Rime"
  $bak = "$dst.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  if (Test-Path $dst) { Rename-Item -Path $dst -NewName $bak; "已备份原目录到 $bak" } else { "本机无原 Rime 目录，无需备份" }
  ```
- 期望结果：输出「已备份…」或「本机无原 Rime 目录…」。
- 不满足时：若 Rename 因「目录被占用」失败，说明仍有 Rime 相关进程在运行，回到步骤 2 处理。

### 步骤 4：复制 `rime/` 到 `%APPDATA%\Rime`

- 目的：把备份的配置部署到 Rime 的实际配置目录。
- 命令：
  ```powershell
  $repo = '<repo>'                     # 替换为步骤 0 得到的实际路径
  $src  = Join-Path $repo 'rime'
  $dst  = "$env:APPDATA\Rime"
  New-Item -ItemType Directory -Path $dst -Force | Out-Null
  Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
  ```
- 期望结果：命令无报错；复制完成后目录中可看到关键文件：
  ```powershell
  Get-ChildItem $dst | Select-Object Name
  # 应包含：rime_ice.schema.yaml、rime_ice.dict.yaml、default.custom.yaml、
  #         weasel.custom.yaml、installation.yaml、user.yaml、
  #         cn_dicts、en_dicts、lua、opencc、rime_ice.userdb、luna_pinyin.userdb 等
  ```
  并确认两个词库目录已就位：
  ```powershell
  Get-ChildItem "$dst\rime_ice.userdb", "$dst\luna_pinyin.userdb" -ErrorAction SilentlyContinue
  ```
- 不满足时：
  - 若提示拒绝访问/文件被占用 → 回到步骤 2，确认 `WeaselServer` 已退出，再重试。
  - 若缺少 `*.userdb` → 可能是 clone 或复制不完整，请用户确认仓库内容后重试。

### 步骤 5：触发重新部署

- 目的：让 Rime 读取新配置、重建 `build\` 编译缓存并生效。
- 操作（**这一步是 GUI 操作，AI 无法代替用户点击**）：请用户执行
  **右键任务栏托盘的小狼毫图标 → 小狼毫 → 重新部署**。
- 备选（命令行，**需确认**）：若安装目录内存在 `WeaselDeployer.exe`，可尝试
  ```powershell
  & 'D:\Tools\xiaolanghao\WeaselDeployer.exe' /deploy
  ```
  该参数在当前环境**未经验证**，如失败请改用上面的托盘菜单方式。
- 期望结果：部署过程中托盘图标可能出现短暂变化；部署完成后 `%APPDATA%\Rime\build\` 目录被重新生成（该目录**不在备份内**，属正常现象）。
  ```powershell
  Test-Path "$env:APPDATA\Rime\build"
  ```
  应返回 `True`。
- 不满足时：询问用户重新部署是否成功；若 `build\` 未生成，检查 `%APPDATA%\Rime\build\rime.weasel.log`（如存在）排查报错。

### 步骤 6（备选）：使用 `restore.ps1`

若用户希望一键还原，可在仓库根执行：

```powershell
# 先确保已退出小狼毫（见步骤 2）
.\restore.ps1
# 然后同样需要手动执行"重新部署"（见步骤 5）
```

`restore.ps1` 做的事与步骤 4 等价：把仓库 `rime\` 下的所有条目递归复制到 `%APPDATA%\Rime`（**注意：它不会先备份本机已有目录，也不会自动触发部署**）。因此仍建议优先走手动步骤以便逐步校验。

## 还原后要做的事

1. **重新部署**：右键托盘 → 小狼毫 → 重新部署（等价于步骤 5）。修改配置后必须重新部署才会生效。
2. **验证输入方案可用**：
   - 在任意文本框调出小狼毫，用快捷键（默认 `Ctrl+`` ` ``）切换方案；
   - 确认可切换到 `雾凇拼音`（rime_ice）与 `小鹤双拼`（double_pinyin_flypy）；
   - 随便输入几个词，确认候选、皮肤正常，且词频/自造词能生效（说明 userdb 已加载）。
3. **验证皮肤**：确认候选框样式为 `so_young`（来自 `weasel.custom.yaml`）。
4. 若用户使用过「用户词典/自造词」，请重点验证步骤 2 提到的 `rime_ice.userdb` 是否生效（见「注意事项」）。

## 目录对照表

| 仓库内路径 | 目标路径 | 说明 |
|---|---|---|
| `rime/` | `%APPDATA%\Rime\` | 整个配置目录，一一对应复制 |
| `rime/installation.yaml` | `%APPDATA%\Rime\installation.yaml` | 安装信息（版本、installation_id、安装时间） |
| `rime/default.custom.yaml` | `%APPDATA%\Rime\default.custom.yaml` | 用户方案列表（rime_ice、double_pinyin_flypy） |
| `rime/weasel.custom.yaml` | `%APPDATA%\Rime\weasel.custom.yaml` | 小狼毫自定义（皮肤 `so_young`） |
| `rime/user.yaml` | `%APPDATA%\Rime\user.yaml` | 上次构建时间戳等 |
| `rime/rime_ice.schema.yaml` / `rime/rime_ice.dict.yaml` | 同左 | 雾凇拼音方案与主词典定义 |
| `rime/double_pinyin_*.schema.yaml` | 同左 | 各类双拼方案（含已启用的 `double_pinyin_flypy`） |
| `rime/cn_dicts/`、`rime/en_dicts/`、`rime/all_dicts/` | 同左 | 中英文词典数据 |
| `rime/lua/` | 同左 | 雾凇拼音的 Lua 脚本（含 `cold_word_drop` 等） |
| `rime/opencc/` | 同左 | 简繁转换数据 |
| `rime/others/` | 同左 | 上游其它平台相关文件（Windows 一般用不到，可保留） |
| `rime/*.userdb/` | 同左 | 用户词频学习数据（见下文说明） |
| `rime/README.md`、`rime/LICENSE` | 同左 | 上游 rime-ice 自带文件 |
| `restore.ps1`、`backup.ps1` | （不复制） | 仓库自带的还原/备份辅助脚本 |

## 备份范围

**包含**：`%APPDATA%\Rime` 下的全部配置——方案文件（`*.schema.yaml`）、词典（`*.dict.yaml`、`cn_dicts/`、`en_dicts/`、`all_dicts/`）、Lua 脚本、opencc 数据、皮肤与自定义（`weasel.custom.yaml` 等）、安装信息（`installation.yaml`）、自定义短语（`custom_phrase.txt`）、符号表（`symbols_*.yaml`）以及 `*.userdb/` 用户词库。

**排除**：
- `build/` — Rime 的编译缓存，体积大且可由「重新部署」自动重建；
- `.github/`、`.gitignore` — 与运行无关的仓库元数据；
- `rime-ice-main/` — 上游第三方项目源码，不属于本机配置。

**关于 `*.userdb/`（用户词库）**：这是 Rime 记录用户词频与自造词的学习数据，直接决定「用久了越顺手」的效果，务必随配置一起备份/还原。
- `luna_pinyin.userdb/`：完整，含 `MANIFEST-000004`，**可直接恢复**。
- `rime_ice.userdb/`：**易受进程锁影响**，详见「注意事项」第 1 条。截至最近一次提交，本仓库中的 `rime_ice.userdb` 缺少其 `CURRENT` 所指向的 `MANIFEST-000423` 文件（提交记录亦注明"用户词库因小狼毫进程锁定本次未同步"），因此该词库当前**不能保证直接恢复**，需按「更新备份」一节重新采集。

## 更新备份

当配置或词频发生变化、需要刷新本仓库时：

1. **先切换到其它输入法，或彻底退出小狼毫**（务必先做，否则 `rime_ice.userdb` 会被 `WeaselServer` 独占锁定，读不到关键的 `MANIFEST` 文件，备份出的词库不完整、无法直接恢复——本仓库历史上就是这样丢过 `MANIFEST`）。
2. 确认进程已退出：
   ```powershell
   Get-Process WeaselServer -ErrorAction SilentlyContinue   # 应无输出
   ```
3. 把 `%APPDATA%\Rime` 的内容复制到仓库 `rime/`，并删除 `build/` 等排除项。也可以运行仓库自带的 `backup.ps1`（它会复制到 `Backup\<时间戳>\`，但**不作为最终提交目录**；正式备份请落盘到 `rime/`）：
   ```powershell
   $src = "$env:APPDATA\Rime"
   $dst = '<repo>\rime'
   robocopy $src $dst /MIR /XD build .github rime-ice-main /XF .gitignore
   ```
   > 上面用 `robocopy` 做镜像同步并排除 `build` 等；请按实际需要调整，执行前先确认 `<repo>\rime` 路径无误。
4. **校验词库完整性**（关键）：
   ```powershell
   $c = Get-Content "$dst\rime_ice.userdb\CURRENT"
   Test-Path "$dst\rime_ice.userdb\$c"     # 期望 True；False 说明 MANIFEST 缺失，备份不完整
   Test-Path "$dst\luna_pinyin.userdb\MANIFEST-000004"   # 期望 True
   ```
   若 `CURRENT` 指向的 MANIFEST 不存在，说明小狼毫未真正退出，请回到第 1 步。
5. 提交并推送（Windows git）。

## 注意事项

1. **词库锁定的坑（最重要）**：备份/还原 `*.userdb` 时若小狼毫正在运行，`WeaselServer` 会独占词库文件，导致只能读到部分文件、读不到 `MANIFEST`（LevelDB 的元数据入口）。这样的词库无法直接恢复，只会表现为"词频丢失"。**任何备份或还原前后，都必须先退出小狼毫或切换输入法。** `luna_pinyin.userdb` 目前完整可直接恢复；`rime_ice.userdb` 需特别留意。
2. **必须重新部署**：还原或修改任何配置后，都要「右键托盘 → 小狼毫 → 重新部署」才会生效。`build/` 目录会在部署时自动重建，无需备份。
3. **方案文件对应关系**：`default.custom.yaml` 中的 `schema_list` 决定启用哪些方案（当前为 `rime_ice`、`double_pinyin_flypy`）；每个方案由 `<方案名>.schema.yaml`（行为）+ `<方案名>.dict.yaml`（词表）+ 词典目录共同定义。皮肤由 `weasel.custom.yaml` 的 `style/color_scheme`（当前 `so_young`）指定。
4. **安装路径**：本备份对应小狼毫装在 `D:\Tools\xiaolanghao`。若新机器装在其它目录，配置本身不受影响，但托盘部署与（若使用的）命令行部署路径需相应调整。
5. **`installation.yaml`**：内含 `installation_id` 与 `install_time`。还原时一并复制即可；若用户希望被识别为"同一台机器"以继续使用同步等能力，请保留原 `installation_id` 不要手改。
6. **不要手动编辑 `*.userdb/`**：这是 LevelDB 数据库目录，文件间相互依赖；只能用 Rime 自身读写，不要单独增删其中的文件。
7. **Windows 路径大小写**：Windows 下路径不区分大小写，但请统一使用文档中的标准写法，避免复制粘贴时引入错误。
