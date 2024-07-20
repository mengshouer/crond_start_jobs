MyPrint() {
  echo "$@"
  sleep 0.05
}

MyPrint " "
MyPrint "╔════════════════════════════════════"
MyPrint "║   - [&]请先阅读 避免一些不必要的问题"
MyPrint "╠════════════════════════════════════"
MyPrint "║"
MyPrint "║   - 1.模块刷入重启后，只在用户解锁设备才开始生效。"
MyPrint "║   - 2.使用crond定时命令，不会浪费或占用系统资源。"
MyPrint "║   - 3.模块自定义路径: /sdcard/Android/start_jobs/"
MyPrint "║   - 4.配置文件修改: /sdcard/Android/start_jobs/cron_set.sh"
MyPrint "║   - 5.首次安装默认不配置 cron 任务，需要到模块自定义路径运行一遍 Run_cron.sh"
MyPrint "║ "
MyPrint "║   - 源码：https://github.com/mengshouer/crond_start_jobs/"
MyPrint "║ "
MyPrint "╚════════════════════════════════════"
MyPrint " "
#文件夹类型
start_jobs_list_path="/sdcard/Android/start_jobs"
cron_set_dir="${start_jobs_list_path}"
backup_dir="${start_jobs_list_path}/backup"

#文件类型
White_List="${start_jobs_list_path}/勿扰名单.prop"
cron_set_file="${cron_set_dir}/cron_set.sh"
cron_set_example="${backup_dir}/cron_set_example.sh"
Run_cron_sh="${cron_set_dir}/Run_cron.sh"

[[ -d ${cron_set_dir} ]] || mkdir -p ${cron_set_dir}
[[ -d ${backup_dir} ]] || mkdir -p ${backup_dir}
[[ -f ${White_List} ]] || cp -r "${MODPATH}"/AndroidFile/勿扰名单.prop ${start_jobs_list_path}/
[[ -f ${cron_set_file} ]] || cp -r "${MODPATH}"/AndroidFile/cron_set.sh ${cron_set_dir}/
rm -f ${Run_cron_sh} ${cron_set_example}
cp "${MODPATH}"/AndroidFile/Run_cron.sh ${cron_set_dir}/
cp "${MODPATH}"/AndroidFile/cron_set.sh ${cron_set_example}
rm -rf "${MODPATH}"/AndroidFile/

# 删除旧文件，保留几个版本后删除
rm -f "${cron_set_dir}/crontab-bak"
rm -f "${backup_dir}/cron_set_example.sh"