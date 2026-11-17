#!/system/bin/sh
SKIPUNZIP=0

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/lib 0 0 0755 0755
set_perm_recursive $MODPATH/scripts 0 0 0755 0755
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/boot-completed.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755
set_perm $MODPATH/action.sh 0 0 0755

ui_print "================================"
ui_print "  游戏性能优化器 已安装"
ui_print "================================"
ui_print "配置文件: $MODPATH/config.conf"
ui_print "日志: /data/local/tmp/game_optimizer/"
ui_print "================================"