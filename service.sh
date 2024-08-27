#!/system/bin/sh

(
    until [ $(getprop init.svc.bootanim) = "stopped" ]; do
        sleep 30
    done

    # in case of /data encryption is disabled
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
      sleep 10
    done

    # in case of the user unlocked the screen
    while [ ! -d "/sdcard/Android" ]; do
      sleep 10
    done

    if [ -f "/data/adb/start_jobs/scripts/start.sh" ]; then
        chmod 755 /data/adb/start_jobs/scripts/*
        /data/adb/start_jobs/scripts/start.sh
    else
        echo "File '/data/adb/start_jobs/scripts/start.sh' not found"
    fi
)&