#!/system/bin/sh
scripts_dir="/data/adb/start_jobs/scripts"
. "$scripts_dir"/utils.sh

module_name="crond_start_jobs"
module_path=$(find /data/adb -type d -name "$module_name" | head -n 1)

start_service() {
  if [ ! -f "${module_path}/disable" ]; then
    "${scripts_dir}/start_jobs.service" start >> "/dev/null" 2>&1
  else
    rm -f $backup_dir/cron_pid
  fi
}

start_inotifyd() {
  PIDs=($(busybox pidof inotifyd))
  for PID in "${PIDs[@]}"; do
    if grep -q -e "start_jobs.inotify" "/proc/$PID/cmdline"; then
      kill -9 "$PID"
    fi
  done
  inotifyd "${scripts_dir}/start_jobs.inotify" "${module_path}" > "/dev/null" 2>&1 &
}

if [ ! -f "${backup_dir}/onlycrond" ]; then
  logd "| inotifyd 已开启 |：当前可以使用 su 管理器(magisk/ksu/ap)内管理模块开关，不需要重启手机"
  logd "此功能是用 inotifyd 监控模块目录实现的，不经常开关模块的可以关掉"
  logd "如需关闭此功能，在 ${backup_dir} 中新建一个 onlycrond 文件，重启生效"
  logd "如果是有操作按钮的新版 su 管理器，可以关闭此项，使用操作按钮控制"
  start_inotifyd
fi

if [ ! -f "${backup_dir}/nowakelock" ]; then
  echo "PowerManagerService.noSuspend" >> /sys/power/wake_lock
  logd "|已开启设备唤醒锁，会增加耗电，关闭可能导致任务在设备休眠后无法准时执行"
  logd "如需关闭此功能，在 ${backup_dir} 中新建一个 nowakelock 文件，重启生效"
fi

start_service