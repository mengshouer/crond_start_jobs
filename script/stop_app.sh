MODDIR=${0%/*}
start_apps_log=/sdcard/Android/start_apps/log.md

arg_pkg=$1
after_x_seconds_to_kill=$2
# 如果是 --user [id] 开头，则是多开应用
if [[ "$arg_pkg" == "--user"* ]]; then
  isDual="多开应用"
  user_id=$(echo $arg_pkg | cut -d ' ' -f 2)
  app_name=$(echo $arg_pkg | cut -d ' ' -f 3)
else
  isDual=""
  app_name=$1
fi

# 除去包名后面的启动类名
app_name=$(echo $app_name | cut -d '/' -f 1)

if [[ "$after_x_seconds_to_kill" == "" ]]; then
  after_x_seconds_to_kill=0
fi

# 如果 after_x_seconds_to_kill 不为正数，则不杀进程
if [[ $after_x_seconds_to_kill -gt 0 ]]; then
  sleep $after_x_seconds_to_kill
  echo "$(date '+%F %T') | 关闭$isDual $user_id $app_name" >> $start_apps_log
  if [[ "$isDual" == "" ]]; then
    am force-stop $app_name
  else
    am force-stop --user $user_id $app_name
  fi
else
  echo "$(date '+%F %T') | kill时间不为正数，不关闭$isDual $user_id $app_name" >> $start_apps_log
fi