#!/system/bin/sh
MODDIR=${0%/*}

echo "================================"
echo "  🎮 游戏性能优化器"
echo "================================"
echo ""

# 守护进程状态
echo "【守护进程】"
if [ -f /data/local/tmp/game_optimizer/daemon.pid ]; then
    PID=$(cat /data/local/tmp/game_optimizer/daemon.pid)
    if kill -0 "$PID" 2>/dev/null; then
        echo "  ✅ 运行中 (PID: $PID)"
    else
        echo "  ❌ 未运行（PID 文件残留）"
    fi
else
    echo "  ❌ 未运行"
fi
echo ""

# 当前游戏状态
echo "【当前状态】"
if [ -f /data/local/tmp/game_optimizer/current_game ]; then
    CUR=$(cat /data/local/tmp/game_optimizer/current_game)
    echo "  🎮 优化中: $CUR"
else
    echo "  💤 空闲（未检测到游戏）"
fi
echo ""

# 白名单总数 + 前 10 条
echo "【游戏白名单】"
if [ -f /data/local/tmp/game_optimizer/game_list.txt ]; then
    TOTAL=$(wc -l < /data/local/tmp/game_optimizer/game_list.txt 2>/dev/null)
    echo "  共 $TOTAL 条，前 10 条:"
    head -n 10 /data/local/tmp/game_optimizer/game_list.txt | sed 's/^/    - /'
    [ "$TOTAL" -gt 10 ] && echo "    ..."
else
    echo "  (白名单文件不存在)"
fi
echo ""

# 最近日志
echo "【最近日志 (最后 15 行)】"
tail -n 15 /data/local/tmp/game_optimizer/game_optimizer.log 2>/dev/null | sed 's/^/  /'
echo ""

# 温度信息
echo "【系统状态】"
TEMP=0
for zone in /sys/class/thermal/thermal_zone*/type; do
    TYPE=$(cat "$zone" 2>/dev/null)
    case "$TYPE" in
        *cpu*|*soc*|*ap*)
            T=$(cat "${zone%type}temp" 2>/dev/null)
            [ -n "$T" ] && TEMP=$((T / 1000)) && break
            ;;
    esac
done
echo "  CPU 温度: ${TEMP}°C"
echo "  温控阈值: 75°C"
echo ""

echo "================================"
echo "可用命令:"
echo "  game_add.sh <包名>   添加游戏"
echo "  game_remove.sh <包名> 移除游戏"
echo "  restore.sh           恢复设置"
echo "================================"