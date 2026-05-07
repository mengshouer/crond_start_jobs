#!/system/bin/sh

scripts_dir=${0%/*}
. "$scripts_dir"/utils.sh

ARG_PKG="$1"
NO_START_ON_SCREEN="$2"
KILL_TIME="$3"
DISABLE_APP="$4"

CURRENT_TIME=""
FRONT_APP=""
SCREEN_STATUS=""
WHITE_LIST_APPS=""
WINDOW_DUMP=""
CURRENT_TIME_READY="false"
FRONT_APP_READY="false"
SCREEN_STATUS_READY="false"
WHITE_LIST_READY="false"
WINDOW_DUMP_READY="false"
PARSED_PKG=""
PARSED_USER_ID=""
PARSED_APP_NAME=""
PARSED_IS_DUAL=""

append_runtime_log() {
  echo "$(date '+%F %T') | $*" >> "$logfile"
}

extract_package_name() {
  local full_name="$1"
  echo "${full_name%%/*}"
}

parse_pkg() {
  PARSED_PKG="$1"
  PARSED_USER_ID=""
  PARSED_APP_NAME="$PARSED_PKG"
  PARSED_IS_DUAL=""

  if [[ "$PARSED_PKG" == "--user"* ]]; then
    PARSED_IS_DUAL="多开应用"
    set -- $PARSED_PKG
    PARSED_USER_ID="$2"
    PARSED_APP_NAME="$3"
  fi

  PARSED_APP_NAME=$(extract_package_name "$PARSED_APP_NAME")
}

read_cron_config() {
  read_indexed_config "$1" "$2"
}

get_front_app() {
  printf '%s\n' "$WINDOW_DUMP" | awk '
    /mTopFullscreenOpaqueWindowState/ { top=$NF }
    END {
      sub(/\/.*/, "", top)
      print top
    }'
}

get_screen_status() {
  local status
  status="$(printf '%s\n' "$WINDOW_DUMP" | awk -F= '
    /mInputRestricted/ {
      gsub(/[[:space:]]/, "", $2)
      print $2
      exit
    }')"

  if [[ -n "$status" ]]; then
    echo "$status"
    return
  fi

  dumpsys window policy 2>/dev/null | awk -F= '
    /mInputRestricted/ {
      gsub(/[[:space:]]/, "", $2)
      print $2
      exit
    }'
}

ensure_current_time() {
  if [[ "$CURRENT_TIME_READY" != "true" ]]; then
    CURRENT_TIME=$(date '+%H%M')
    CURRENT_TIME_READY="true"
  fi
}

ensure_window_dump() {
  if [[ "$WINDOW_DUMP_READY" != "true" ]]; then
    WINDOW_DUMP="$(dumpsys window 2>/dev/null)"
    WINDOW_DUMP_READY="true"
  fi
}

ensure_screen_status() {
  if [[ "$SCREEN_STATUS_READY" != "true" ]]; then
    ensure_window_dump
    SCREEN_STATUS="$(get_screen_status)"
    SCREEN_STATUS_READY="true"
  fi
}

ensure_front_app() {
  if [[ "$FRONT_APP_READY" != "true" ]]; then
    ensure_window_dump
    FRONT_APP="$(get_front_app)"
    FRONT_APP_READY="true"
    append_runtime_log "前台应用包名为 $FRONT_APP"
  fi
}

ensure_white_list() {
  if [[ "$WHITE_LIST_READY" != "true" ]]; then
    WHITE_LIST_APPS="$(load_white_list)"
    WHITE_LIST_READY="true"
  fi
}

load_white_list() {
  if [[ -f "$white_list" ]]; then
    awk -F= '
      /^[[:space:]]*#/ { next }
      {
        value = $0
        if (NF >= 2) {
          value = $2
        }
        sub(/#.*/, "", value)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        if (value != "") {
          printf "%s ", value
        }
      }' "$white_list"
  fi
}

is_front_app_in_white_list() {
  local current_front_app="$1"
  local white_list_apps="$2"

  [[ -n "$current_front_app" ]] || return 1

  case " $white_list_apps " in
    *" $current_front_app "*)
      return 0
      ;;
  esac

  return 1
}

run_custom_shell() {
  local command_text="$1"
  local exit_code=0

  logd "执行自定义命令: $command_text"
  run_shell_command "$command_text"
  exit_code=$?

  if [[ "$exit_code" -eq 0 ]]; then
    logd "自定义命令执行成功"
  else
    logd "自定义命令执行失败，退出码: $exit_code"
  fi
}

start_app() {
  local pkg="$1"

  if [[ -n "$pkg" ]]; then
    parse_pkg "$pkg"
    logd "启动$PARSED_IS_DUAL $PARSED_USER_ID $pkg"
    pm enable "$PARSED_APP_NAME" >/dev/null 2>&1
    am start $pkg >/dev/null 2>&1
    sleep 0.5
  fi
}

log_skip_stop_app() {
  local pkg="$1"
  parse_pkg "$pkg"
  append_runtime_log "kill时间不为正数，不关闭$PARSED_IS_DUAL $PARSED_USER_ID $PARSED_APP_NAME"
}

schedule_stop_app() {
  local pkg="$1"
  local kill_time="$2"
  local disable_app="$3"

  if is_uint "$kill_time" && [[ "$kill_time" -gt 0 ]]; then
    nohup sh "$scripts_dir/stop_app.sh" "$pkg" "$kill_time" "$disable_app" >/dev/null 2>&1 &
  else
    log_skip_stop_app "$pkg"
  fi
}

should_skip_execution() {
  if [[ -n "$ARG_PKG" ]]; then
    ensure_white_list

    [[ -n "$WHITE_LIST_APPS" ]] || return 1

    ensure_screen_status

    if [[ "$SCREEN_STATUS" == "true" ]]; then
      return 1
    fi

    ensure_front_app

    if is_front_app_in_white_list "$FRONT_APP" "$WHITE_LIST_APPS"; then
      append_runtime_log "$FRONT_APP 什么也不做"
      return 0
    fi
  fi

  return 1
}

execute_batch_mode() {
  local max_count=999
  if is_uint "$cron_count" && [[ "$cron_count" -gt 0 ]]; then
    max_count="$cron_count"
  fi

  local i=1
  while [[ "$i" -le "$max_count" ]]; do
    local rule_value
    rule_value="$(read_cron_config "cron_config_rule" "$i")"
    if [[ -z "$rule_value" ]]; then
      break
    fi

    local pkg_value
    local shell_value
    pkg_value="$(read_cron_config "cron_config_pkg" "$i")"
    shell_value="$(read_cron_config "cron_custom_shell" "$i")"

    if [[ -n "$pkg_value" ]]; then
      local no_start
      no_start="$(read_cron_config "cron_config_screen_on_no_start" "$i")"

      if [[ "$no_start" == "true" ]]; then
        ensure_screen_status
      fi

      if [[ "$no_start" == "true" && "$SCREEN_STATUS" != "true" ]]; then
        append_runtime_log "跳过亮屏启动: $pkg_value"
        i=$((i + 1))
        continue
      fi

      start_app "$pkg_value"

      local kill_time
      local disable_app
      kill_time="$(read_cron_config "cron_config_kill_time" "$i")"
      disable_app="$(read_cron_config "cron_config_disable_app" "$i")"
      [[ -z "$kill_time" ]] && kill_time="$after_x_seconds_to_kill"

      schedule_stop_app "$pkg_value" "$kill_time" "$disable_app"
    elif [[ -n "$shell_value" ]]; then
      run_custom_shell "$shell_value"
    fi

    i=$((i + 1))
  done
}

should_skip_kill_by_time() {
  if ! is_uint "$not_kill_time_left"; then
    return 1
  fi

  if ! is_uint "$not_kill_time_right"; then
    return 1
  fi

  ensure_current_time

  if [[ "$not_kill_time_left" -le "$CURRENT_TIME" ]] && [[ "$CURRENT_TIME" -le "$not_kill_time_right" ]]; then
    return 0
  fi

  return 1
}

execute_single_mode() {
  if [[ "$NO_START_ON_SCREEN" == "true" ]]; then
    ensure_screen_status
  fi

  if [[ "$NO_START_ON_SCREEN" == "true" && "$SCREEN_STATUS" != "true" ]]; then
    append_runtime_log "亮屏时不启动: $ARG_PKG"
    return
  fi

  start_app "$ARG_PKG"

  if should_skip_kill_by_time; then
    append_runtime_log "在 $not_kill_time_left 到 $not_kill_time_right 之间，不杀进程"
    return
  fi

  [[ -z "$KILL_TIME" ]] && KILL_TIME="$after_x_seconds_to_kill"
  schedule_stop_app "$ARG_PKG" "$KILL_TIME" "$DISABLE_APP"
}

main_execution() {
  if [[ -f "$crond_rule_list" ]]; then
    source "$crond_rule_list"
  else
    echo "- [!]: 缺少$crond_rule_list 文件"
    exit 2
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$logfile"

  if should_skip_execution; then
    return
  fi

  if [[ -z "$ARG_PKG" ]]; then
    execute_batch_mode
  else
    execute_single_mode
  fi
}

main_execution
