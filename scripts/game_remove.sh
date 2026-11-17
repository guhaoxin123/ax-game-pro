#!/system/bin/sh
MODDIR="${0%/*}/.."
. "$MODDIR/lib/common.sh"

[ -z "$1" ] && echo "用法: game_remove.sh <包名>" && exit 1

if grep -qxF "$1" "$GAME_LIST" 2>/dev/null; then
    grep -vxF "$1" "$GAME_LIST" > "$GAME_LIST.tmp"
    mv "$GAME_LIST.tmp" "$GAME_LIST"
    echo "已移除: $1"
    log_info "白名单移除: $1"
else
    echo "未找到: $1"
    exit 1
fi