#!/system/bin/sh

start_jobs_path="/data/adb/start_jobs"
backup_dir="$start_jobs_path/backup"
cron_d_path="$backup_dir"
white_list="$start_jobs_path/勿扰名单.prop"
crond_rule_list="$start_jobs_path/cron_set.sh"
logfile="$start_jobs_path/log.md"
module_name="crond_start_jobs"
module_default_path="/data/adb/modules/${module_name}"
module_cache_file="$backup_dir/module_path"

if [[ ! -d "$start_jobs_path" ]]; then
  echo "- 模块目录 $start_jobs_path 不存在！"
  exit 88
fi

if ! command -v busybox >/dev/null 2>&1; then
  export PATH="/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin:$PATH:/system/bin"
fi

if [[ ! -f "$logfile" ]]; then
  echo "| 如果有问题，请携带日志反馈 |" > "$logfile"
fi

_log_timestamp() {
  date '+%g/%m/%d %H:%M'
}

logd() {
  local timestamp=$(_log_timestamp)
  echo "[$timestamp] | $*"
  echo "[$timestamp] | $*" >> "$logfile"
}

logd_clear() {
  local timestamp=$(_log_timestamp)
  echo "[$timestamp] | $*" > "$logfile"
}

logd_at() {
  local timestamp="$1"
  shift
  echo "[$timestamp] | $*"
  echo "[$timestamp] | $*" >> "$logfile"
}

basic_Information() {
  local brand=$(getprop ro.product.brand)
  local model=$(getprop ro.product.model)
  local device=$(getprop ro.product.device)
  local version=$(getprop ro.build.version.release)
  local timestamp=$(_log_timestamp)
  
  logd_at "$timestamp" "品牌: $brand"
  logd_at "$timestamp" "型号: $model"
  logd_at "$timestamp" "代号: $device"
  logd_at "$timestamp" "安卓: $version"
}

resolve_module_path() {
  local module_path=""

  if [[ -n "$START_JOBS_MODULE_PATH" ]] && [[ -d "$START_JOBS_MODULE_PATH" ]]; then
    echo "$START_JOBS_MODULE_PATH"
    return 0
  fi

  if [[ -f "$module_cache_file" ]]; then
    module_path=$(cat "$module_cache_file" 2>/dev/null)
    if [[ -n "$module_path" ]] && [[ -d "$module_path" ]]; then
      echo "$module_path"
      return 0
    fi
  fi

  for module_path in \
    "$module_default_path" \
    "/data/adb/modules_update/${module_name}" \
    "/data/adb/ksu/modules/${module_name}" \
    "/data/adb/ap/modules/${module_name}"; do
    if [[ -d "$module_path" ]]; then
      printf '%s\n' "$module_path" > "$module_cache_file" 2>/dev/null
      echo "$module_path"
      return 0
    fi
  done

  return 1
}

ensure_executable() {
  local target_file="$1"
  [[ -f "$target_file" ]] || return 1
  [[ -x "$target_file" ]] || chmod 0755 "$target_file" 2>/dev/null
}

run_shell_command() {
  local command_text="$1"
  if [[ -z "$command_text" ]]; then
    return 1
  fi

  eval "$command_text"
}

is_uint() {
  case "$1" in
    ''|*[!0-9]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

config_prefix_allowed() {
  case "$1" in
    cron_config_rule|cron_config_pkg|cron_custom_shell|cron_config_screen_on_no_start|cron_config_kill_time|cron_config_disable_app)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_safe_config_var() {
  local var_name="$1"
  printf '%s' "$var_name" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*$'
}

read_config_var() {
  local var_name="$1"
  is_safe_config_var "$var_name" || return 1
  eval "printf '%s' \"\${$var_name-}\""
}

read_indexed_config() {
  local key_prefix="$1"
  local index="$2"

  case "$index" in
    ''|*[!0-9]*)
      return 1
      ;;
  esac

  read_config_var "${key_prefix}${index}"
}

get_config_value() {
  local key_prefix="$1"
  local index="$2"

  config_prefix_allowed "$key_prefix" || return 1
  read_indexed_config "$key_prefix" "$index"
}
