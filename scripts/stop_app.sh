#!/system/bin/sh

scripts_dir=${0%/*}
. "$scripts_dir"/utils.sh

arg_pkg=$1
after_x_seconds_to_kill=$2
disable_app=$3

if [[ "$arg_pkg" == "--user"* ]]; then
  isDual="多开应用"
  user_id="${arg_pkg#*--user }"
  user_id="${user_id%% *}"
  app_name="${arg_pkg##* }"
else
  isDual=""
  user_id=""
  app_name="$arg_pkg"
fi

# 除去包名后面的启动类名
app_name="${app_name%%/*}"

# 设置默认杀进程时间
if [[ -z "$after_x_seconds_to_kill" ]]; then
  after_x_seconds_to_kill=0
fi

# 如果 after_x_seconds_to_kill 不为正数，则不杀进程
if [[ $after_x_seconds_to_kill -gt 0 ]]; then
  sleep $after_x_seconds_to_kill
  
  local text="关闭"
  if [[ "$disable_app" == "true" ]]; then
    text="禁用"
    if [[ -z "$isDual" ]]; then
      pm disable-user $app_name
    else
      pm disable-user --user $user_id $app_name
    fi
  fi

  echo "$(date '+%F %T') | $text$isDual $user_id $app_name" >> $logfile
  
  if [[ -z "$isDual" ]]; then
    am force-stop $app_name
  else
    am force-stop --user $user_id $app_name
  fi
else
  echo "$(date '+%F %T') | kill时间不为正数，不关闭$isDual $user_id $app_name" >> $logfile
fi