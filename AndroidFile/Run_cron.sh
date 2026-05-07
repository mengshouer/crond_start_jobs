#!/system/bin/sh
#此文件每次安装会覆盖，不要在此文件中添加自定义内容

start_jobs_path="/data/adb/start_jobs"
scripts_dir="$start_jobs_path/scripts"
. "$scripts_dir/utils.sh"

[[ -d "$backup_dir" ]] || mkdir -p "$backup_dir"

if [[ -f "$crond_rule_list" ]]; then
  source "$crond_rule_list"
else
  echo "- [!]: 缺少 $crond_rule_list 文件"
  exit 2
fi

if [[ ! -f "$scripts_dir/run_jobs.sh" ]]; then
  echo "- 模块脚本缺失！"
  exit 2
fi

shell_quote() {
  local value="$1"
  printf "'%s'" "$(printf '%s' "$value" | sed "s/'/'\\\\''/g")"
}

busybox crontab -c "$cron_d_path" -r

touch "$cron_d_path/root"
chmod 0755 "$cron_d_path/root"

max_count=999
if is_uint "$cron_count" && [[ "$cron_count" -gt 0 ]]; then
  max_count="$cron_count"
fi

i=1
while [[ "$i" -le "$max_count" ]]; do
  cron_config_rule="$(get_config_value "cron_config_rule" "$i")"
  if [[ -z "$cron_config_rule" ]]; then
    break
  fi

  cron_config_pkg="$(get_config_value "cron_config_pkg" "$i")"
  cron_custom_shell="$(get_config_value "cron_custom_shell" "$i")"

  if [[ -n "$cron_config_pkg" ]]; then
    cron_config_pkg_arg="$(shell_quote "$cron_config_pkg")"
    no_start="false"
    [[ -n "$(get_config_value "cron_config_screen_on_no_start" "$i")" ]] && no_start="true"

    kill_time="$(get_config_value "cron_config_kill_time" "$i")"
    [[ -z "$kill_time" ]] && kill_time="$after_x_seconds_to_kill"

    disable_app="false"
    [[ -n "$(get_config_value "cron_config_disable_app" "$i")" ]] && disable_app="true"

    echo "- 定时设置 | $cron_config_pkg | $cron_config_rule"
    echo "$cron_config_rule $scripts_dir/run_jobs.sh $cron_config_pkg_arg $no_start $kill_time $disable_app" >> "$cron_d_path/root"
  elif [[ -n "$cron_custom_shell" ]]; then
    cron_custom_shell_arg="$(shell_quote "$cron_custom_shell")"
    echo "- 定时设置(自定义指令) | $cron_custom_shell | $cron_config_rule"
    echo "$cron_config_rule $scripts_dir/run_shell.sh $cron_custom_shell_arg" >> "$cron_d_path/root"
  fi

  i=$((i + 1))
done

echo "- | 定时更新成功 |"
logd_clear "重设定时"
basic_Information
