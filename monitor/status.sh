#!/bin/bash
##############################服务器运行状态信息###################################
# Note:运行状态信息
# Author：
# DAte:2017年 9月 4日 星期一 10时38分32秒 CST
# Email:#
################################################################################
#判断系统版本
function check_sys() {
    sys_no=`cat /etc/redhat-release`
    echo -e "\e[1;31m""当前系统版本为"   $(tput sgr0)   ${sys_no}
}
#服务器CPU运行状态
function cpu_status() {
    cpu_num=`cat /proc/cpuinfo  | grep processor |wc -l`
    avg1=`uptime | awk '{print $(NF -2)}' | cut -c 1`
    avg5=`uptime | awk '{print $(NF -1)}' | cut -c 1`
    avg15=`uptime | awk '{print $NF}' | cut -c 1 `
    echo -e "\e[1;31m""系统CPU核数"   $(tput sgr0)   ${cpu_num}
    echo -e "\e[1;31m""系统1分钟CPU负载"   $(tput sgr0)   ${avg1}
    echo -e "\e[1;31m""系统5分钟CPU负载"   $(tput sgr0)   ${avg5}
    echo -e "\e[1;31m""系统15分钟CPU负载"  $(tput sgr0)   ${avg15}
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
    disk_use=`df -TH | sed -n 2p | awk '{print $(NF-1)}' | awk -F "%" '{print $1}'`
    disk_free=`df -TH | sed -n 2p | awk '{print $5}'`
    echo -e "\e[1;31m""当前系统根目录挂载已使用"   $(tput sgr0) ${disk_use}%
    echo -e "\e[1;31m""当前系统根目录可用空间"   $(tput sgr0) ${disk_free}

}
#服务器进程状态
function process_status() {
    Trade_status=`ps aux | grep  tomcat_trade | grep -v grep | wc -l`
    interface_status=`ps aux | grep  tomcat_interface | grep -v grep | wc -l`
    code_status=`curl -I -m 10 -o /dev/null -s -w %{http_code} http://127.0.0.1:8080/USTrade/web/pages/login.htm`
}
#服务器前CPU消耗前10，内存消耗前10的进程
function process_name() {
    echo "当前服务器CPU消耗前10的进程"  >> ${Log_path}/process_`date +"%F_%H_%M_%S"`.log
    ps aux | head -1 >> ${Log_path}/process_`date +"%F_%H_%M_%S"`.log
    ps aux | grep -v PID | sort -rn -k +3 | head  >> ${Log_path}/process_`date +"%F_%H_%M_%S"`.log
    echo "######################################" >> ${Log_path}/process_`date +"%F_%H_%M_%S"`.log
    echo "当前服务器内存消耗前10的简称"  >> ${Log_path}/process_`date +"%F_%H_%M_%S"`.log
    ps aux | head -1 >> ${Log_path}/process_`date +"%F_%H_%M_%S"`.log
    ps aux | grep -v PID | sort -rn -k +4 | head  >> ${Log_path}/process_`date +"%F_%H_%M_%S"`.log
}
#服务器连接状态
function netstat_status() {
    netstat -tuanlp | awk '/^tcp/ {++state[$(NF-1)]} END {for (key in state) print key,"\t",state[key]}' >> ${Log_path}/netstat_`date +"%F_%H_%M_%S"`.log
}
#定义变量
Log_path="/wocloud/script/log"
Data_path="/wocloud/script/data"

if [ ! -d ${Log_path} ];then
    mkdir -p ${Log_path}
fi

if [ ! -d ${Data_path} ];then
    mkdir -p ${Data_path}
fi

check_sys
cpu_status
mem_status
disk_status
process_status

#判断磁盘空间使用超过80%报警
if [ ${disk_use} -gt 80 ];then
    echo -e "\e[1;31m""磁盘使用空间超过"  $(tput sgr0)  80%
    echo -e "\e[1;31m""当前根目录可用空间为" $(tput sgr0) ${disk_free}
fi
#判断CPU负载1分钟、5分钟、15分钟的负载超过80报警
if [ ${avg1} -ge 4   -o ${avg5} -ge 4 -o  ${avg15} -ge 3 ];then
    process_name
    netstat_status
fi
#Trade和interface项目运行状态
if [ ${Trade_status} -ne 1 ];then
    echo -e "\e[1;31m""项目tomcat_trade出现异常" $(tput sgr0)
fi
if [ ${interface_status} -ne 1 ];then
    echo -e "\e[1;31m""项目tomcat_interface出现异常" $(tput sgr0)
fi
if [ ${code_status} -ne 200 ];then
    echo -e "\e[1;31m""web页面访问出现异常;返回值为" $(tput sgr0) ${code_status}
fi
