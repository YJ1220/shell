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
        echo -e "\e[1;34m"  "$(date +'%F %H:%M') $1 "  $(tput sgr0) "Success"  | tee -a  ${Logs_path}/local.log
    else
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') $1 "  $(tput sgr0) "Failed"   | tee -a  ${Logs_path}/local.log
        exit 1
    fi
}
#判断目录是否正确
function dic_path() {
    dire=`pwd`
    if [ $dire != $1 ];then
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') 切换到目录$1 "  $(tput sgr0) "失败" | tee -a  ${Logs_path}/local.log
        exit 1
    else
        echo -e "\e[1;34m"  "$(date +'%F %H:%M') 切换到目录$1 "  $(tput sgr0) | tee -a  ${Logs_path}/local.log
    fi
}
#停止服务
function stop_server() {
    kill -9  $1
    sleep 5
    Status_num_stop=`ps aux | grep  ${Ser_name}  | grep -v grep | wc -l`
    if [ ${Status_num_stop} -ne 0 ];then
        echo -e "\e[1;31m" "$(date +'%F %H:%M') 停止${project_name}服务"   $(tput sgr0) "Failed"  | tee -a  ${Logs_path}/local.log
        exit 1
    else
        echo -e "\e[1;34m" "$(date +'%F %H:%M') 停止${project_name}服务"  $(tput sgr0) "Success"  | tee -a  ${Logs_path}/local.log
    fi
}
#启动服务
function start_server() {
    cd ${Ser_path}/bin
    echo ""  > ${Ser_path}/logs/catalina.out
    ./startup.sh &> /dev/null
    sleep 5
    Status_num_start=`ps aux | grep  ${Ser_name}  | grep -v grep | wc -l`
    if [ ${Status_num_start} -ne 1 ];then
        echo -e "\e[1;31m" "$(date +'%F %H:%M') 启动${project_name}服务"   $(tput sgr0) "Failed"  | tee -a  ${Logs_path}/local.log
        exit 1
    else
        echo -e "\e[1;34m" "$(date +'%F %H:%M') 启动${project_name}服务"  $(tput sgr0) "Success"  | tee -a  ${Logs_path}/local.log
    fi
}
######################################变量解释########################################
# Project_work:自动部署的项目；一个自动部署项目一个目录
# Project_repo:项目的本地提交目录；本地git commit使用
# Build_id: 存储build次数
# Work_path: 各项目工作目录
# Work_num: 每次部署生成当前对应的具体工作目录
# Work_logs: 每次部署的工作日志
# Work_old: 生产项目删除和修改的备份
# Work_new: 本次build新增和修改的文件


# Ser_name:项目Server工作唯一识别信息（默认即为tomcat;多tomcat服务下，需要使用唯一特定标识）
# Ser_path:Tomcat目录（默认为/usr/local/tomcat）
#####################################获取变量########################################

project_name=$1

#获取变量Ser_name
eval $( grep '^Ser_name' ${Conf_path}/${project_name}.conf)    &>/dev/null
#获取变量Ser_path
eval $( grep '^Ser_path' ${Conf_path}/${project_name}.conf)    &>/dev/null
if [ -z ${Ser_name} ];then
    Ser_name="Tomcat"
fi
if [ -z ${Ser_path} ];then
    Ser_path="/usr/local/tomcat"
fi

#Build_num=`cat  ${Project_path}/${project_name}/build.txt  `


###################################################################################
Status_num=`ps aux | grep  "${Ser_name}"  | grep -v grep | wc -l`
check_work "获取${project_name}服务运行状态"
echo  -e "\e[1;34m" "项目${project_name}运行的总进程数为 "   $(tput sgr0)  ${Status_num}  | tee -a  ${Logs_path}/local.log


#重启服务
if [ ${Status_num}  -eq 1  ];then
    Status_id=`ps aux | grep  "${Ser_name}" | grep -v grep | awk '{print $2}' `
    echo -e "\e[1;34m" "$(date +'%F %H:%M') 开始停止${project_name}服务"  $(tput sgr0) | tee -a  ${Logs_path}/local.log
    stop_server  ${Status_id}
    #启动服务
    echo -e "\e[1;34m" "$(date +'%F %H:%M') 开始启动${project_name}服务"  $(tput sgr0) | tee -a  ${Logs_path}/local.log
    start_server
elif [ ${Status_num} -eq 0 ];then
    echo -e "\e[1;34m" "$(date +'%F %H:%M') 开始启动${project_name}服务"  $(tput sgr0) | tee -a  ${Logs_path}/local.log
    start_server
else
    echo -e "\e[1;31m" "$(date +'%F %H:%M') ${project_name}服务异常，存在多个进程"   $(tput sgr0)   | tee -a  ${Logs_path}/local.log
    exit 1
fi
