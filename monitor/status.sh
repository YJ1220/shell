#!/bin/bash
##############################服务器运行状态信息###################################
# Note:运行状态信息
# Author：
# DAte:2017年 9月 4日 星期一 10时38分32秒 CST
# Email:#
##############################说明###############################################
# 主控脚本
# 全局变量
# 创建工作环境
# 脚本返回信息处理
#############################获取全局变量#########################################
#判断系统
function check_sys() {
    sys_no=`cat /etc/redhat-release`
    echo -e "\e[1;31m""当前系统版本为"   $(tput sgr0)   ${sys_no}

}

#服务器CPU运行状态
function cpu_status() {
    cpu_num=`cat /proc/cpuinfo  | grep processor |wc -l`

    echo -e "\e[1;31m""系统CPU核数"   $(tput sgr0)   ${cpu_num}


}
#服务器内存状态
function mem_status() {
    mem_free=`free -m | sed -n '2p' | awk '{print $4}'`
    mem_ava=`free -m | sed -n '3p' | awk '{print $NF}'`
    echo -e "\e[1;31m""当前系统空闲内存(M)"   $(tput sgr0) ${mem_free}
    echo -e "\e[1;31m""当前系统可用内存(M)"   $(tput sgr0) ${mem_ava}
}
#服务器磁盘状态
function  disk_status() {
    disk_use=`df -TH | sed -n 2p | awk '{print $(NF-1)}'`
    disk_free=`df -TH | sed -n 2p | awk '{print $5}'`
    echo -e "\e[1;31m""当前系统根目录挂载已使用"   $(tput sgr0) ${disk_use}
    echo -e "\e[1;31m""当前系统根目录可用空间"   $(tput sgr0) ${disk_free}

}
#服务器进程状态
function process_status() {
    echo ok
}
#服务器连接状态
function netstat_status() {
    netstat -tuanlp | awk '/^tcp/ {++state[$(NF-1)]} END {for (key in state) print key,"\t",state[key]}'
}
check_sys
mem_status
disk_status
