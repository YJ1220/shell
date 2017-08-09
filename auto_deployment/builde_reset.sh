#!/bin/bash
##############################版本回退###########################################
# Note:当前版本回退
# Author：
# DAte:2017年 8月 7日 星期一
# Email:#
#############################function##########################################
#判断上条命令执行结果
function check_work() {
    if [ $? -eq 0 ];then
        echo -e "\e[1;32m"  "$Time $1 "  $(tput sgr0) "Success"  | tee -a  ${Logs_path}/reset.log
    else
        echo -e "\e[1;31m"  "$Time $1 "  $(tput sgr0) "Failed"   | tee -a  ${Logs_path}/reset.log
        echo -e "\e[1;31m"  "$Time 本次版本回退失败"  | tee -a  ${Logs_path}/reset.log
        exit 1
    fi
}
#判断目录是否正确
function dic_path {
    dire=`pwd`
    if [ $dire != $1 ];then
        echo -e "\e[1;31m"  "$Time 切换到目录$1 "  $(tput sgr0) "失败" | tee -a  ${Logs_path}/reset.log
        echo -e "\e[1;31m"  "$Time 本次版本回退失败"  | tee -a  ${Logs_path}/reset.log
        exit 1
    else
        echo -e "\e[1;33m"  "$Time 切换到目录$1 "  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
    fi
}
#停止服务
function stop_server() {
    kill -9 $1
    sleep 5
    Status_num_stop=`ps aux | grep  tomcat_trade  | grep -v grep | wc -l`
    if [ ${Status_num_stop} -ne 0 ];then
        echo -e "\e[1;31m" "$Time 停止服务"   $(tput sgr0) "Failed"  | tee -a  ${Logs_path}/reset.log
        exit 1
    else
        echo -e "\e[1;32m"  "$Time 停止服务"  $(tput sgr0) "Success" | tee -a  ${Logs_path}/reset.log
    fi
}
#启动服务
function start_server() {
    cd ${Server_path}/bin
    echo ""  >  ${Server_path}/logs/catalina.out
    ./startup.sh &> /dev/null
    sleep 5
    Status_num_start=`ps aux | grep  tomcat_trade  | grep -v grep | wc -l`
    if [ ${Status_num_start} -ne 1 ];then
        echo -e "\e[1;31m" "$Time 启动服务"   $(tput sgr0) "Failed"  | tee -a  ${Logs_path}/reset.log
        exit 1
    else
        echo -e "\e[1;32m" "$Time 启动服务"  $(tput sgr0) "Success" | tee -a  ${Logs_path}/reset.log
    fi
}
###############################################################################
#确认是是否执行版本回退
echo -e "\e[1;31m"  "请确认是否回退到上一版本" $(tput sgr0)
read -p "如果确实请输入YES;不执行请输入其他或者直接回车"   input_id
if [ $input_id != "YES" ];then
    echo -e "\e[1;36m" "不执行版本回退"  $(tput sgr0)
    exit 1
else
    echo -e "\e[1;32m" "开始执行版本回退" $(tput sgr0)
fi


Time=`date +'%F %H:%M'`
Build_id=`cat /root/autodeployment/build.txt`
Build_path='/root/autodeployment/build'
Work_path='/root/autodeployment/work'
Logs_path='/root/autodeployment/logs'
Web_Path="/usr/local/tomcat_trade/webapps"
Server_path="/usr/local/tomcat_trade"

if [ -f $Web_Path/USTrade.zip ];then
    rm -rf $Web_Path/USTrade.zip
    check_work "删除生产环境目录下USTrade.zip"
fi

cd $Web_Path
dic_path $Web_Path

#删除本次版本更新新增文件
if `grep -q '^A'  ${Work_path}/${Build_id}/status.log `;then
    awk '{ if ($1 == "A") { print $2 }}'  ${Work_path}/${Build_id}/git_diff.log | grep "^USTrade" | xargs
    rm -rf
    check_work  "删除生产项目内本次build新增文件"
else
    echo -e "\e[1;33m" "本次版本更新未增加新文件；不用删除项目内的文件"    $(tput sgr0) | tee -a  ${Logs_path}/reset.log
fi

#当前版本回退;原备份文件恢复
if [ -f ${Work_path}/${Build_id}/old_web/USTrade.zip  ];then
    mv ${Work_path}/${Build_id}/old_web/USTrade.zip  ${Web_Path}/USTrade.zip
    check_work "移动本次版本更新old_web下的USTrade.zip到webapps下"
    sleep 5
    unzip -o USTrade.zip
    check_work "解压备份USTrade.zip文件到生产目录"
else
    echo  -e "\e[1;31m"  "本次版本更新未修改和删除的文件;当前版本回退到上一版本不需要进行文件备份文件恢复" $(tput sgr0)  | tee -a  ${Logs_path}/reset.log
fi




#当前版本构建工作目录备份
mv  ${Work_path}/${Build_id}   ${Work_path}/${Build_id}_`date +%F`
check_work "当前版本work目录进行备份"

#修改Build_id
Build_num=$(( $Build_id - 1 ))
check_work  "修改版本ID；回退为上一版本ID"

echo    "${Build_num}"   >    /root/autodeployment/build.txt


#Build目录下回退到上一版本
cd $Build_path
dic_path ${Build_path}

echo -e "\e[1;33m" "build目录下版本回退到上一版本"  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
git reset --hard HEAD^
check_work "build目录版本回退"


Status_num=`ps aux | grep  tomcat_trade  | grep -v grep | wc -l`
check_work "获取服务运行状态"
#重启服务
if [ ${Status_num}  -eq 1  ];then
    Status_id=`ps aux | grep  tomcat_trade | grep -v grep | awk '{print $2}' `
    echo -e "\e[1;32m" "$Time 开始停止Trade服务"  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
    stop_server  ${Status_id}
    #启动服务
    echo -e "\e[1;32m" "$Time 开始启动Trade服务"  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
    start_server

elif [ ${Status_num} -eq 0 ];then
    echo -e "\e[1;32m" "$Time 开始启动Trade服务"  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
    start_server
else
    echo -e "\e[1;31m" "$Time Trade服务异常，存在多个进程"  |  tee -a  ${Logs_path}/reset.log
    exit 1
fi



echo -e "\e[1;31m" "本次版本回退"  $(tput sgr0)  "Success"  | tee -a  ${Logs_path}/reset.log
