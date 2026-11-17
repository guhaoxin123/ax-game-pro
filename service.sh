#!/system/bin/sh
MODDIR=${0%/*}

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 10

chmod 755 "$MODDIR/scripts/"*.sh
chmod 755 "$MODDIR/lib/"*.sh

exec "$MODDIR/scripts/game_optimizer.sh"