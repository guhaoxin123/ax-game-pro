#!/system/bin/sh

optimize_gpu() {
    log_info "[GPU] ===== 开始深度优化 ====="
    [ "$ENABLE_GPU" != "1" ] && return

    # 1. 调频器
    for gov in /sys/class/kgsl/kgsl-3d0/devfreq/governor \
               /sys/class/devfreq/*.mali/governor \
               /sys/class/devfreq/mtk-mali/governor \
               /sys/class/devfreq/gpufreq/governor \
               /sys/kernel/gpu/gpu_governor; do
        [ -e "$gov" ] && {
            save_orig "gpu_gov_${gov}" "$gov"
            safe_write "$gov" "performance" || safe_write "$gov" "simple_ondemand"
        }
    done

    # 2. 频率范围
    for min in /sys/class/kgsl/kgsl-3d0/devfreq/min_freq \
               /sys/class/devfreq/*.mali/min_freq \
               /sys/class/devfreq/mtk-mali/min_freq; do
        [ -e "$min" ] && {
            local max=$(cat "${min%min_freq}max_freq" 2>/dev/null)
            [ -n "$max" ] && {
                save_orig "gpu_min_${min}" "$min"
                safe_write "$min" "$((max * 60 / 100))"
            }
        }
    done

    # 3. Adreno 强制开启
    safe_write /sys/class/kgsl/kgsl-3d0/force_clk_on "1"
    safe_write /sys/class/kgsl/kgsl-3d0/force_bus_on "1"
    safe_write /sys/class/kgsl/kgsl-3d0/force_rail_on "1"
    safe_write /sys/class/kgsl/kgsl-3d0/force_no_nap "1"
    safe_write /sys/class/kgsl/kgsl-3d0/bus_split "0"
    safe_write /sys/class/kgsl/kgsl-3d0/max_pwrlevel "0"
    safe_write /sys/class/kgsl/kgsl-3d0/min_pwrlevel "0"
    safe_write /sys/class/kgsl/kgsl-3d0/default_pwrlevel "0"
    safe_write /sys/class/kgsl/kgsl-3d0/idle_timer "10000"
    safe_write /sys/class/kgsl/kgsl-3d0/throttling "0"
    safe_write /sys/class/kgsl/kgsl-3d0/thermal_pwrlevel "0"

    # 4. AdrenoBoost
    safe_write /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost "1"
    safe_write /sys/class/kgsl/kgsl-3d0/devfreq/polling_interval "10"

    # 5. Mali 相关
    for m in /sys/class/devfreq/*.mali/*; do
        case "$m" in
            *upthreshold) safe_write "$m" "50" ;;
            *downdifferential) safe_write "$m" "10" ;;
            *polling_interval) safe_write "$m" "10" ;;
        esac
    done

    # 6. GPU 调度
    safe_write /sys/module/msm_performance/parameters/gpu_min_freq "0"
    safe_write /sys/kernel/gpu/gpu_min_clock "0"
    safe_write /sys/kernel/gpu/gpu_max_clock "0"

    # 7. DDR / 总线
    for bus in /sys/class/devfreq/soc:qcom,cpubw/governor \
               /sys/class/devfreq/soc:qcom,memlat-cpu0/governor; do
        safe_write "$bus" "performance"
    done

    # 8. GPU 调试关闭
    safe_write /sys/module/msm_kgsl/parameters/kgsl_debug "0"
    safe_write /sys/kernel/debug/kgsl/kgsl-3d0/debug "0"

    log_info "[GPU] ===== 优化完成 ====="
}

restore_gpu() {
    for gov in /sys/class/kgsl/kgsl-3d0/devfreq/governor \
               /sys/class/devfreq/*.mali/governor; do
        restore_value "gpu_gov_${gov}" "$gov"
    done
    for min in /sys/class/kgsl/kgsl-3d0/devfreq/min_freq; do
        restore_value "gpu_min_${min}" "$min"
    done
    safe_write /sys/class/kgsl/kgsl-3d0/force_clk_on "0"
    safe_write /sys/class/kgsl/kgsl-3d0/force_bus_on "0"
    safe_write /sys/class/kgsl/kgsl-3d0/force_rail_on "0"
    safe_write /sys/class/kgsl/kgsl-3d0/force_no_nap "0"
    safe_write /sys/class/kgsl/kgsl-3d0/throttling "1"
}