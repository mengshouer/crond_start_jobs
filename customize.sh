#!/system/bin/sh

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
MyPrint "║   - 2.使用 crond 定时管理，可以用 su 管理器开关模块，无需重启。"
MyPrint "║   - 3.模块自定义路径: /data/adb/start_jobs/"
MyPrint "║   - 4.配置文件修改: /data/adb/start_jobs/cron_set.sh"
MyPrint "║   - 5.首次安装默认不配置 cron 任务，需要到模块自定义路径运行一遍 Run_cron.sh"
MyPrint "║ "
MyPrint "║   - 源码：https://github.com/mengshouer/crond_start_jobs/"
MyPrint "║ "
MyPrint "╚════════════════════════════════════"
MyPrint " "

#文件夹类型
start_jobs_path="/data/adb/start_jobs"
scripts_dir="${start_jobs_path}/scripts"
backup_dir="${start_jobs_path}/backup"


service_dir="/data/adb/service.d"
if [ "$KSU" = "true" ]; then
  ui_print "- kernelSU version: $KSU_VER ($KSU_VER_CODE)"
  [ "$KSU_VER_CODE" -lt 10683 ] && service_dir="/data/adb/ksu/service.d"
elif [ "$APATCH" = "true" ]; then
  APATCH_VER=$(cat "/data/adb/ap/version")
  ui_print "- APatch version: $APATCH_VER"
else
  ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

mkdir -p "${service_dir}"

#文件类型
white_list="${start_jobs_path}/勿扰名单.prop"
cron_set_file="${start_jobs_path}/cron_set.sh"
cron_set_example="${backup_dir}/cron_set_example.sh"
Run_cron_sh="${start_jobs_path}/Run_cron.sh"

ui_print "- Create directories"
[[ -d ${start_jobs_path} ]] || mkdir -p ${start_jobs_path}
[[ -d ${backup_dir} ]] || mkdir -p ${backup_dir}
[[ -f ${white_list} ]] || cp -r "${MODPATH}"/AndroidFile/勿扰名单.prop ${start_jobs_path}/
[[ -f ${cron_set_file} ]] || cp -r "${MODPATH}"/AndroidFile/cron_set.sh ${start_jobs_path}/
rm -f ${Run_cron_sh} ${cron_set_example}
cp "${MODPATH}"/AndroidFile/Run_cron.sh ${start_jobs_path}/
cp "${MODPATH}"/AndroidFile/cron_set.sh ${cron_set_example}
rm -rf "${MODPATH}"/AndroidFile/

rm -rf $scripts_dir && mkdir -p $scripts_dir
mv "${MODPATH}"/scripts/* "${scripts_dir}"/

ui_print "- Setting permissions"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $start_jobs_path/  0 3005 0755 0700
set_perm $MODPATH/uninstall.sh  0  0  0755
set_perm $scripts_dir/  0  0  0755

chmod ugo+x $MODPATH/*
chmod ugo+x $start_jobs_path/*

ui_print "- Installation is complete, reboot your device"

