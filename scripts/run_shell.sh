#!/system/bin/sh

scripts_dir=${0%/*}
. "$scripts_dir"/utils.sh

# shell执行函数
if [[ -n "$1" ]]; then
  # 执行命令并记录日志
  eval "$1"
  local exit_code=$?
  
  if [[ $exit_code -eq 0 ]]; then
    echo "$(date '+%F %T') | 执行成功: $1" >> $logfile
  else
    echo "$(date '+%F %T') | 执行失败 (退出码: $exit_code): $1" >> $logfile
  fi
else
  echo "$(date '+%F %T') | 错误: 没有提供要执行的命令" >> $logfile
  exit 1
fi
