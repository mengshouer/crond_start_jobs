#全局变量
MODDIR=${0%/*}
#等待用户登录
Wait_until_login() {
  # in case of /data encryption is disabled
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
  done

  # in case of the user unlocked the screen
  while [ ! -d "/sdcard/Android" ]; do
    sleep 1
  done
}
#保持系统不休眠
(
    until [ $(resetprop sys.boot_completed) -eq 1 ] &&
        [ -d /sdcard ]; do
        sleep 60
    done

    echo "PowerManagerService.noSuspend" > /sys/power/wake_lock
    dumpsys deviceidle disable
    
    exit 0
)

Wait_until_login

#赋权才能正常运行
chmod -R 0777 "$MODDIR"
#注入sh进程
. "$MODDIR"/script/start_jobs_functions.sh
#清空log
logd_clear "开机启动完成: [service.sh]"

sh "$MODDIR"/initial.sh
