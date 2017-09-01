#!/bin/baash
############################main###############################################
# Note: 主控脚本
# Author:YJ
# Date: 2017年 8月10日 星期四 09时48分01秒 CST
# Email:
############################说明###############################################
# 主控脚本
# 全局变量
# 创建工作环境
# 脚本返回信息处理
# 本次部署
#########################function##############################################
#判断文件夹是否存在；不存在进行创建；
function mk_dire() {
    if [ ! -d $1 ];then
        mkdir -p $1
        if [ $? -eq 0  ];then
            echo -e "\e[1;36m" "$(date +'%F %H:%M') 创建目录$1 " $(tput sgr0) "Success" | tee -a  ${Logs_path}/local.log
        else
            echo -e "\e[1;31m" "$(date +'%F %H:%M') 创建目录$1 " $(tput sgr0) "Failed"  | tee -a  ${Logs_path}/local.log
            echo -e "\e[1;31m" "$(date +'%F %H:%M') 本次部署"   $(tput sgr0) "Failed"   | tee -a  ${Logs_path}/local.log

            exit
        fi
    fi
}
#判断脚本执行状态
function check_script() {
    if [ $? -eq 0 ];then
        echo -e "\e[1;36m"  "$(date +'%F %H:%M') $1 " $(tput sgr0) "Success"      | tee -a  $Logs_path/local.log
    else
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') $1 " $(tput sgr0) "Failed"       | tee -a  $Logs_path/local.log
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') 本次部署"  $(tput sgr0) "Failed"  | tee -a  $Logs_path/local.log

        exit
    fi
}
################################################################################
Auto_path=`pwd`
Conf_path="${Auto_path}/conf"
Project_path="${Auto_path}/project"
Code_path="${Auto_path}/code"
Local_repo="${Auto_path}/repo"
Logs_path="${Auto_path}/logs"
Reset_path="${Auto_path}/reset"
#Time=`date +'%F %H:%M'`
resettem=$(tput sgr0)

export Auto_path Conf_path Project_path Code_path Local_repo Logs_path Reset_path  resettem


#变量数组;判断文件夹是否存在
declare  -a   Local_path
Local_path=($Logs_path $Conf_path $Project_path $Code_path  $Local_repo   $Reset_path )
for i in ${Local_path[@]};do
    mk_dire $i
done

if [  ! -f  ${Auto_path}/README.md ];then
cat  > ${Auto_path}/README.md  <<EOF
# 自动部署
## 全局信息
* conf目录  ${Conf_path}:    各项目的文件配置信息
* project目录 ${Project_path}:  各项目工作目录
* code目录  ${Code_path}:    各项目源码目录
* repo目录 ${Local_repo}:   各项目本地commit目录
* logs目录   ${Logs_path}:   全局日志
* reset目录 ${Reset_path}:   各项目版本回退目录

##配置文件信息
* main.conf: 主配置文件
* default.conf：各项目配置文件模板

##环境配置
* git 部署 : 配置好git config
* maven 部署  ： 最好提前测试一次maven构建，

EOF
fi



if [ ! -f ${Conf_path}/main.conf ];then
    cat > ${Conf_path}/main.conf <<EOF
# 说明

# Local_name: 自动部署加载的项目
# declare  -a  Local_name
# 请确定Local_name内填写的有对应的配置文件；
Local_name=()

#######################################
#各项目配置文件编写

# Git_repo: 项目项目地址（不能为空）
# Repo_name=

# Branch_name： 远程项目分支（默认为master）
# Bran_name=

# Source_name: git clone的项目名；即项目clone下的文件名;存放在code目录(不能为空)
# Sou_name=

# Compile_name: mvn编译后，target下生成的编译完成的项目目录(默认与Sou_name一样)
# Com_name=

# Destination_name: 各生产项目名;即存放于webapps下的(默认与Sou_name一样)
# Des_name=

# Server_name: 项目Server工作唯一识别信息(默认即为tomcat;多tomcat服务下，需要使用唯一特定标识）
# Ser_name=

# Server_path: Tomcat的安装目录(默认为/usr/local/tomcat）
# Ser_path=
#####################################
EOF
fi

#从配置文件内获取项目
eval $( grep  '^Local_name' ${Conf_path}/main.conf )

if [ ${#Local_name[@]} -eq 0 ];then
    echo -e "\e[1;31m" "$(date +'%F %H:%M') 未加载任何项目配置文件；程序退出" $(tput sgr0) | tee -a  $Logs_path/local.log
    exit
fi




echo -e "\e[1;36m"  "$(date +'%F %H:%M') 请选择自动部署的项目；同时请确认该项目的配置文件存在且正确"  ${resettem}

select project_name in ${Local_name[@]}
do
    if `echo ${Local_name[@]} | grep -wq "${project_name}" `;then
        echo -e "\e[1;33m" "$(date +'%F %H:%M') ${project_name} 项目开始部署"  ${resettem}  | tee -a  $Logs_path/local.log
        sh ${Auto_path}/script/work.sh ${project_name}
        if [ $? -eq 0 ];then
            echo -e "\e[1;36m"  "$(date +'%F %H:%M') 项目${project_name}部署;脚本work.sh运行 " $(tput sgr0) "Success"      | tee -a  $Logs_path/local.log
        else
            echo -e "\e[1;31m"  "$(date +'%F %H:%M') 项目${project_name}部署 " $(tput sgr0) "Failed"       | tee -a  $Logs_path/local.log
            echo -e "\e[1;31m"  "$(date +'%F %H:%M') 本次部署i"  $(tput sgr0) "Failed"  | tee -a  $Logs_path/local.log
            exit
        fi

        sh ${Auto_path}/script/restart.sh ${project_name}
        if [ $? -eq 0 ];then
            echo -e "\e[1;36m"  "$(date +'%F %H:%M') 项目${project_name}服务启动;脚本restart.sh " $(tput sgr0) "Success"      | tee -a  $Logs_path/local.log
        else
            echo -e "\e[1;31m"  "$(date +'%F %H:%M') 项目${project_name}服务启动 " $(tput sgr0) "Failed"       | tee -a  $Logs_path/local.log
            echo -e "\e[1;31m"  "$(date +'%F %H:%M') 本次部署"  $(tput sgr0) "Failed"  | tee -a  $Logs_path/local.log

            exit
        fi

        echo -e "\e[1;35m"  "$(date +'%F %H:%M') 本次部署"  $(tput sgr0) "Success" | tee -a  $Logs_path/local.log
        exit
    else
        echo -e "\e[1;31m" "请选择正确的数字；结束请按ctrl+c"  ${resettem}
    fi
done
