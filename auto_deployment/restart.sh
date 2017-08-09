#!/bin/bash
###############################################################################
# Note:重启服务
# Author：
# DAte:2017年 8月 7日 星期一
# Email:#
##############################function#########################################
#判断上条命令执行结果
function check_work() {
    if [ $? -eq 0 ];then
        echo -e "\e[1;32m"  "$Time $1 "  $(tput sgr0) "Success"  | tee -a  ${Work_path}/$Build_num/logs/script.log
    else
        echo -e "\e[1;31m"  "$Time $1 "  $(tput sgr0) "Failed"   | tee -a  ${Work_path}/$Build_num/logs/script.log
        exit 1
    fi
}
#判断目录是否正确
function dic_path {
    dire=`pwd`
    if [ $dire != $1 ];then
        echo -e "\e[1;31m"  "$Time 切换到目录$1 "  $(tput sgr0) "失败" | tee -a  ${Work_path}/$Build_num/logs/script.log
        exit 1
    else
        echo -e "\e[1;33m"  "$Time 切换到目录$1 "  $(tput sgr0) | tee -a  ${Work_path}/$Build_num/logs/script.log
    fi
}
#停止服务
function stop_server() {
    kill -9 $1
    sleep 5
    Status_num_stop=`ps aux | grep  tomcat_trade  | grep -v grep | wc -l`
    if [ ${Status_num_stop} -ne 0 ];then
        echo -e "\e[1;31m" "$Time 停止服务"   $(tput sgr0) "Failed"  | tee -a  ${Work_path}/$Build_num/logs/script.log
        exit 1
    else
        echo -e "\e[1;32m"  "$Time 停止服务"  $(tput sgr0) "Success" | tee -a  ${Work_path}/$Build_num/logs/script.log
    fi
}
#启动服务
function start_server() {
    cd ${Server_path}/bin
    ./startup.sh
    sleep 5
    Status_num_start=`ps aux | grep  tomcat_trade  | grep -v grep | wc -l`
    if [ ${Status_num_start} -ne 1 ];then
        echo -e "\e[1;31m" "$Time 启动服务"   $(tput sgr0) "Failed"  | tee -a  ${Work_path}/$Build_num/logs/script.log
        exit 1
    else
        echo -e "\e[1;32m"  "$Time 启动服务"  $(tput sgr0) "Success" | tee -a  ${Work_path}/$Build_num/logs/script.log
    fi
}
###############################################################################

Status_num=`ps aux | grep  tomcat_trade  | grep -v grep | wc -l`
check_work "获取服务运行状态"
echo  -e "\e[1;36m" "Trade运行的总进程数为 "   $(tput sgr0)  ${Status_num}  | tee -a  ${Work_path}/$Build_num/logs/script.log


#重启服务
if [ ${Status_num}  -eq 1  ];then
    Status_id=`ps aux | grep  tomcat_trade | grep -v grep | awk '{print $2}' `
    echo -e "\e[1;32m" "$Time 开始停止Trade服务"  $(tput sgr0) | tee -a  ${Work_path}/$Build_num/logs/script.log
    stop_server  ${Status_id}
    #启动服务
    echo -e "\e[1;32m" "$Time 开始启动Trade服务"  $(tput sgr0) | tee -a  ${Work_path}/$Build_num/logs/script.log
    start_server

elif [ ${Status_num} -eq 0 ];then
    echo -e "\e[1;32m" "$Time 开始启动Trade服务"  $(tput sgr0) | tee -a  ${Work_path}/$Build_num/logs/script.log
    start_server
else
    echo -e "\e[1;31m" "$Time Trade服务异常，存在多个进程"  |  tee -a  ${Work_path}/$Build_num/logs/script.log
    exit 1
fi
