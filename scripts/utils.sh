#!/system/bin/sh

start_jobs_path="/data/adb/start_jobs"
backup_dir="$start_jobs_path/backup"
cron_d_path=$backup_dir
white_list=$start_jobs_path/勿扰名单.prop
crond_rule_list=$start_jobs_path/cron_set.sh
logfile="$start_jobs_path/log.md"

if [[ ! -d "$start_jobs_path" ]]; then
  echo "- 模块目录 $start_jobs_path 不存在！"
  exit 88
fi

if ! command -v busybox &> /dev/null; then
  export PATH="/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin:$PATH:/system/bin"
fi

# 关键文件赋权才能正常运行
chmod -R 0755 "$start_jobs_path"

if [[ ! -f "$logfile" ]]; then
  echo "| 如果有问题，请携带日志反馈 |" > "$logfile"
fi

_log_timestamp() {
  date '+%g/%m/%d %H:%M'
}

logd() {
  local timestamp=$(_log_timestamp)
  echo "[$timestamp] | $*"
  echo "[$timestamp] | $*" >> "$logfile"
}

logd_clear() {
  local timestamp=$(_log_timestamp)
  echo "[$timestamp] | $*" > "$logfile"
}

basic_Information() {
  local brand=$(getprop ro.product.brand)
  local model=$(getprop ro.product.model)
  local device=$(getprop ro.product.device)
  local version=$(getprop ro.build.version.release)
  
  logd "品牌: $brand"
  logd "型号: $model"
  logd "代号: $device"
  logd "安卓: $version"
}