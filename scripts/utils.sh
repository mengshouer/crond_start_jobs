#!/system/bin/sh

start_jobs_path="/data/adb/start_jobs"
backup_dir="$start_jobs_path/backup"
cron_d_path=$backup_dir
white_list=$start_jobs_path/勿扰名单.prop
crond_rule_list=$start_jobs_path/cron_set.sh

if [[ ! -d "$start_jobs_path" ]]; then
  echo "- 模块目录 $start_jobs_path 不存在！"
  exit 88
fi

if ! command -v busybox &> /dev/null; then
  export PATH="/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin:$PATH:/system/bin"
fi

# 关键文件赋权才能正常运行
chmod -R 0755 "$start_jobs_path"

#配置log文件路径
logfile="$start_jobs_path/log.md"
if [[ ! -f "$logfile" ]]; then
  touch "$logfile"
  echo "| 如果有问题，请携带日志反馈 |" > $logfile
fi

#这个是主log
logd() {
  echo "[$(date '+%g/%m/%d %H:%M')] | $*"
  echo "[$(date '+%g/%m/%d %H:%M')] | $*" >> "$logfile"
}

#这个用来清空log文件
logd_clear() {
  echo "[$(date '+%g/%m/%d %H:%M')] | $*"
  echo "[$(date '+%g/%m/%d %H:%M')] | $*" > "$logfile"
}

#log信息
basic_Information() {
  logd "品牌: $(getprop ro.product.brand)"
  logd "型号: $(getprop ro.product.model)"
  logd "代号: $(getprop ro.product.device)"
  logd "安卓: $(getprop ro.build.version.release)"
}