#此文件每次安装会覆盖，不要在此文件中添加自定义内容
#全局变量
module="/data/adb/modules/crond_start_jobs"
moduleksu="/data/adb/ksu/modules/crond_start_jobs/"
if [[ -d "$module" ]]; then
  mod_path=$module
else
  mod_path=$moduleksu
fi

set_path=${0%/*}
set_file=$set_path/cron_set.sh
cron_d_path=$mod_path/script/set_cron.d
#不存在则创建目录
[[ ! -d $cron_d_path ]] && mkdir -p $cron_d_path

. $mod_path/script/start_jobs_functions.sh

if [[ -f $set_file ]]; then
  . "$set_file"
else
  echo "- [!]: 缺少$set_file 文件" && exit 2
fi

start_jobs_crond_pid_1="$(ps -ef | grep -v 'grep' | grep 'crond' | grep 'crond_start_jobs' | awk '{print $2}')"
if [[ -n $start_jobs_crond_pid_1 ]]; then
  for i in $start_jobs_crond_pid_1; do
    echo "- 杀死上次定时 | pid: $i"
    kill -9 $i
  done
fi

#定义变量
if [[ -f "/data/adb/ksud" ]]; then
  S=$(/data/adb/ksud -V | awk '/ksud/{gsub("ksud ", ""); print substr($0,1,4)}')
  if [[ "$S" = "v0.3" ]]; then
    alias crond="/data/adb/busybox/crond"
  else
    alias crond="/data/adb/busybox/crond"
  fi
else
  alias crond="\$( magisk --path )/.magisk/busybox/crond"
fi

#开启定时
echo "" > $cron_d_path/root
for i in $(seq 1 $cron_count); do
  if [[ -n $(eval "echo \$cron_config_pkg$i") ]]; then
    eval "cron_config_pkg=\$cron_config_pkg$i"
    eval "cron_config_rule=\$cron_config_rule$i"
    [[ -n $(eval "echo \$cron_config_screen_on_no_start$i") ]] && no_start="true" || no_start="false"
    [[ -n $(eval "echo \$cron_config_kill_time$i") ]] && kill_time=$(eval "echo \$cron_config_kill_time$i") || kill_time=$after_x_seconds_to_kill
    [[ -n $(eval "echo \$cron_config_disable_app$i") ]] && disable_app="true" || disable_app="false"
    echo "- 定时设置 | $cron_config_pkg | $cron_config_rule"
    echo "$cron_config_rule $mod_path/script/run_jobs.sh '$cron_config_pkg' $no_start $kill_time $disable_app" >> $cron_d_path/root
  else
    break
  fi
done
cp -f $cron_d_path/root $set_path/crontab-bak
crond -c "$cron_d_path"
start_jobs_crond_pid_2="$(ps -ef | grep -v 'grep' | grep 'crond' | grep 'crond_start_jobs' | awk '{print $2}')"
echo "- 定时启动成功 | pid: $start_jobs_crond_pid_2"
log_md_set_cron_clear
# if [[ -f $mod_path/script/run_jobs.sh ]]; then
#   for i in $(seq 1 $cron_count); do
#     if [[ -n $(eval "echo \$cron_config_pkg$i") ]]; then
#       eval "cron_config_pkg=\$cron_config_pkg$i"
#       sh $mod_path/script/run_jobs.sh "$cron_config_pkg"
#     else
#       break
#     fi
#   done
# else
#   echo "- 模块脚本缺失！"
# fi
if [[ ! -f $mod_path/script/run_jobs.sh ]]; then
  echo "- 模块脚本缺失！"
fi
