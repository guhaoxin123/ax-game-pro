#!/system/bin/sh
MODDIR="${0%/*}/.."
. "$MODDIR/lib/common.sh"
. "$MODDIR/lib/cpu.sh"
. "$MODDIR/lib/gpu.sh"
. "$MODDIR/lib/mem.sh"
. "$MODDIR/lib/net.sh"
. "$MODDIR/lib/io.sh"
. "$MODDIR/lib/render.sh"
. "$MODDIR/lib/thermal.sh"

log_info "=== 手动切换: 性能模式 ==="
rm -f "$ORIG_STATE"

optimize_cpu
optimize_gpu
optimize_mem
optimize_net
optimize_io
optimize_render
optimize_thermal

notify "🎮 性能模式" "已应用全部性能优化"
echo "✅ 性能模式已激活"