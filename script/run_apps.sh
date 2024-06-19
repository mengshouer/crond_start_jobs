MODDIR=${0%/*}
start_apps_log=/sdcard/Android/start_apps/log.md
White_List=/sdcard/Android/start_apps/勿扰名单.prop
crond_rule_list=/sdcard/Android/start_apps/cron_set.sh
#创建日志文件
if [ ! -f $start_apps_log ]; then
	mkdir /sdcard/Android/start_apps
	touch $start_apps_log
	echo "#如果有问题，请携带日志反馈" >$start_apps_log
fi
#关闭唤醒锁，尝试解决息屏不处理的问题
echo lock_me > /sys/power/wake_unlock
#开始启动
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> $start_apps_log
#获取前台应用包名
pkg=`dumpsys window | grep mTopFullscreenOpaqueWindowState | sed 's/ /\n/g' | tail -n 1 | sed 's/\/.*$//g'`
echo "$(date '+%F %T') | 前台应用包名为 $pkg" >> $start_apps_log

if [[ -f $crond_rule_list ]]; then
  . "$crond_rule_list"
else
  echo "- [!]: 缺少$crond_rule_list 文件" && exit 2
fi

#获取当前时间，格式是时分，例如当前是上午8：50，hh=850
hh=`date '+%H%M'`

worklist=$(cat "$White_List" | grep -v '^#' | cut -f2 -d '=')
#echo "$(date '+%F %T') | 勿扰应用包名为 $worklist" >> $start_apps_log

#pkgs内的应用在前台时，不会启动支付宝任务(类似于游戏模式)
#pkgs=(
#com.eg.android.AlipayGphone
#com.tencent.tmgp.sgame
#com.tencent.jkchess
#)
#检测屏幕状态
Screen_status="$(dumpsys window policy | grep 'mInputRestricted' | cut -d= -f2)"
if [[ "$Screen_status" != "true" ]]; then
  #判断前台应用是否属于pkgs内的应用
  result=$(echo $worklist | grep "${pkg}")
else
  result=""
fi

arg_pkg=$1
isDual=""
user_id=""
app_name="$arg_pkg"
# 如果是 --user [id] 开头，则是多开应用
if [[ "$arg_pkg" == "--user"* ]]; then
  isDual="多开应用"
  user_id=$(echo $arg_pkg | cut -d ' ' -f 2)
  app_name=$(echo $arg_pkg | cut -d ' ' -f 3)
fi

start_app() {
  # 如果有 arg_pkg 则说明是定时任务启动的，否则是手动启动或者初始化启动的
  pkg=$arg_pkg
  if [[ "$pkg" == "" ]]; then
    pkg=$1
    user_id=$(echo $pkg | cut -d ' ' -f 2)
    app_name=$(echo $pkg | cut -d ' ' -f 3)
  fi
  if [[ ! "$pkg" == "" ]]; then
    echo "$(date '+%F %T') | 启动$isDual $user_id $app_name" >> $start_apps_log
    am start $pkg
    sleep 1
  fi
}

if [[ "$result" == "" ]]; then
  if [[ $arg_pkg == "" ]]; then
    # 如果没有传入参数，则启动所有应用，一般是初始化或者更改配置文件重跑后执行的
    for i in $(seq 1 $cron_count); do
      if [[ -n $(eval "echo \$cron_config_pkg$i") ]]; then
        eval "cron_config_pkg=\$cron_config_pkg$i"
        [[ -n $(eval "echo \$cron_config_screen_on_no_start$i") ]] && no_start="true" || no_start="false"
        # 检查是否配置了亮屏时不启动应用
        if [[ "$Screen_status" != "true" && "$no_start" == "true" ]]; then
          continue
        fi
        start_app "$cron_config_pkg"
        nohup sh $MODDIR/stop_app.sh "$cron_config_pkg" $after_x_seconds_to_kill > /dev/null 2>&1 &
      else
        break
      fi
    done
  else
    # 如果传入了参数，则只启动指定应用
    if [[ "$Screen_status" != "true" && "$2" == "true" ]]; then
      echo "$(date '+%F %T') | 亮屏时不启动 $arg_pkg" >> $start_apps_log
    else
      start_app $arg_pkg
      if [[ "$not_kill_time_left" -le "$hh" && "$hh" -le "$not_kill_time_right" ]]; then
        echo "$(date '+%F %T') | 在 $not_kill_time_left 到 $not_kill_time_right 之间，不杀进程" >> $start_apps_log
      else
        nohup sh $MODDIR/stop_app.sh "$arg_pkg" $after_x_seconds_to_kill > /dev/null 2>&1 &
      fi
    fi
  fi
else
    echo "$(date '+%F %T') | $result 什么也不做" >> $start_apps_log
fi
