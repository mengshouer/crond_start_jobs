MODDIR=${0%/*}
start_jobs_log=/sdcard/Android/start_jobs/log.md
#创建日志文件
if [ ! -f $start_jobs_log ]; then
	mkdir /sdcard/Android/start_jobs
	touch $start_jobs_log
	echo "#如果有问题，请携带日志反馈" >$start_jobs_log
fi
#关闭唤醒锁，尝试解决息屏不处理的问题
echo lock_me > /sys/power/wake_unlock

# 运行 eval $1
eval "$1"
echo "$(date '+%F %T') | 执行 $1" >> $start_jobs_log
