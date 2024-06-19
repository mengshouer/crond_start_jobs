#-------------------------------------------------
# 设置完成后 以root方式执行: Run_cron.sh
# 不要试图更改Run_cron.sh脚本内容，若更改后执行出问题概不负责！
#-------------------------------------------------

# 应用启动后过多久后杀进程，单位秒
# after_x_seconds_to_kill=300 表示5分钟后杀进程
after_x_seconds_to_kill=300

# 配置一个时间段内启动应用时不杀进程 [not_kill_time_left, not_kill_time_right]
# 例如：not_kill_time_left=650, not_kill_time_right=730 表示在6:50到7:30之间不杀进程
not_kill_time_left=650
not_kill_time_right=730


# 定时任务数量，根据下面实际填写，可以多过实际数量，但是过多会导致运行时间变长
cron_count=2

# 所有的 cron_config_配置项 一一对应，不要多也不要少
# cron_config_pkg 为包名/启动类名，前面添加 --user 999 则启动双开应用，有些多开软件 user 不是 999，需要自己查看
# 本质上就是执行 am start [cron_config_pkg] 命令，可以在这里添加自己的应用
# cron_config_XXXX0 0结尾的为示例配置，修改了也不生效的。
cron_config_pkg0="xxxx"
# cron_config_rule 为 cron 的规则，例子： 0 */1 * * *  为每小时执行一次
cron_config_rule0="0 */1 * * *"
# 如果需要亮屏时不启动应用，可以在对应的配置后面添加 cron_config_screen_on_no_startX=true
cron_config_screen_on_no_start0=true


# 下面两个是支付宝的例子，可以根据自己的需求添加或删除
cron_config_pkg1="com.eg.android.AlipayGphone/com.alipay.mobile.framework.service.common.SchemeStartActivity"
cron_config_rule1="0 */1 * * *"

cron_config_pkg2="--user 999 com.eg.android.AlipayGphone/com.alipay.mobile.framework.service.common.SchemeStartActivity"
cron_config_rule2="0 */1 * * *"
