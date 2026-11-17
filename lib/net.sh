#!/system/bin/sh

optimize_net() {
    log_info "[网络] ===== 开始深度优化 ====="
    [ "$ENABLE_NET" != "1" ] && return

    safe_write /proc/sys/net/ipv4/tcp_low_latency "1"
    safe_write /proc/sys/net/ipv4/tcp_timestamps "1"
    safe_write /proc/sys/net/ipv4/tcp_sack "1"
    safe_write /proc/sys/net/ipv4/tcp_fack "1"
    safe_write /proc/sys/net/ipv4/tcp_window_scaling "1"
    safe_write /proc/sys/net/ipv4/tcp_no_metrics_save "1"
    safe_write /proc/sys/net/ipv4/tcp_moderate_rcvbuf "1"
    safe_write /proc/sys/net/ipv4/tcp_ecn "1"
    safe_write /proc/sys/net/ipv4/tcp_dsack "1"
    safe_write /proc/sys/net/ipv4/tcp_mtu_probing "1"
    safe_write /proc/sys/net/ipv4/tcp_slow_start_after_idle "0"
    safe_write /proc/sys/net/ipv4/tcp_frto "2"

    safe_write /proc/sys/net/ipv4/tcp_retries1 "3"
    safe_write /proc/sys/net/ipv4/tcp_retries2 "8"
    safe_write /proc/sys/net/ipv4/tcp_syn_retries "3"
    safe_write /proc/sys/net/ipv4/tcp_synack_retries "2"
    safe_write /proc/sys/net/ipv4/tcp_fin_timeout "15"
    safe_write /proc/sys/net/ipv4/tcp_keepalive_time "300"
    safe_write /proc/sys/net/ipv4/tcp_keepalive_intvl "30"
    safe_write /proc/sys/net/ipv4/tcp_keepalive_probes "5"

    safe_write /proc/sys/net/core/rmem_max "2097152"
    safe_write /proc/sys/net/core/wmem_max "2097152"
    safe_write /proc/sys/net/core/rmem_default "524288"
    safe_write /proc/sys/net/core/wmem_default "524288"
    safe_write /proc/sys/net/core/optmem_max "65536"
    safe_write /proc/sys/net/core/netdev_max_backlog "3000"
    safe_write /proc/sys/net/core/somaxconn "1024"

    if [ -n "$TCP_CC" ] && grep -q "$TCP_CC" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
        save_orig "tcp_cc" "/proc/sys/net/ipv4/tcp_congestion_control"
        safe_write /proc/sys/net/ipv4/tcp_congestion_control "$TCP_CC"
    fi

    safe_write /proc/sys/net/core/default_qdisc "fq_codel"
    for qdisc in /sys/class/net/*/queues/rx-0/rps_cpus; do
        [ -e "$qdisc" ] && safe_write "$qdisc" "f"
    done

    safe_write /proc/sys/net/ipv4/route/gc_timeout "300"
    safe_write /proc/sys/net/ipv4/route/gc_interval "60"

    cmd netpolicy set restrict-background true 2>/dev/null

    for wifi in /sys/module/wlan/parameters/fast_roam \
                /sys/module/wlan/parameters/wifi_latency; do
        safe_write "$wifi" "1"
    done

    log_info "[网络] ===== 优化完成 ====="
}

restore_net() {
    restore_value "tcp_cc" "/proc/sys/net/ipv4/tcp_congestion_control"
    cmd netpolicy set restrict-background false 2>/dev/null
}