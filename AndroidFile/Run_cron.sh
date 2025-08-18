#!/system/bin/sh
#此文件每次安装会覆盖，不要在此文件中添加自定义内容
module_name="crond_start_jobs"
module_path=$(find /data/adb -type d -name "$module_name" | head -n 1)

start_jobs_path="/data/adb/start_jobs"
scripts_dir=$start_jobs_path/scripts
. $scripts_dir/utils.sh

#不存在则创建目录
[[ -d $backup_dir ]] || mkdir -p $backup_dir


if [[ -f $crond_rule_list ]]; then
  source "$crond_rule_list"
else
  echo "- [!]: 缺少 $crond_rule_list 文件" && exit 2
fi

if [[ ! -f $scripts_dir/run_jobs.sh ]]; then
  echo "- 模块脚本缺失！" && exit 2
fi

# # delete the previous crontab and create a new crontab
busybox crontab -c "${cron_d_path}" -r

#开启定时
touch $cron_d_path/root
chmod 755 $cron_d_path/root

# 确定任务数量
max_count=999  # 默认最大搜索 999 个任务

# 如果设置了cron_count，则使用它作为限制
if [[ -n "$cron_count" ]] && [[ "$cron_count" -gt 0 ]]; then
  max_count=$cron_count
fi

for i in $(seq 1 $max_count); do
  # 检查是否存在rule配置，如果不存在则说明没有更多任务了
  eval "cron_config_rule=\$cron_config_rule$i"
  if [[ -z "$cron_config_rule" ]]; then
    # 没有rule配置，结束循环
    break
  fi
  
  if [[ -n $(eval "echo \$cron_config_pkg$i") ]]; then
    eval "cron_config_pkg=\$cron_config_pkg$i"
    [[ -n $(eval "echo \$cron_config_screen_on_no_start$i") ]] && no_start="true" || no_start="false"
    [[ -n $(eval "echo \$cron_config_kill_time$i") ]] && kill_time=$(eval "echo \$cron_config_kill_time$i") || kill_time=$after_x_seconds_to_kill
    [[ -n $(eval "echo \$cron_config_disable_app$i") ]] && disable_app="true" || disable_app="false"
    echo "- 定时设置 | $cron_config_pkg | $cron_config_rule"
    echo "$cron_config_rule $scripts_dir/run_jobs.sh '$cron_config_pkg' $no_start $kill_time $disable_app" >> $cron_d_path/root
  elif [[ -n $(eval "echo \$cron_custom_shell$i") ]]; then
    eval "cron_custom_shell=\$cron_custom_shell$i"
    echo "- 定时设置(自定义指令) | $cron_custom_shell | $cron_config_rule"
    echo "$cron_config_rule $scripts_dir/run_shell.sh '$cron_custom_shell'" >> $cron_d_path/root
  fi
done

echo "- | 定时更新成功 |"
logd_clear "重设定时"
basic_Information