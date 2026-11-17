#!/system/bin/sh

optimize_render() {
    log_info "[渲染] ===== 开始深度优化 ====="
    [ "$ENABLE_RENDER" != "1" ] && return

    settings put global window_animation_scale "$ANIM_SCALE"
    settings put global transition_animation_scale "$ANIM_SCALE"
    settings put global animator_duration_scale "$ANIM_SCALE"

    setprop debug.sf.hw 1
    setprop debug.sf.nobootanimation 1
    setprop debug.sf.latch_unsignaled 1
    setprop debug.sf.enable_gl_backpressure 1
    setprop debug.sf.enable_hwc_vds 1
    setprop debug.sf.use_frame_rate_priority 1
    setprop debug.sf.enable_adpf_cpu_hint 1

    setprop debug.hwui.render_dirty_regions false
    setprop debug.hwui.show_dirty_regions false
    setprop debug.hwui.show_overdraw false
    setprop debug.hwui.profile false
    setprop debug.hwui.disable_vsync true
    setprop debug.hwui.use_gpu_pixel_buffers true
    setprop debug.hwui.render_thread true
    setprop debug.hwui.render_ahead true

    setprop debug.egl.hw 1
    setprop debug.egl.profiler 0
    setprop debug.egl.buffcount 4
    setprop debug.gralloc.enable_fb_ubwc 1
    setprop debug.gralloc.gfx_ubwc_disable 0

    setprop debug.vulkan.strict_mode 0
    setprop persist.sys.vulkan.version 1

    setprop debug.composition.type gpu
    setprop debug.sf.gpu_comp_tiling 1

    settings put system peak_refresh_rate 120.0 2>/dev/null
    settings put system min_refresh_rate 120.0 2>/dev/null

    settings put global gpu_debug_layers_enable 0
    settings put global gpu_debug_app ""
    settings put global gpu_debug_layers ""

    log_info "[渲染] ===== 优化完成 ====="
}

restore_render() {
    settings put global window_animation_scale 1.0
    settings put global transition_animation_scale 1.0
    settings put global animator_duration_scale 1.0
    setprop debug.sf.hw 0
    setprop debug.hwui.disable_vsync false
    setprop debug.sf.gpu_comp_tiling 0
}