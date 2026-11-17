#!/system/bin/sh

log_rotate_loop() {
    while true; do
        rotate_log
        sleep 300
    done
}