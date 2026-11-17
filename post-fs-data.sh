#!/system/bin/sh
MODDIR=${0%/*}

mkdir -p /data/local/tmp/game_optimizer
touch /data/local/tmp/game_optimizer/game_optimizer.log
chmod 666 /data/local/tmp/game_optimizer/game_optimizer.log

[ ! -f /data/local/tmp/game_optimizer/game_list.txt ] && \
    cp "$MODDIR/game_list.txt" /data/local/tmp/game_optimizer/game_list.txt
[ ! -f /data/local/tmp/game_optimizer/blacklist.txt ] && \
    cp "$MODDIR/blacklist.txt" /data/local/tmp/game_optimizer/blacklist.txt