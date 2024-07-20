#!/system/bin/sh
#此文件每次安装会覆盖，不要在此文件中添加自定义内容
module_name="crond_start_jobs"
module_path=$(find /data/adb -type d -name "$module_name" -print -quit)

set_path=${0%/*}
backup_dir=$set_path/backup
set_file=$set_path/cron_set.sh
cron_d_path=$module_path/script/set_cron.d
#不存在则创建目录
[[ -d $cron_d_path ]] || mkdir -p $cron_d_path
[[ -d $backup_dir ]] || mkdir -p $backup_dir

. $module_path/script/start_jobs_functions.sh

if [[ -f $set_file ]]; then
  . "$set_file"
else
  echo "- [!]: 缺少$set_file 文件" && exit 2
fi

# 杀死上次定时
start_jobs_crond_pid_1=$(cat $backup_dir/cron_pid)
for i in $start_jobs_crond_pid_1; do
  echo "- 杀死上次定时 | pid: $i"
  kill -9 $i
done

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
    echo "$cron_config_rule $module_path/script/run_jobs.sh '$cron_config_pkg' $no_start $kill_time $disable_app" >> $cron_d_path/root
  elif [[ -n $(eval "echo \$cron_custom_shell$i") ]]; then
    eval "cron_custom_shell=\$cron_custom_shell$i"
    eval "cron_config_rule=\$cron_config_rule$i"
    echo "- 定时设置(自定义指令) | $cron_custom_shell | $cron_config_rule"
    echo "$cron_config_rule $module_path/script/run_shell.sh '$cron_custom_shell'" >> $cron_d_path/root
  else
    break
  fi
done

cp -f $cron_d_path/root $backup_dir/crontab-bak
busybox crond -c "$cron_d_path"
start_jobs_crond_pid_2="$(ps -ef | grep -v 'grep' | grep 'crond' | grep 'crond_start_jobs' | awk '{print $2}')"
echo "- 定时启动成功 | pid: $start_jobs_crond_pid_2"
echo $start_jobs_crond_pid_2 > $backup_dir/cron_pid
log_md_set_cron_clear
# if [[ -f $module_path/script/run_jobs.sh ]]; then
#   for i in $(seq 1 $cron_count); do
#     if [[ -n $(eval "echo \$cron_config_pkg$i") ]]; then
#       eval "cron_config_pkg=\$cron_config_pkg$i"
#       sh $module_path/script/run_jobs.sh "$cron_config_pkg"
#     else
#       break
#     fi
#   done
# else
#   echo "- 模块脚本缺失！"
# fi
if [[ ! -f $module_path/script/run_jobs.sh ]]; then
  echo "- 模块脚本缺失！"
fi
