# 智能游戏优化 Pro

<img src="banner.jpg" width="100%">

自动识别前台游戏，按游戏分别调 CPU / GPU / 内存 / 渲染 / 网络，退出后自动恢复原状。

## 功能
- 前台识别：检测到游戏启动即进入优化，退出或切后台自动回滚
- 分模块策略：`lib/` 下 cpu、gpu、mem、io、net、render、thermal、process 各自独立
- 游戏名单：`game_list.txt` 自定义要优化的包名，`blacklist.txt` 排除不处理的
- 配置：`config.conf` 调开关与档位，`scripts/balance_mode.sh` 提供均衡模式
- 撤出即恢复：不写死参数，退出游戏还原

## 安装
1. 到 [Releases](../../releases) 下载 `ax-game-pro-v3.0.zip`
2. AxManager / 模块管理器从本地导入
3. 重启后常驻；把想优化的游戏包名加进 `game_list.txt` 即可

## 目录
```
module.prop  customize.sh  post-fs-data.sh  service.sh  action.sh  uninstall.sh
boot-completed.sh  config.conf  game_list.txt  blacklist.txt
lib/     cpu gpu mem io net render thermal process monitor detect logger common adb
scripts/ game_optimizer.sh  game_add.sh  balance_mode.sh
```

## 说明
作者 ghx；本仓库由 DSH 整理、重命名并统一打包。`lib/` 与 `scripts/` 的目录结构不能改，脚本靠相对路径互相引用。
