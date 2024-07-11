# crond_start_jobs

`模块刷入重启后查看`

```
管理器
  └── /sdcard
     └── /Android
        └── /start_jobs  <--- 模块生成的目录
           │
           ├── cron_set.sh     <--- 在里面自定义参数
           ├── Run_cron.sh     <--- cron_set.sh 文件定义好之后以 root 执行
           ├── log.md          <--- 日志文件: 每次重启设备或运行 Run_cron.sh 重新记录
           └── 勿扰名单.prop    <--- 勿扰名单里的应用在前台时，不会启动应用(勿扰，类似游戏模式)
```

- Magisk 20.4+
- 支持 Magisk Lite
- 支持任何安卓设备

## 参数设置

[cron_set.sh](https://github.com/mengshouer/crond_start_jobs/blob/main/AndroidFile/cron_set.sh)

## 为什么会有这个模块

> 装了某些脚本插件之后，需要应用启动的时候才会运行，但是又不想让应用一直留在后台耗电，则定时打开应用，然后 sleep 指定时间后关闭/禁用应用，这样就可以达到节省电量的目的。

> 或者定时执行自定义 shell 指令。

## 鸣谢

本模块基本就是改自 https://github.com/Petit-Abba/black_and_white_list/

以及感谢其他二改作者的作者。@瘦鹏鹏 @焕晨 @懒猫
