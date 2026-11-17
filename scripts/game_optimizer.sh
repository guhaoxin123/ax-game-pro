#!/system/bin/sh
MODDIR="${0%/*}/.."
. "$MODDIR/lib/common.sh"
. "$MODDIR/lib/detect.sh"
. "$MODDIR/lib/cpu.sh"
. "$MODDIR/lib/gpu.sh"
. "$MODDIR/lib/mem.sh"
. "$MODDIR/lib/net.sh"
. "$MODDIR/lib/io.sh"
. "$MODDIR/lib/render.sh"
. "$MODDIR/lib/thermal.sh"
. "$MODDIR/lib/process.sh"
. "$MODDIR/lib/monitor.sh"
. "$MODDIR/lib/logger.sh"
. "$MODDIR/lib/adb.sh"

CURRENT_GAME=""

apply_all() {
    local game="$1"
    log_info "=== 游戏启动: $game ==="
    set_current_game "$game"
    rm -f "$ORIG_STATE"

    adb_optimize_all "$game"

    optimize_cpu
    optimize_gpu
    optimize_mem
    optimize_net
    optimize_io
    optimize_render
    optimize_thermal
    optimize_process "$game"

    notify "🎮 游戏性能优化" "已启动: $game"
    log_info "=== 全部优化已应用 ==="
}

restore_all() {
    local game="$1"
    log_info "=== 恢复原始设置 ==="

    adb_restore_all "$game"

    restore_cpu
    restore_gpu
    restore_mem
    restore_net
    restore_io
    restore_render

    rm -f "$ORIG_STATE"
    set_current_game ""
    notify "🎮 游戏性能优化" "已恢复系统设置"
    log_info "=== 恢复完成 ==="
}

main() {
    echo $$ > "$PID_FILE"
    log_info "========== 游戏性能优化器启动 =========="
    log_info "配置: THERMAL_LIMIT=${THERMAL_LIMIT} CHECK_INTERVAL=${CHECK_INTERVAL}"

    log_rotate_loop &
    monitor_loop &

    local last_game=""
    while true; do
        local cur=$(get_foreground_app)
        if is_game "$cur" && [ "$cur" != "$last_game" ]; then
            last_game="$cur"
            CURRENT_GAME="$cur"
            sleep 3
            [ "$(get_foreground_app)" = "$cur" ] && apply_all "$cur"
        fi
        if [ -n "$last_game" ] && [ "$cur" != "$last_game" ]; then
            restore_all "$last_game"
            last_game=""
            CURRENT_GAME=""
        fi
        sleep "$CHECK_INTERVAL"
    done
}

case "$1" in
    restore) restore_all "$CURRENT_GAME"; exit 0 ;;
    apply)   apply_all "$2"; exit 0 ;;
    *)       main ;;
esac