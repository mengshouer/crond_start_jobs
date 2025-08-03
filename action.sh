#!/system/bin/sh
scripts_dir="/data/adb/start_jobs/scripts"
service_file="${scripts_dir}/start_jobs.service"
. "$scripts_dir"/utils.sh

start_jobs_last_pid=$(cat $backup_dir/cron_pid)
[[ -z $start_jobs_last_pid ]] && start_jobs_last_pid=$(pgrep -f "crond -c ${cron_d_path}")

if [[ -n "${start_jobs_last_pid}" ]]; then
  echo "Stopping crond with PID: $start_jobs_last_pid"
  "${service_file}" stop
else
  echo "No crond service is running, starting it now..."
  "${service_file}" start
fi