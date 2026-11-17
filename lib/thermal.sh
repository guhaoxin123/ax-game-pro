#!/system/bin/sh

optimize_thermal() {
    log_info "[热管理] ===== 开始调整 ====="
    [ "$ENABLE_THERMAL" != "1" ] && return

    for zone in /sys/class/thermal/thermal_zone*/policy; do
        [ -e "$zone" ] && safe_write "$zone" "step_wise"
    done

    for trip in /sys/class/thermal/thermal_zone*/trip_point_*_temp; do
        [ -e "$trip" ] || continue
        local cur=$(cat "$trip" 2>/dev/null)
        [ -z "$cur" ] && continue
        save_orig "thermal_${trip}" "$trip"
        safe_write "$trip" "$((cur + 5000))"
    done

    for cd in /sys/class/thermal/cooling_device*/cur_state; do
        [ -e "$cd" ] || continue
        local type=$(cat "${cd%cur_state}type" 2>/dev/null)
        case "$type" in
            *battery*|*batt*) continue ;;
            *gpu*|*cpu*)
                save_orig "cool_${cd}" "$cd"
                safe_write "$cd" "0"
                ;;
        esac
    done

    for th in /sys/module/msm_thermal/parameters/enabled \
              /sys/module/msm_thermal/core_control/enabled \
              /sys/module/msm_thermal/parameters/limit_temp_degC; do
        case "$th" in
            *enabled) safe_write "$th" "Y" ;;
            *limit_temp_degC) safe_write "$th" "85" ;;
        esac
    done

    log_info "[热管理] ===== 调整完成 ====="
}

# ---------- 温度检查（带报警去重） ----------
LAST_THERMAL_WARN=0
LAST_THERMAL_TEMP=0

check_thermal() {
    local temp=$(read_cpu_temp)
    [ "$temp" -le 0 ] && return 0

    if [ "$temp" -gt "$THERMAL_LIMIT" ]; then
        local now=$(date +%s)
        local elapsed=$((now - LAST_THERMAL_WARN))

        # 60 秒内同温度段只报一次
        if [ "$elapsed" -gt 60 ] || [ "$((temp / 5))" != "$((LAST_THERMAL_TEMP / 5))" ]; then
            log_warn "温度 ${temp}°C 超过阈值 ${THERMAL_LIMIT}°C，降低频率目标"
            LAST_THERMAL_WARN=$now
            LAST_THERMAL_TEMP=$temp
        fi

        for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
            [ -d "$cpu" ] || continue
            local max=$(cat "$cpu/cpuinfo_max_freq" 2>/dev/null)
            [ -n "$max" ] && safe_write "$cpu/scaling_max_freq" "$((max * 80 / 100))"
        done
        return 1
    fi
    return 0
}