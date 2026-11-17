#!/system/bin/sh
MODDIR=${0%/*}

"$MODDIR/scripts/game_optimizer.sh" restore 2>/dev/null
rm -rf /data/local/tmp/game_optimizer