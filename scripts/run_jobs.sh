#!/system/bin/sh

scripts_dir=${0%/*}
. "$scripts_dir"/utils.sh

# 全局变量定义
ARG_PKG="$1"
NO_START_ON_SCREEN="$2"
KILL_TIME="$3"
DISABLE_APP="$4"

CURRENT_TIME=""
FRONT_APP=""
SCREEN_STATUS=""
WHITE_LIST_APPS=""

# 字符串处理优化函数 - 使用shell内置功能
extract_package_name() {
    local full_name="$1"
    echo "${full_name%%/*}"
}

extract_user_id() {
    local pkg_string="$1"
    if [[ "$pkg_string" == "--user"* ]]; then
        set -- $pkg_string
        echo "$2"
    fi
}

extract_app_name() {
    local pkg_string="$1"
    if [[ "$pkg_string" == "--user"* ]]; then
        set -- $pkg_string
        echo "$3"
    else
        echo "$pkg_string"
    fi
}

# 前台应用检测
get_front_app() {
    dumpsys window 2>/dev/null | grep 'mTopFullscreenOpaqueWindowState' | sed 's/ /\n/g' | tail -n 1 | sed 's/\/.*$//g'
}

# 屏幕状态检测
get_screen_status() {
    dumpsys window policy | awk -F= '/mInputRestricted/ {print $2; exit}'
}

# 白名单加载
load_white_list() {
    if [[ -f "$white_list" ]]; then
        grep -v '^#' "$white_list" 2>/dev/null | cut -f2 -d'=' | tr '\n' ' '
    fi
}

# 勿扰检查函数
is_in_white_list() {
    local app_to_check="$1"
    local current_front_app="$2"
    local white_list_apps="$3"
    
    # 使用shell内置功能进行字符串匹配
    case " $white_list_apps " in
        *" $current_front_app "*) return 0 ;;
        *" $app_to_check "*) return 0 ;;
        *) return 1 ;;
    esac
}

# 初始化全局变量
init_global_vars() {
    # 获取当前时间（格式：HHMM）
    CURRENT_TIME=$(date '+%H%M')
    
    # 一次性获取系统状态信息
    FRONT_APP=$(get_front_app)
    SCREEN_STATUS=$(get_screen_status)
    WHITE_LIST_APPS=$(load_white_list)
    
    echo "$(date '+%F %T') | 前台应用包名为 $FRONT_APP" >> $logfile
}

# 应用启动函数
start_app() {
    local pkg="$1"
    local user_id=""
    local app_name=""
    local is_dual=""
    
    # 解析包名信息
    if [[ "$pkg" == "--user"* ]]; then
        is_dual="多开应用"
        user_id=$(extract_user_id "$pkg")
        app_name=$(extract_app_name "$pkg")
    else
        app_name="$pkg"
    fi
    
    # 提取纯包名
    app_name=$(extract_package_name "$app_name")
    
    if [[ -n "$pkg" ]]; then
        logd "启动$is_dual $user_id $pkg"
        
        # 批量执行命令，减少系统调用
        pm enable "$app_name" && am start $pkg
        
        sleep 0.5
    fi
}

# 检查是否应该跳过执行
should_skip_execution() {
    # 只有在单个应用模式下才检查勿扰名单
    if [[ -n "$ARG_PKG" ]]; then
        # 屏幕状态检查
        if [[ "$SCREEN_STATUS" != "true" ]]; then
            # 屏幕亮着，检查勿扰名单
            if is_in_white_list "$ARG_PKG" "$FRONT_APP" "$WHITE_LIST_APPS"; then
                echo "$(date '+%F %T') | $FRONT_APP 什么也不做" >> $logfile
                return 0  # 应该跳过
            fi
        fi
    fi
    return 1  # 不跳过
}

# 批量执行模式，直接执行当前sh，整体跑一边定时任务
execute_batch_mode() {
    local max_count=999  # 默认最大搜索 999 个任务
    
    # 如果设置了cron_count，则使用它作为限制
    if [[ -n "$cron_count" ]] && [[ "$cron_count" -gt 0 ]]; then
        max_count=$cron_count
    fi
    
    for i in $(seq 1 $max_count); do
        # 检查是否存在rule配置，如果不存在则说明没有更多任务了
        local rule_value=$(eval "echo \$cron_config_rule$i")
        if [[ -z "$rule_value" ]]; then
            # 没有rule配置，结束循环
            break
        fi
        
        local pkg_value=$(eval "echo \$cron_config_pkg$i")
        local shell_value=$(eval "echo \$cron_custom_shell$i")
        
        if [[ -n "$pkg_value" ]]; then
            local no_start=$(eval "echo \$cron_config_screen_on_no_start$i")
            
            # 检查屏幕状态限制
            if [[ "$SCREEN_STATUS" != "true" && "$no_start" == "true" ]]; then
                echo "$(date '+%F %T') | 跳过亮屏启动: $pkg_value" >> $logfile
                continue
            fi
            
            start_app "$pkg_value"
            
            # 启动停止任务
            local kill_time=$(eval "echo \$cron_config_kill_time$i")
            local disable_app=$(eval "echo \$cron_config_disable_app$i")
            [[ -z "$kill_time" ]] && kill_time="$after_x_seconds_to_kill"
            
            # 后台启动停止脚本
            nohup sh "$scripts_dir/stop_app.sh" "$pkg_value" "$kill_time" "$disable_app" >/dev/null 2>&1 &
            
        elif [[ -n "$shell_value" ]]; then
            echo "$(date '+%F %T') | 执行自定义命令: $shell_value" >> $logfile
            eval "$shell_value"
        fi
    done
}

# 单个应用执行模式，如果传入了参数，则只启动指定应用，args: pkg no_start kill_time disable_app
execute_single_mode() {
    # 检查亮屏限制
    if [[ "$SCREEN_STATUS" != "true" && "$NO_START_ON_SCREEN" == "true" ]]; then
        echo "$(date '+%F %T') | 亮屏时不启动: $ARG_PKG" >> $logfile
        return
    fi
    
    start_app "$ARG_PKG"
    
    # 检查时间段保护
    if [[ "$not_kill_time_left" -le "$CURRENT_TIME" && "$CURRENT_TIME" -le "$not_kill_time_right" ]]; then
        echo "$(date '+%F %T') | 在 $not_kill_time_left 到 $not_kill_time_right 之间，不杀进程" >> $logfile
    else
        # 使用传入的kill_time或全局配置
        [[ -z "$KILL_TIME" ]] && KILL_TIME="$after_x_seconds_to_kill"
        
        # 后台启动停止脚本
        nohup sh "$scripts_dir/stop_app.sh" "$ARG_PKG" "$KILL_TIME" "$DISABLE_APP" >/dev/null 2>&1 &
    fi
}

# 主执行逻辑
main_execution() {
    # 加载配置文件
    if [[ -f "$crond_rule_list" ]]; then
        source "$crond_rule_list"
    else
        echo "- [!]: 缺少$crond_rule_list 文件" && exit 2
    fi

    # 开始日志记录
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> $logfile
    
    # 初始化全局变量
    init_global_vars
    
    # 检查是否应该跳过执行
    if should_skip_execution; then
        return
    fi
    
    if [[ -z "$ARG_PKG" ]]; then
        # 批量启动模式 - 启动所有配置的应用
        execute_batch_mode
    else
        # 单个应用模式
        execute_single_mode
    fi
}

# 执行主逻辑
main_execution