#!/system/bin/sh

optimize_io() {
    log_info "[IO] ===== 开始深度优化 ====="
    [ "$ENABLE_IO" != "1" ] && return

    for sched in /sys/block/*/queue/scheduler; do
        [ -e "$sched" ] || continue
        save_orig "io_${sched}" "$sched"
        case "$(cat "$sched")" in
            *deadline*) safe_write "$sched" "deadline" ;;
            *cfq*)      safe_write "$sched" "cfq" ;;
            *none*)     safe_write "$sched" "none" ;;
        esac
    done

    for nr in /sys/block/*/queue/nr_requests; do
        safe_write "$nr" "256"
    done
    for iod in /sys/block/*/queue/iosched/*; do
        case "$iod" in
            *fifo_batch)     safe_write "$iod" "4" ;;
            *front_merges)   safe_write "$iod" "1" ;;
            *writes_starved) safe_write "$iod" "2" ;;
            *read_expire)    safe_write "$iod" "50" ;;
            *write_expire)   safe_write "$iod" "200" ;;
        esac
    done

    for ra in /sys/block/*/queue/read_ahead_kb; do
        safe_write "$ra" "2048"
    done

    for q in /sys/block/*/queue/nomerges \
             /sys/block/*/queue/rotational \
             /sys/block/*/queue/add_random; do
        case "$q" in
            *nomerges)    safe_write "$q" "0" ;;
            *rotational)  safe_write "$q" "0" ;;
            *add_random)  safe_write "$q" "0" ;;
        esac
    done

    for stat in /sys/block/*/queue/iostats; do
        safe_write "$stat" "0"
    done

    for pm in /sys/block/*/device/power/control; do
        safe_write "$pm" "on"
    done

    for f2 in /sys/fs/f2fs/*/gc_urgent; do
        safe_write "$f2" "1"
    done

    safe_write /proc/sys/vm/drop_caches "1"

    fstrim -v /data 2>/dev/null
    fstrim -v /cache 2>/dev/null

    log_info "[IO] ===== 优化完成 ====="
}

restore_io() {
    for sched in /sys/block/*/queue/scheduler; do
        restore_value "io_${sched}" "$sched"
    done
}