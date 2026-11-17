#!/system/bin/sh
# ============================================
# 公共函数库
# ============================================

MODDIR="${MODDIR:-/data/adb/modules/game_optimizer}"
CONFIG="$MODDIR/config.conf"
STATE_DIR="/data/local/tmp/game_optimizer"
ORIG_STATE="$STATE_DIR/orig_state"
LOG_FILE="$STATE_DIR/game_optimizer.log"
GAME_LIST="$STATE_DIR/game_list.txt"
BLACKLIST="$STATE_DIR/blacklist.txt"
PID_FILE="$STATE_DIR/daemon.pid"
STATE_FLAG="$STATE_DIR/current_game"

mkdir -p "$STATE_DIR"
[ -f "$CONFIG" ] && . "$CONFIG"

# ---------- 配置默认值兜底（防止 config.conf 加载失败） ----------
CHECK_INTERVAL="${CHECK_INTERVAL:-5}"
ENABLE_CPU="${ENABLE_CPU:-1}"
ENABLE_GPU="${ENABLE_GPU:-1}"
ENABLE_MEM="${ENABLE_MEM:-1}"
ENABLE_NET="${ENABLE_NET:-1}"
ENABLE_IO="${ENABLE_IO:-1}"
ENABLE_RENDER="${ENABLE_RENDER:-1}"
ENABLE_THERMAL="${ENABLE_THERMAL:-1}"
ENABLE_PROCESS_KILL="${ENABLE_PROCESS_KILL:-1}"
ENABLE_LOG_REDUCE="${ENABLE_LOG_REDUCE:-1}"
THERMAL_LIMIT="${THERMAL_LIMIT:-75}"
ENABLE_NOTIFY="${ENABLE_NOTIFY:-1}"
LOG_LEVEL="${LOG_LEVEL:-info}"
LOG_MAX_LINES="${LOG_MAX_LINES:-2000}"
KILL_LEVEL="${KILL_LEVEL:-light}"
TCP_CC="${TCP_CC:-bbr}"
ANIM_SCALE="${ANIM_SCALE:-0.5}"
TARGET_REFRESH_RATE="${TARGET_REFRESH_RATE:-120}"

# ADB 层开关默认值
ENABLE_ADB_GAME_MODE="${ENABLE_ADB_GAME_MODE:-1}"
ENABLE_ADB_FIXED_PERF="${ENABLE_ADB_FIXED_PERF:-1}"
ENABLE_ADB_UCLAMP="${ENABLE_ADB_UCLAMP:-1}"
ENABLE_ADB_CGROUP="${ENABLE_ADB_CGROUP:-1}"
ENABLE_ADB_FREEZER="${ENABLE_ADB_FREEZER:-1}"
ENABLE_ADB_REFRESH="${ENABLE_ADB_REFRESH:-1}"
ENABLE_ADB_NET_POLICY="${ENABLE_ADB_NET_POLICY:-1}"

# 校验 THERMAL_LIMIT 合法性
case "$THERMAL_LIMIT" in
    ''|*[!0-9]*) THERMAL_LIMIT=75 ;;
esac
[ "$THERMAL_LIMIT" -lt 40 ] && THERMAL_LIMIT=75
[ "$THERMAL_LIMIT" -gt 120 ] && THERMAL_LIMIT=75

# ---------- 日志 ----------
log() {
    local level="$1"; shift
    local ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts][$level] $*" >> "$LOG_FILE"
}

log_debug() { [ "$LOG_LEVEL" = "debug" ] && log DEBUG "$@"; }
log_info()  { log INFO "$@"; }
log_warn()  { log WARN "$@"; }
log_error() { log ERROR "$@"; }

rotate_log() {
    [ ! -f "$LOG_FILE" ] && return
    local lines=$(wc -l < "$LOG_FILE" 2>/dev/null)
    [ -z "$lines" ] && return
    if [ "$lines" -gt "$LOG_MAX_LINES" ]; then
        tail -n $((LOG_MAX_LINES / 2)) "$LOG_FILE" > "$LOG_FILE.tmp"
        mv "$LOG_FILE.tmp" "$LOG_FILE"
        log_info "日志已轮转"
    fi
}

# ---------- 安全写入 ----------
safe_write() {
    local path="$1" value="$2"
    if [ -e "$path" ] && [ -w "$path" ]; then
        echo "$value" > "$path" 2>/dev/null && return 0
    fi
    return 1
}

save_orig() {
    local key="$1" path="$2"
    if [ -e "$path" ] && [ -r "$path" ]; then
        local val=$(cat "$path" 2>/dev/null)
        echo "$key=$val" >> "$ORIG_STATE"
    fi
}

restore_value() {
    local key="$1" path="$2"
    [ -f "$ORIG_STATE" ] || return
    local val=$(grep "^${key}=" "$ORIG_STATE" 2>/dev/null | tail -1 | cut -d'=' -f2-)
    [ -n "$val" ] && safe_write "$path" "$val"
}

# ---------- 通知 ----------
notify() {
    [ "$ENABLE_NOTIFY" != "1" ] && return
    cmd notification post -S bigtext -t "$1" "$2" 2>/dev/null
}

# ---------- 温度读取 ----------
read_cpu_temp() {
    for zone in /sys/class/thermal/thermal_zone*/type; do
        local type=$(cat "$zone" 2>/dev/null)
        case "$type" in
            *cpu*|*soc*|*ap*)
                local temp=$(cat "${zone%type}temp" 2>/dev/null)
                [ -n "$temp" ] && echo $((temp / 1000)) && return
                ;;
        esac
    done
    echo 0
}

# ---------- 当前游戏状态 ----------
set_current_game() {
    if [ -n "$1" ]; then
        echo "$1" > "$STATE_FLAG"
    else
        rm -f "$STATE_FLAG"
    fi
}

get_current_game() {
    [ -f "$STATE_FLAG" ] && cat "$STATE_FLAG" 2>/dev/null
}