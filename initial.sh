MODDIR=${0%/*}
backup_dir="/sdcard/Android/start_jobs/backup"
#注入sh进程
. "$MODDIR"/script/start_jobs_functions.sh

logd "初始化完成: [initial.sh]"

if [[ -f "$MODDIR/script/set_cron.d/root" ]]; then
  busybox crond -c "$MODDIR"/script/set_cron.d
elif [[ -f "$backup_dir/crontab-bak" ]]; then
  mkdir -p $MODDIR/script/set_cron.d
  cp -f $backup_dir/crontab-bak $MODDIR/script/set_cron.d/root
  busybox crond -c $MODDIR/script/set_cron.d
fi

sleep 2

cron_pid=$(pgrep -f "crond_start_jobs/script/set_cron.d")

if [[ -n $cron_pid ]]; then
  crond_root_file=$MODDIR/script/set_cron.d/root
  echo $cron_pid > $backup_dir/cron_pid
  basic_Information
  logd "开始运行: [$crond_root_file]"
  logd "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  basic_Information
  logd "未检测到 cron 任务，需要修改配置文件后，手动运行一遍 /sdcard/Android/start_jobs/Run_cron.sh"
  exit 1
fi