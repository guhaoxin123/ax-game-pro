#!/system/bin/sh

optimize_cpu() {
    log_info "[CPU] ===== 开始深度优化 ====="
    [ "$ENABLE_CPU" != "1" ] && return

    # 1. 调频器
    for gov in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
        [ -e "$gov" ] || continue
        save_orig "cpu_gov_${gov}" "$gov"
        safe_write "$gov" "performance" || \
        safe_write "$gov" "schedutil" || \
        safe_write "$gov" "interactive"
    done

    # 2. 频率锁定
    for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
        [ -d "$cpu" ] || continue
        local max=$(cat "$cpu/cpuinfo_max_freq" 2>/dev/null)
        [ -n "$max" ] && {
            save_orig "cpu_min_${cpu}" "$cpu/scaling_min_freq"
            save_orig "cpu_max_${cpu}" "$cpu/scaling_max_freq"
            safe_write "$cpu/scaling_min_freq" "$((max * 50 / 100))"
            safe_write "$cpu/scaling_max_freq" "$max"
        }
    done

    # 3. 核心热插拔
    for core in /sys/devices/system/cpu/cpu[1-9]*/online; do
        safe_write "$core" "1"
    done
    for ctl in /sys/devices/system/cpu/cpu[0-9]*/core_ctl/enable; do
        safe_write "$ctl" "0"
    done
    for hp in /sys/kernel/hotplug/mp_decision_enable \
              /sys/module/msm_thermal/core_control/enabled; do
        safe_write "$hp" "0"
    done

    # 4. stune / uclamp
    for stune in /dev/stune/top-app/schedtune.boost \
                 /dev/stune/foreground/schedtune.boost \
                 /dev/stune/rt/schedtune.boost \
                 /dev/cpuset/top-app/schedtune.boost; do
        save_orig "stune_${stune}" "$stune"
        safe_write "$stune" "50"
    done
    for uc in /dev/stune/top-app/schedtune.util_clamp \
              /dev/stune/foreground/schedtune.util_clamp; do
        safe_write "$uc" "1024"
    done

    # 5. cpuset 分组
    for cs in /dev/cpuset/top-app/cpus /dev/cpuset/foreground/cpus; do
        [ -e "$cs" ] && {
            save_orig "cpuset_${cs}" "$cs"
            safe_write "$cs" "0-7"
        }
    done

    # 6. 调度器参数
    safe_write /proc/sys/kernel/sched_min_granularity_ns "2000000"
    safe_write /proc/sys/kernel/sched_wakeup_granularity_ns "1000000"
    safe_write /proc/sys/kernel/sched_latency_ns "8000000"
    safe_write /proc/sys/kernel/sched_nr_migrate "32"
    safe_write /proc/sys/kernel/sched_migration_cost_ns "500000"
    safe_write /proc/sys/kernel/sched_rt_runtime_us "950000"
    safe_write /proc/sys/kernel/sched_autogroup_enabled "0"

    # 7. cgroup 权重
    for w in /dev/cpuctl/top-app/cpu.shares \
             /dev/cpuctl/foreground/cpu.shares; do
        [ -e "$w" ] && safe_write "$w" "10240"
    done

    # 8. CPU Boost
    for b in /sys/module/cpu_boost/parameters/input_boost_enabled \
             /sys/module/cpu_boost/parameters/sched_boost_on_input \
             /sys/module/cpu_boost/parameters/dynamic_stune_boost; do
        safe_write "$b" "1"
    done
    safe_write /sys/module/cpu_boost/parameters/input_boost_ms "1000"

    # 9. 关闭省电
    setprop power.saving.mode 0 2>/dev/null
    settings put global low_power 0 2>/dev/null

    # 10. 大小核亲和
    safe_write /proc/sys/kernel/sched_group_upmigrate "95"
    safe_write /proc/sys/kernel/sched_group_downmigrate "95"

    log_info "[CPU] ===== 优化完成 ====="
}

restore_cpu() {
    for gov in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
        restore_value "cpu_gov_${gov}" "$gov"
    done
    for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_min_freq; do
        restore_value "cpu_min_${cpu%scaling_min_freq}" "$cpu"
    done
    for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_max_freq; do
        restore_value "cpu_max_${cpu%scaling_max_freq}" "$cpu"
    done
    for stune in /dev/stune/top-app/schedtune.boost \
                 /dev/stune/foreground/schedtune.boost; do
        restore_value "stune_${stune}" "$stune"
    done
    for cs in /dev/cpuset/top-app/cpus /dev/cpuset/foreground/cpus; do
        restore_value "cpuset_${cs}" "$cs"
    done
}