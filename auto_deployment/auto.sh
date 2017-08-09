#!/bin/bash
###############################################################################
# Note:自动部署
# Author:
# Dat:e2017年 8月 7日 星期一
# Email:
# versions： v2.0
#############################说明###############################################
#全局日志存放于Logs_path目录
#每次发布单独日志存放于各自工作目录下
#环境配置需要git maven
#提前git clone 项目到code文件夹
#########################function##############################################
#判断文件夹是否存在；不存在进行创建；
function mk_dire() {
    if [ ! -d $1 ];then
        mkdir -p $1
        if [ $? -ne 0  ];then
            echo -e "\e[1;31m" "$Time 创建目录$1 " $(tput sgr0) "Failed" | tee -a  $Logs_path/local.log
            echo -e "\e[1;31m" "自动部署失败" $(tput sgr0)  | tee -a  $Logs_path/local.log
            exit 1
        else
            echo -e "\e[1;36m" "$Time 创建目录$1 "$(tput sgr0) "Success" | tee -a  $Logs_path/local.log
        fi
    fi
}
function check_script() {
    if [ $? -eq 0 ];then
        echo -e "\e[1;36m"  "$Time $1 "  $(tput sgr0) "Success"  | tee -a  $Logs_path/local.log
    else
        echo -e "\e[1;31m"  "$Time $1 "  $(tput sgr0) "Failed"   | tee -a  $Logs_path/local.log
        echo -e "\e[1;31m"  "$Time 本次部署"  $(tput sgr0) "Failed" | tee -a  $Logs_path/local.log
        exit 1
    fi
}
################################################################################

#脚本全局变量
Code_path='/root/autodeployment/code'
Build_path='/root/autodeployment/build'
Logs_path='/root/autodeployment/logs'
Work_path='/root/autodeployment/work'
Build_id='/root/autodeployment/build.txt'
Web_Path="/usr/local/tomcat_trade/webapps"
Server_path="/usr/local/tomcat_trade"
Reset_path="/root/autodeployment/reset"
Time=`date +'%F %H:%M'`
resettem=$(tput sgr0)
export Code_path Build_path Logs_path Work_path Web_Path Time Build_id resettem Server_path  Reset_path

#变量数组;判断文件夹是否存在
declare  -a   Local_path
Local_path=($Code_path $Build_path $Logs_path $Work_path  $Reset_path )
for i in ${Local_path[@]};do
    mk_dire $i
done


#判断build_id是否存在;同时判断build_id的值是否准确
if [ ! -f $Build_id ]   ;then
    echo -e  "\e[1;36m" "初始化build_id"  ${resettem}
    cd $Work_path
    id_num=`ls | wc -l`
    if [ $id_num -ne 0 ];then
        echo $id_num > $Build_id
    else
        echo 0 > $Build_id
    fi
else
    id_old=`cat $Build_id`
    cd $Work_path
    id_num=`ls | wc -l `
    if [ $id_old -ne $id_num ];then
        echo -e "\e[1;31m" "$Time Build版本id值错误；文件内的值为${id_old};work目录内当前的版本为${id_num}" ${resettem}| tee -a $Logs_path/local.log
        exit 1
    fi
fi

#获取本次build_id
get_id=`cat $Build_id `
Build_num=$(( $get_id + 1 ))
if [ $? -ne 0 ];then
    echo -e "\e[1;31m" "$Time 获取本次build_id失败"  ${resettem} | tee  -a $Logs_path/local.log
    echo -e "\e[1;31m" "$Time 部署停止"  ${resettem}   | tee  -a $Logs_path/local.log
    exit 1
else
    echo -e "\e[1;36m" "$Time 本次build_id为"  ${resettem}  ${Build_num} | tee  -a $Logs_path/local.log
fi

export Build_num
#更新build_id
echo $Build_num >$Build_id


sh  /root/autodeployment/script/work.sh
check_script "脚本work执行"

sh /root/autodeployment/script/restart.sh
check_script "脚本work执行"

echo -e "\e[1;35m"  "$Time 本次部署"  $(tput sgr0) "Success" | tee -a  $Logs_path/local.log
