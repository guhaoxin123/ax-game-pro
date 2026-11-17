#!/system/bin/sh
MODDIR="${0%/*}/.."
. "$MODDIR/lib/common.sh"
. "$MODDIR/lib/cpu.sh"
. "$MODDIR/lib/gpu.sh"
. "$MODDIR/lib/mem.sh"
. "$MODDIR/lib/net.sh"
. "$MODDIR/lib/io.sh"
. "$MODDIR/lib/render.sh"

log_info "=== 手动切换: 均衡模式 ==="

restore_cpu
restore_gpu
restore_mem
restore_net
restore_io
restore_render

rm -f "$ORIG_STATE"
notify "⚖️ 均衡模式" "已恢复系统默认设置"
echo "✅ 均衡模式已激活"