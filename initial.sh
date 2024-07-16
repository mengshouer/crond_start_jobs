#全局变量
MODDIR=${0%/*}
start_jobs_list_path="/sdcard/Android/start_jobs"
#注入sh进程
. "$MODDIR"/script/start_jobs_functions.sh

#定义变量
if [[ -f "/data/adb/ksud" ]]; then
  alias crond="/data/adb/busybox/crond"
else
  alias crond="\$( magisk --path )/.magisk/busybox/crond"
fi

logd "初始化完成: [initial.sh]"

if [[ -f "$MODDIR/script/set_cron.d/root" ]]; then
  crond -c "$MODDIR"/script/set_cron.d
  crond_root_file=$MODDIR/script/set_cron.d/root
elif [[ -f "$start_jobs_list_path/crontab-bak" ]]; then
  mkdir -p $MODDIR/script/set_cron.d
  cp -f $start_jobs_list_path/crontab-bak $MODDIR/script/set_cron.d/root
  crond -c $MODDIR/script/set_cron.d
  crond_root_file=$MODDIR/script/set_cron.d/root
fi

sleep 1

if [[ $(pgrep -f "crond_start_jobs/script/set_cron.d" | grep -vc grep) -ge 1 ]]; then
  basic_Information
  logd "开始运行: [$crond_root_file]"
  logd "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  basic_Information
  logd "未检测到 cron 任务，需要修改配置文件后，手动运行一遍 /sdcard/Android/start_jobs/Run_cron.sh"
  exit 1
fi

