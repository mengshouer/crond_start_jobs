#!/system/bin/sh
scripts_dir="/data/adb/start_jobs/scripts"
. "$scripts_dir"/utils.sh

module_path="$(resolve_module_path 2>/dev/null)"
if [[ -z "$module_path" ]]; then
  module_path="$module_default_path"
fi

start_service() {
  if [[ ! -f "${module_path}/disable" ]]; then
    ensure_executable "${scripts_dir}/start_jobs.service"
    "${scripts_dir}/start_jobs.service" start >> "/dev/null" 2>&1
  else
    rm -f "$backup_dir/cron_pid"
  fi
}

find_inotifyd_pids() {
  local pids
  pids="$(busybox pidof inotifyd 2>/dev/null)"
  local pid=""
  local matched_pids=""

  [[ -n "$pids" ]] || return 0

  for pid in $pids; do
    if [[ -f "/proc/$pid/cmdline" ]] && grep -q "start_jobs.inotify" "/proc/$pid/cmdline" 2>/dev/null; then
      if [[ -n "$matched_pids" ]]; then
        matched_pids="${matched_pids} ${pid}"
      else
        matched_pids="$pid"
      fi
    fi
  done

  echo "$matched_pids"
}

should_keep_inotifyd() {
  local pids="$1"
  local pid=""
  local matched_count=0

  [[ -n "$pids" ]] || return 1

  for pid in $pids; do
    matched_count=$((matched_count + 1))
    if grep -q "$module_path" "/proc/$pid/cmdline" 2>/dev/null; then
      continue
    fi

    return 1
  done

  [[ "$matched_count" -eq 1 ]]
}

stop_inotifyd() {
  local pids="$1"
  local pid=""

  [[ -n "$pids" ]] || return 0

  for pid in $pids; do
    kill -15 "$pid" 2>/dev/null
  done

  sleep 1

  for pid in $pids; do
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null
    fi
  done
}

start_inotifyd() {
  local pids=""

  if [[ ! -d "$module_path" ]]; then
    logd "未找到模块目录，跳过 inotifyd 监听: $module_path"
    return
  fi

  pids="$(find_inotifyd_pids)"
  if should_keep_inotifyd "$pids"; then
    return
  fi

  stop_inotifyd "$pids"
  inotifyd "${scripts_dir}/start_jobs.inotify" "${module_path}" > "/dev/null" 2>&1 &
}

# 检查并启动inotifyd功能
if [[ ! -f "${backup_dir}/onlycrond" ]]; then
  start_inotifyd
fi

start_service
