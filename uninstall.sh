#!/system/bin/sh

start_jobs_dir="/data/adb/start_jobs"
if [ -d $start_jobs_dir ]; then
  rm -rf $start_jobs_dir
fi