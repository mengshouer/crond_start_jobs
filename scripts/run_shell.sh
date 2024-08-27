#!/system/bin/sh

scripts_dir=${0%/*}
. "$scripts_dir"/utils.sh

# 运行 eval $1
eval "$1"
echo "$(date '+%F %T') | 执行 $1" >> $logfile
