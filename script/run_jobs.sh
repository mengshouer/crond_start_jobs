MODDIR=${0%/*}
start_jobs_log=/sdcard/Android/start_jobs/log.md
White_List=/sdcard/Android/start_jobs/勿扰名单.prop
crond_rule_list=/sdcard/Android/start_jobs/cron_set.sh
#创建日志文件
if [ ! -f $start_jobs_log ]; then
	mkdir /sdcard/Android/start_jobs
	touch $start_jobs_log
	echo "#如果有问题，请携带日志反馈" >$start_jobs_log
fi
#关闭唤醒锁，尝试解决息屏不处理的问题
echo lock_me > /sys/power/wake_unlock
#开始启动
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> $start_jobs_log

if [[ -f $crond_rule_list ]]; then
  . "$crond_rule_list"
else
  echo "- [!]: 缺少$crond_rule_list 文件" && exit 2
fi

#获取当前时间，格式是时分，例如当前是上午8：50，hh=850
hh=`date '+%H%M'`

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
    # 除去包名后面的启动类名
    app_name=$(echo $app_name | cut -d '/' -f 1)
    echo "$(date '+%F %T') | 启动$isDual $user_id $pkg" >> $start_jobs_log
    pm enable $app_name
    am start $pkg
    sleep 1
  fi
}

#获取前台应用包名
front_pkg=`dumpsys window | grep mTopFullscreenOpaqueWindowState | sed 's/ /\n/g' | tail -n 1 | sed 's/\/.*$//g'`
echo "$(date '+%F %T') | 前台应用包名为 $front_pkg" >> $start_jobs_log

worklist=$(cat "$White_List" | grep -v '^#' | cut -f2 -d '=')
#echo "$(date '+%F %T') | 勿扰应用包名为 $worklist" >> $start_jobs_log

#pkgs内的应用在前台时，不会启动支付宝任务(类似于游戏模式)
#pkgs=(
#com.eg.android.AlipayGphone
#com.tencent.tmgp.sgame
#com.tencent.jkchess
#)
#检测屏幕状态
Screen_status="$(dumpsys window policy | grep 'mInputRestricted' | cut -d= -f2)"
if [[ "$Screen_status" != "true" ]]; then
  #判断前台应用是否属于 勿扰应用包 内的应用，或者为 arg_pkg 指定的应用
  result=$(echo $worklist | grep "${front_pkg}") || result=$(echo $arg_pkg | grep "${front_pkg}")
else
  result=""
fi

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
        # 如果有单独设置杀进程时间，则使用单独设置的时间，否则使用全局配置
        if [[ -n $(eval "echo \$cron_config_kill_time$i") ]]; then
          after_x_seconds_to_kill=$(eval "echo \$cron_config_kill_time$i")
        else
          after_x_seconds_to_kill=$after_x_seconds_to_kill
        fi
        disable_app=$(eval "echo \$cron_config_disable_app$i")
        nohup sh $MODDIR/stop_app.sh "$cron_config_pkg" $after_x_seconds_to_kill $disable_app > /dev/null 2>&1 &
      elif [[ -n $(eval "echo \$cron_custom_shell$i") ]]; then
        eval "$cron_custom_shell$i"
      else
        break
      fi
    done
  else
    # 如果传入了参数，则只启动指定应用，args: pkg no_start kill_time disable_app
    if [[ "$Screen_status" != "true" && "$2" == "true" ]]; then
      echo "$(date '+%F %T') | 亮屏时不启动 $arg_pkg" >> $start_jobs_log
    else
      start_app $arg_pkg
      if [[ "$not_kill_time_left" -le "$hh" && "$hh" -le "$not_kill_time_right" ]]; then
        echo "$(date '+%F %T') | 在 $not_kill_time_left 到 $not_kill_time_right 之间，不杀进程" >> $start_jobs_log
      else
        # 如果有单独设置杀进程时间，则使用单独设置的时间，否则使用全局配置
        if [[ -n "$3" ]]; then
          after_x_seconds_to_kill=$3
        fi
        # disable_app=$4
        nohup sh $MODDIR/stop_app.sh "$arg_pkg" $after_x_seconds_to_kill $4 > /dev/null 2>&1 &
      fi
    fi
  fi
else
    echo "$(date '+%F %T') | $result 什么也不做" >> $start_jobs_log
fi
