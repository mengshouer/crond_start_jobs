#!/system/bin/sh
scripts_dir="/data/adb/start_jobs/scripts"
. "$scripts_dir"/utils.sh

module_name="crond_start_jobs"
module_path=$(find /data/adb -type d -name "$module_name" | head -n 1)

start_service() {
  if [[ ! -f "${module_path}/disable" ]]; then
    "${scripts_dir}/start_jobs.service" start >> "/dev/null" 2>&1
  else
    rm -f $backup_dir/cron_pid
  fi
}

start_inotifyd() {
  # 查找并停止现有的inotifyd进程
  local pids=$(busybox pidof inotifyd 2>/dev/null)
  if [[ -n "$pids" ]]; then
    for pid in $pids; do
      if [[ -f "/proc/$pid/cmdline" ]] && grep -q "start_jobs.inotify" "/proc/$pid/cmdline" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null
      fi
    done
  fi
  
  # 启动新的inotifyd进程
  inotifyd "${scripts_dir}/start_jobs.inotify" "${module_path}" > "/dev/null" 2>&1 &
}

# 检查并启动inotifyd功能
if [[ ! -f "${backup_dir}/onlycrond" ]]; then
  logd "| inotifyd 已开启 |：当前可以使用 su 管理器(magisk/ksu/ap)内管理模块开关，不需要重启手机"
  logd "此功能是用 inotifyd 监控模块目录实现的，不经常开关模块的可以关掉"
  logd "如需关闭此功能，在 ${backup_dir} 中新建一个 onlycrond 文件，重启生效"
  logd "如果是有操作按钮的新版 su 管理器，可以关闭此项，使用操作按钮控制"
  start_inotifyd
fi

# 检查并设置唤醒锁
if [[ ! -f "${backup_dir}/nowakelock" ]]; then
  echo "PowerManagerService.noSuspend" >> /sys/power/wake_lock
  logd "|已开启设备唤醒锁，会增加耗电，关闭可能导致任务在设备休眠后无法准时执行"
  logd "如需关闭此功能，在 ${backup_dir} 中新建一个 nowakelock 文件，重启生效"
fi

start_service