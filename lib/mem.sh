#!/system/bin/sh

optimize_mem() {
    log_info "[内存] ===== 开始深度优化 ====="
    [ "$ENABLE_MEM" != "1" ] && return

    save_orig "swappiness" "/proc/sys/vm/swappiness"
    safe_write /proc/sys/vm/swappiness "10"
    save_orig "vfs_cache_pressure" "/proc/sys/vm/vfs_cache_pressure"
    safe_write /proc/sys/vm/vfs_cache_pressure "200"

    safe_write /proc/sys/vm/dirty_ratio "20"
    safe_write /proc/sys/vm/dirty_background_ratio "5"
    safe_write /proc/sys/vm/dirty_expire_centisecs "100"
    safe_write /proc/sys/vm/dirty_writeback_centisecs "100"

    local mem_total_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    [ -n "$mem_total_kb" ] && safe_write /proc/sys/vm/min_free_kbytes "$((mem_total_kb / 100))"
    safe_write /proc/sys/vm/extra_free_kbytes "102400"

    safe_write /proc/sys/vm/overcommit_memory "0"
    safe_write /proc/sys/vm/page-cluster "0"
    safe_write /proc/sys/vm/watermark_scale_factor "10"

    for thp in /sys/kernel/mm/transparent_hugepage/enabled \
               /sys/kernel/mm/transparent_hugepage/defrag \
               /sys/kernel/mm/transparent_hugepage/shmem_enabled; do
        [ -e "$thp" ] && { save_orig "thp_${thp}" "$thp"; safe_write "$thp" "never"; }
    done

    safe_write /sys/kernel/mm/ksm/run "0"

    for zram in /sys/block/zram*/comp_algorithm; do
        [ -e "$zram" ] && {
            save_orig "zram_${zram}" "$zram"
            safe_write "$zram" "zstd" || safe_write "$zram" "lz4"
        }
    done

    for lmk in /sys/module/lowmemorykiller/parameters/minfree \
               /sys/module/lowmemorykiller/parameters/adj; do
        [ -e "$lmk" ] && save_orig "lmk_${lmk}" "$lmk"
    done
    safe_write /sys/module/lowmemorykiller/parameters/minfree "18432,23040,27648,32256,55296,80640"
    safe_write /sys/module/lowmemorykiller/parameters/adj "0,100,200,300,900,906"

    safe_write /proc/sys/vm/compact_memory "1"
    safe_write /proc/sys/vm/oom_kill_allocating_task "1"
    safe_write /proc/sys/vm/panic_on_oom "0"

    sync 2>/dev/null
    safe_write /proc/sys/vm/drop_caches "1"

    log_info "[内存] ===== 优化完成 ====="
}

restore_mem() {
    restore_value "swappiness" "/proc/sys/vm/swappiness"
    restore_value "vfs_cache_pressure" "/proc/sys/vm/vfs_cache_pressure"
    for thp in /sys/kernel/mm/transparent_hugepage/enabled \
               /sys/kernel/mm/transparent_hugepage/defrag; do
        restore_value "thp_${thp}" "$thp"
    done
    for lmk in /sys/module/lowmemorykiller/parameters/minfree \
               /sys/module/lowmemorykiller/parameters/adj; do
        restore_value "lmk_${lmk}" "$lmk"
    done
    for zram in /sys/block/zram*/comp_algorithm; do
        restore_value "zram_${zram}" "$zram"
    done
}