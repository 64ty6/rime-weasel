# Rime + 小狼毫 + 雾凇 配置备份

- **小狼毫** (Weasel) 0.17.4 — Windows 前端
- **Rime** 1.13.1 — 输入法引擎
- **雾凇拼音** (rime-ice) — 输入方案

## 快速还原

```powershell
# 1. 安装小狼毫到 D:\Tools\xiaolanghao
# 2. 执行还原
.\restore.ps1
# 3. 右键托盘 → 小狼毫 → 重新部署
```

## 目录说明

```
rime/   → %APPDATA%\Rime\
```

| 文件/目录 | 说明 |
|-----------|------|
| `weasel.custom.yaml` | 小狼毫自定义（皮肤、候选框样式） |
| `default.custom.yaml` | 用户自定义方案选择 |
| `rime_ice.*` | 雾凇拼音方案 |
| `cn_dicts/` / `en_dicts/` | 中英文词典 |
| `lua/` | 雾凇 Lua 脚本 |
| `opencc/` | 简繁转换 |
| `*.userdb/` | 用户词频学习数据 |

## 备份

```powershell
# 建议先关闭 Rime 输入法再备份（userdb 可能被锁定）
.\backup.ps1
```
