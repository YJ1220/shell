#!/bin/baash
############################main###############################################
# Note: 版本回退工作脚本
# Author:YJ
# Date: 2017年 8月14日 星期四 09时48分01秒 CST
# Email:
######################################变量解释###################################
# Project_work:自动部署的项目；一个自动部署项目一个目录
# Project_repo:项目的本地提交目录；本地git commit使用
# Build_id: 存储build次数
# Work_path: 各项目工作目录
# Work_num: 每次部署生成当前对应的具体工作目录
# Work_logs: 每次部署的工作日志
# Work_old: 生产项目删除和修改的备份
# Work_new: 本次build新增和修改的文件

# Des_name:各生产项目名;即存放于webapps下的 (默认与Sou_name一样)
# Ser_name:项目Server工作唯一识别信息（默认即为tomcat;多tomcat服务下，需要使用唯一特定标识）
# Ser_path:Tomcat目录（默认为/usr/local/tomcat）
#########################function##############################################
#判断上条命令执行结果
function check_work() {
    if [ $? -eq 0 ];then
        echo -e "\e[1;36"  "$(date +'%F %H:%M') $1 "  $(tput sgr0) "Success"  | tee -a  ${Logs_path}/reset.log
    else
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') $1 "  $(tput sgr0) "Failed"   | tee -a  ${Logs_path}/reset.log
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') 本次版本回退失败"  | tee -a  ${Logs_path}/reset.log
        exit 1
    fi
}
#判断文件夹是否存在；不存在进行创建；
function mk_dire() {
    if [ ! -d $1 ];then
        mkdir -p $1
        if [ $? -eq 0  ];then
            echo -e "\e[1;36m" "$(date +'%F %H:%M') 创建目录$1 " $(tput sgr0) "Success" | tee -a  ${Logs_path}/reset.log
        else
            echo -e "\e[1;31m" "$(date +'%F %H:%M') 创建目录$1 " $(tput sgr0) "Failed"  | tee -a  ${Logs_path}/reset.log
            echo -e "\e[1;31m" "$(date +'%F %H:%M') 本次部署"   $(tput sgr0) "Failed"   | tee -a  ${Logs_path}/reset.log

            exit
        fi
    fi
}
#判断目录是否正确
function dic_path {
    dire=`pwd`
    if [ $dire != $1 ];then
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') 切换到目录$1 "  $(tput sgr0) "失败" | tee -a  ${Logs_path}/reset.log
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') 本次版本回退失败"  | tee -a  ${Logs_path}/reset.log
        exit 1
    else
        echo -e "\e[1;36m"  "$(date +'%F %H:%M') 切换到目录$1 "  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
    fi
}
#停止服务
function stop_server() {
    kill -9  $1
    sleep 5
    Status_num_stop=`ps aux | grep  ${Ser_name}  | grep -v grep | wc -l`
    if [ ${Status_num_stop} -ne 0 ];then
        echo -e "\e[1;31m" "$(date +'%F %H:%M') 停止${project_name}服务"   $(tput sgr0) "Failed"  | tee -a  ${Logs_path}/reset.log
        exit 1
    else
        echo -e "\e[1;36m" "$(date +'%F %H:%M') 停止${project_name}服务"  $(tput sgr0) "Success"  | tee -a  ${Logs_path}/reset.log
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
        echo -e "\e[1;31m" "$(date +'%F %H:%M') 启动${project_name}服务"   $(tput sgr0) "Failed"  | tee -a  ${Logs_path}/reset.log
        exit 1
    else
        echo -e "\e[1;36m" "$(date +'%F %H:%M') 启动${project_name}服务"  $(tput sgr0) "Success"  | tee -a  ${Logs_path}/reset.log
    fi
}
#####################################获取变量####################################
#设置变量
project_name=$1

#获取变量Sou_name
eval $( grep '^Sou_name' ${Conf_path}/${project_name}.conf)    &>/dev/null

#获取变量Des_name
eval $( grep '^Des_name' ${Conf_path}/${project_name}.conf)    &>/dev/null

#获取变量Ser_name
eval $( grep '^Ser_name' ${Conf_path}/${project_name}.conf)    &>/dev/null

#获取变量Ser_path
eval $( grep '^Ser_path' ${Conf_path}/${project_name}.conf)    &>/dev/null

#空值变量为空的赋予默认值
if [ -z ${Des_name} ];then
    Des_name=${Sou_name}
fi
if [ -z ${Ser_name} ];then
    Ser_name="Tomcat"
fi
if [ -z ${Ser_path} ];then
    Ser_path="/usr/local/tomcat"
fi

build_id=`cat ${Project_path}/${project_name}/build.txt`

echo -e "\e[1;36m" "当前版本为${build_id}"   $(tput sgr0) | tee -a ${Logs_path}/reset.log



if [ ! -f ${Project_path}/${project_name}/${build_id}/logs/gitstatus ];then
    echo  -e "\e[1;31m"  "$(date +'%F %H:%M') gitstatus文件不存在，上次部署本地git commit 失败;"  $(tput sgr0)  | tee -a ${Logs_path}/reset.log
    exit 1
fi




if [ -f ${Ser_path}/webapps/${Des_name}.zip ];then
    rm -rf ${Ser_path}/webapps/${Des_name}.zip
    check_work "删除生产环境目录下${Des_name}.zip"
fi

cd ${Ser_path}/webapps
dic_path ${Ser_path}/webapps

#删除本次版本更新新增文件
if `grep -q '^A'  ${Project_path}/${project_name}/${build_id}/logs/status.log `;then
    awk '{ if ($1 == "A") { print $2 }}'  ${Project_path}/${project_name}/${build_id}/logs/git_diff.log | grep "^${Des_name}" | xargs rm -rf
    check_work  "删除生产项目内本次build新增文件"
else
    echo -e "\e[1;33m" "本次版本更新未增加新文件；不用删除项目内的文件"    $(tput sgr0) | tee -a  ${Logs_path}/reset.log
fi

#当前版本回退;原备份文件恢复
if [ -f ${Project_path}/${project_name}/${build_id}/old_web/${Des_name}.zip  ];then
    cp  ${Project_path}/${project_name}/${build_id}/old_web/${Des_name}.zip  ${Ser_path}/webapps
    check_work "移动本次版本更新old_web下的${Des_name}.zip到webapps下"
    sleep 5
    unzip -o ${Des_name}.zip
    check_work "解压备份${Des_name}.zip文件到生产目录"
else
    echo  -e "\e[1;31m"  "本次版本更新未修改和删除的文件;当前版本回退到上一版本不需要进行文件备份文件恢复" $(tput sgr0)  | tee -a  ${Logs_path}/reset.log
fi




#当前版本构建工作目录备份


mk_dire ${Reset_path}/${project_name}

mv  ${Project_path}/${project_name}/${build_id}   ${Reset_path}/${project_name}/${Build_id}_`date +%F`
check_work "当前版本work目录进行备份"

#修改Build_id
Build_num=$(( $Build_id - 1 ))
check_work  "修改版本ID；回退为上一版本ID"

echo    "${Build_num}"   >   ${Project_path}/${project_name}/build.txt


#Build目录下回退到上一版本
cd ${Local_repo}/${project_name}_repo
dic_path "${Local_repo}/${project_name}_repo"

echo -e "\e[1;33m" "本地repo目录下版本回退到上一版本"  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
git reset --hard HEAD^
check_work "本地repo目录版本回退"

Status_num=`ps aux | grep  ${Ser_name}  | grep -v grep | wc -l`
check_work "获取${project_name}服务运行状态"
echo  -e "\e[1;36m" "项目${project_name}运行的总进程数为 "   $(tput sgr0)  ${Status_num}  | tee -a  ${Logs_path}/reset.log

#重启服务
if [ ${Status_num}  -eq 1  ];then
    Status_id=`ps aux | grep  "${Ser_name}" | grep -v grep | awk '{print $2}' `
    echo -e "\e[1;34m" "$(date +'%F %H:%M') 开始停止${project_name}服务"  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
    stop_server  ${Status_id}
    #启动服务
    echo -e "\e[1;34m" "$(date +'%F %H:%M') 开始启动${project_name}服务"  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
    start_server
elif [ ${Status_num} -eq 0 ];then
    echo -e "\e[1;34m" "$(date +'%F %H:%M') 开始启动${project_name}服务"  $(tput sgr0) | tee -a  ${Logs_path}/reset.log
    start_server
else
    echo -e "\e[1;31m" "$(date +'%F %H:%M') ${project_name}服务异常，存在多个进程"   $(tput sgr0)   | tee -a  ${Logs_path}/reset.log
    exit 1
fi
