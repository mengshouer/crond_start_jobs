start_jobs_list_path="/sdcard/Android/start_jobs"
#检测关键文件，赋权才能正常运行
chmod -R 0777 "$start_jobs_list_path"
if [[ ! -d "$start_jobs_list_path" ]]; then
  echo "- 模块Android目录不存在！"
  exit 88
fi

#配置log文件路径
logfile="$start_jobs_list_path/log.md"
if [[ ! -f "$logfile" ]]; then
  touch "$logfile"
fi

if ! command -v busybox &> /dev/null; then
  export PATH="/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin:$PATH:/system/bin"
fi


#这个是主log
logd() {
  echo "[$(date '+%g/%m/%d %H:%M')] | $*" >> "$logfile"
}

#这个用来清空log文件
logd_clear() {
  echo "[$(date '+%g/%m/%d %H:%M')] | $*" > "$logfile"
}

#重新定时时调用
log_md_set_cron_clear() {
  logd_clear "重设定时"
  basic_Information
  logd "开始运行: [$cron_d_path/root]"
  logd "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  logd "┃杀死上次定时 | pid: $start_jobs_crond_pid_1"
  logd "┃定时启动成功 | pid: $start_jobs_crond_pid_2"
  logd "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

#log信息
basic_Information() {
  logd "品牌: $(getprop ro.product.brand)"
  logd "型号: $(getprop ro.product.model)"
  logd "代号: $(getprop ro.product.device)"
  logd "安卓: $(getprop ro.build.version.release)"
}