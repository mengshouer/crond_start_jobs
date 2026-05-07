#!/system/bin/sh

scripts_dir=${0%/*}
. "$scripts_dir"/utils.sh

command_text="$1"
if [[ -n "$command_text" ]]; then
  run_shell_command "$command_text"
  exit_code=$?

  if [[ "$exit_code" -eq 0 ]]; then
    echo "$(date '+%F %T') | 执行成功: $command_text" >> "$logfile"
  else
    echo "$(date '+%F %T') | 执行失败 (退出码: $exit_code): $command_text" >> "$logfile"
  fi
else
  echo "$(date '+%F %T') | 错误: 没有提供要执行的命令" >> "$logfile"
  exit 1
fi
