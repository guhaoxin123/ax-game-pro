#!/system/bin/sh

monitor_loop() {
    while true; do
        local load1=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
        local temp=$(read_cpu_temp)
        local mem_free=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
        local mem_free_mb=$((mem_free / 1024))

        log_debug "负载=${load1} 温度=${temp}°C 可用内存=${mem_free_mb}MB"

        check_thermal

        if [ "$mem_free_mb" -lt 500 ]; then
            log_warn "内存不足 (${mem_free_mb}MB)，执行回收"
            sync 2>/dev/null
            safe_write /proc/sys/vm/drop_caches "1"
        fi

        sleep 30
    done
}