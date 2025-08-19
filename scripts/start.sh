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
  start_inotifyd
fi

start_service