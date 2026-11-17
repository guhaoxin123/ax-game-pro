#!/system/bin/sh
MODDIR="${0%/*}/.."
. "$MODDIR/lib/common.sh"

[ -z "$1" ] && echo "用法: game_add.sh <包名>" && exit 1
grep -qxF "$1" "$GAME_LIST" 2>/dev/null || echo "$1" >> "$GAME_LIST"
echo "已添加: $1"
log_info "白名单添加: $1"