#!/system/bin/sh

optimize_process() {
    log_info "[进程] ===== 开始清理 ====="
    [ "$ENABLE_PROCESS_KILL" != "1" ] && return
    [ "$KILL_LEVEL" = "none" ] && return

    local game="$1"

    if [ "$KILL_LEVEL" = "aggressive" ]; then
        for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
            [ "$pkg" = "$game" ] && continue
            grep -qxF "$pkg" "$BLACKLIST" 2>/dev/null && continue
            am force-stop "$pkg" 2>/dev/null
        done
    elif [ "$KILL_LEVEL" = "light" ]; then
        for pkg in com.google.android.apps.photos \
                   com.google.android.apps.maps \
                   com.google.android.youtube \
                   com.facebook.katana \
                   com.instagram.android; do
            [ "$pkg" = "$game" ] && continue
            am force-stop "$pkg" 2>/dev/null
        done
    fi

    for pid in $(pgrep -f "$game" 2>/dev/null); do
        safe_write "/proc/$pid/oom_score_adj" "-1000"
    done

    for pid in $(pgrep -f "$game" 2>/dev/null); do
        echo "$pid" > /dev/cpuset/top-app/tasks 2>/dev/null
        echo "$pid" > /dev/stune/top-app/tasks 2>/dev/null
        echo "$pid" > /dev/cpuctl/top-app/tasks 2>/dev/null
    done

    sync 2>/dev/null
    safe_write /proc/sys/vm/drop_caches "3"

    for svc in com.android.wallpaper \
               com.android.dreams.phototable \
               com.google.android.gms.persistent; do
        am force-stop "$svc" 2>/dev/null
    done

    log_info "[进程] ===== 清理完成 ====="
}