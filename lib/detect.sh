#!/system/bin/sh

get_foreground_app() {
    local fg=""
    fg=$(dumpsys activity activities 2>/dev/null \
        | grep -E "mResumedActivity|mFocusedApp" | head -1 \
        | grep -oE "[a-zA-Z0-9._]+/[a-zA-Z0-9._]+" | head -1 | cut -d'/' -f1)
    [ -n "$fg" ] && echo "$fg" && return

    fg=$(dumpsys window 2>/dev/null \
        | grep -E "mCurrentFocus" | head -1 \
        | grep -oE "[a-zA-Z0-9._]+/" | head -1 | tr -d '/')
    [ -n "$fg" ] && echo "$fg" && return

    fg=$(dumpsys activity top 2>/dev/null \
        | grep "ACTIVITY" | head -1 | awk '{print $2}' | cut -d'/' -f1)
    echo "$fg"
}

# 精确匹配，不用通配符
is_game() {
    local pkg="$1"
    [ -z "$pkg" ] && return 1
    grep -qxF "$pkg" "$GAME_LIST" 2>/dev/null && return 0
    return 1
}