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
MyPrint "║   - 3.模块自定义路径: /sdcard/Android/start_apps/"
MyPrint "║   - 4.配置文件修改: /sdcard/Android/start_apps/cron_set.sh"
MyPrint "║   - 5.首次安装默认不配置 cron 任务，需要到模块自定义路径运行一遍 Run_cron.sh"
MyPrint "║ "
MyPrint "║   - 源码：https://github.com/mengshouer/crond_start_apps/"
MyPrint "║ "
MyPrint "╚════════════════════════════════════"
MyPrint " "
#文件夹类型
start_apps_list_path="/sdcard/Android/start_apps"
start_apps_list_path_old="/sdcard/Android/start_apps_old"
cron_set_dir="${start_apps_list_path}"

#文件类型
White_List="${start_apps_list_path}/勿扰名单.prop"
cron_set_file="${cron_set_dir}/cron_set.sh"
cron_set_example="${cron_set_dir}/cron_set_example.sh"
Run_cron_sh="${cron_set_dir}/Run_cron.sh"

magisk_util_functions="/data/adb/magisk/util_functions.sh"
grep -q 'lite_modules' "${magisk_util_functions}" && modules_path="lite_modules" || modules_path="modules"
mod_path="/data/adb/${modules_path}/crond_start_apps"
script_dir="${mod_path}/script"

# 判断是否安装过
if [[ -d ${script_dir}/tmp/DATE ]] && [[ -d ${start_apps_list_path} ]]; then
  mkdir -p "$start_apps_list_path_old"
  cp -rf "$start_apps_list_path" "$start_apps_list_path_old"
  rm -rf "$start_apps_list_path"
  MyPrint "检测到安装过模块，旧配置文件已经自动备份。"
fi

#获取ksu的busybox地址
busybox="/data/adb/ksu/bin/busybox"
#释放地址
filepath="/data/adb/busybox"
#如果没有此文件夹则创建
#检查Busybox并释放
if [[ -f $busybox ]]; then
  if [[ ! -f $filepath ]]; then
    mkdir -p "$filepath"
  fi
  #存在Busybox开始释放
  "$busybox" --install -s "$filepath"
  MyPrint "已安装busybox。"
fi

[[ -d ${cron_set_dir} ]] || mkdir -p ${cron_set_dir}
[[ -f ${White_List} ]] || cp -r "${MODPATH}"/AndroidFile/勿扰名单.prop ${start_apps_list_path}/
[[ -f ${cron_set_file} ]] || cp -r "${MODPATH}"/AndroidFile/cron_set.sh ${cron_set_dir}/
rm -f ${Run_cron_sh} ${cron_set_example}
cp "${MODPATH}"/AndroidFile/Run_cron.sh ${cron_set_dir}/
cp "${MODPATH}"/AndroidFile/cron_set.sh ${cron_set_example}
rm -rf "${MODPATH}"/AndroidFile/
