#!/system/bin/sh
# ============================================
# ADB 原生 API 优化层（Android 12+ 主力）
# 走系统 API，不依赖 SELinux 放开的 sysfs 节点
# ============================================

# ---------- 1. 游戏模式（Android 12+） ----------
apply_game_mode() {
    local pkg="$1"
    [ -z "$pkg" ] && return

    log_info "[ADB] 切换游戏模式: $pkg"

    # 系统级游戏模式 → performance
    cmd game mode performance "$pkg" 2>/dev/null

    # 部分设备支持直接设帧率
    cmd game set --fps 120 "$pkg" 2>/dev/null

    # 干预配置：降低后台缓冲缩放，减少 GPU 负载
    # mode=2 为 performance，downscaleFactor 0.9 保守降负载
    device_config put game_overlay "$pkg" \
        "mode=2,downscaleFactor=0.9:mode=3,downscaleFactor=0.5" 2>/dev/null

    log_info "[ADB] 游戏模式已应用"
}

reset_game_mode() {
    local pkg="$1"
    [ -z "$pkg" ] && return
    cmd game mode standard "$pkg" 2>/dev/null
    device_config delete game_overlay "$pkg" 2>/dev/null
    log_info "[ADB] 游戏模式已恢复: $pkg"
}

# ---------- 2. 固定性能模式 ----------
enable_fixed_perf() {
    log_info "[ADB] 开启固定性能模式"
    cmd power set-fixed-performance-mode-enabled true 2>/dev/null
}

disable_fixed_perf() {
    cmd power set-fixed-performance-mode-enabled false 2>/dev/null
    log_info "[ADB] 固定性能模式已关闭"
}

# ---------- 3. UClamp（Android 12+ 调度器接口） ----------
apply_uclamp() {
    log_info "[ADB] 配置 UClamp"

    # 让调度器立即给 top-app 满性能，不等算法学习
    safe_write /dev/cpuctl/top-app/cpu.uclamp.min "1024"
    safe_write /dev/cpuctl/top-app/cpu.uclamp.max "1024"

    # 延迟敏感标记
    safe_write /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive "1"

    # foreground 组次一级
    safe_write /dev/cpuctl/foreground/cpu.uclamp.min "512"

    log_info "[ADB] UClamp 已配置"
}

# ---------- 4. CGroup v2 优先级迁移 ----------
migrate_game_to_topapp() {
    local pkg="$1"
    [ -z "$pkg" ] && return

    local pids=$(pidof "$pkg" 2>/dev/null)
    [ -z "$pids" ] && return

    for pid in $pids; do
        echo "$pid" > /dev/cpuctl/top-app/tasks 2>/dev/null
        echo "$pid" > /dev/cpuset/top-app/tasks 2>/dev/null
        echo "$pid" > /dev/stune/top-app/tasks 2>/dev/null
        # 提升优先级
        renice -n -10 -p "$pid" 2>/dev/null
    done

    log_info "[ADB] 游戏进程已迁移 top-app: $pids"
}

# ---------- 5. 后台核限制 ----------
restrict_background_cpus() {
    log_info "[ADB] 后台限制小核"

    # 系统后台只允许小核
    safe_write /dev/cpuset/system-background/cpus "0-3"
    safe_write /dev/cpuset/restricted/cpus "0-3"
    safe_write /dev/cpuset/background/cpus "0-3"
}

restore_background_cpus() {
    safe_write /dev/cpuset/system-background/cpus "0-7"
    safe_write /dev/cpuset/restricted/cpus "0-7"
    safe_write /dev/cpuset/background/cpus "0-7"
}

# ---------- 6. 后台冻结 ----------
enable_freezer() {
    log_info "[ADB] 启用后台冻结"
    settings put global cached_apps_freezer enabled 2>/dev/null
}

disable_freezer() {
    settings put global cached_apps_freezer default 2>/dev/null
}

# ---------- 7. 刷新率锁定 ----------
lock_refresh_rate() {
    local rate="${1:-120}"
    log_info "[ADB] 锁定刷新率: ${rate}Hz"
    settings put system peak_refresh_rate "$rate.0" 2>/dev/null
    settings put system min_refresh_rate "$rate.0" 2>/dev/null
}

unlock_refresh_rate() {
    settings delete system peak_refresh_rate 2>/dev/null
    settings delete system min_refresh_rate 2>/dev/null
}

# ---------- 8. 网络策略 ----------
apply_net_policy() {
    log_info "[ADB] 应用网络策略"
    cmd netpolicy set restrict-background true 2>/dev/null
}

restore_net_policy() {
    cmd netpolicy set restrict-background false 2>/dev/null
}

# ---------- 9. 应用待机分组 ----------
set_app_standby_active() {
    local pkg="$1"
    [ -z "$pkg" ] && return
    am set-standby-bucket "$pkg" active 2>/dev/null
    log_info "[ADB] 设置 $pkg 为 active"
}

set_app_standby_rare() {
    local pkg="$1"
    [ -z "$pkg" ] && return
    am set-standby-bucket "$pkg" rare 2>/dev/null
}

# ---------- 10. 统一入口 ----------
adb_optimize_all() {
    local pkg="$1"
    log_info "[ADB] ===== 开始 ADB 层优化 ====="

    apply_game_mode "$pkg"
    enable_fixed_perf
    apply_uclamp
    migrate_game_to_topapp "$pkg"
    restrict_background_cpus
    enable_freezer
    lock_refresh_rate 120
    apply_net_policy
    set_app_standby_active "$pkg"

    log_info "[ADB] ===== ADB 层优化完成 ====="
}

adb_restore_all() {
    local pkg="$1"
    log_info "[ADB] ===== 恢复 ADB 层 ====="

    reset_game_mode "$pkg"
    disable_fixed_perf
    restore_background_cpus
    disable_freezer
    unlock_refresh_rate
    restore_net_policy
    set_app_standby_rare "$pkg"

    log_info "[ADB] ===== ADB 层已恢复 ====="
}