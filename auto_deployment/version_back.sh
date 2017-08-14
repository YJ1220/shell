#!/bin/bash
##############################版本回退###########################################
# Note:版本回退
# Author：
# DAte:2017年 8月 14日 星期一
# Email:#
#############################说明###############################################
# 主控脚本
# 全局变量
# 创建工作环境
# 脚本返回信息处理
###########################获取全局变量#########################################
Auto_path=`pwd`
Conf_path="${Auto_path}/conf"
Project_path="${Auto_path}/project"
Code_path="${Auto_path}/code"
Local_repo="${Auto_path}/repo"
Logs_path="${Auto_path}/logs"
Reset_path="${Auto_path}/reset"
resettem=$(tput sgr0)

export Auto_path Conf_path Project_path Code_path Local_repo Logs_path Reset_path  resettem




#确认是是否执行版本回退
echo -e "\e[1;31m"  "请确认是否回退到上一版本" $(tput sgr0)
read -p "如果确实请输入YES;不执行请输入其他或者直接回车"   input_check
if [ $input_check != "YES" ];then
    echo -e "\e[1;36m" "不执行版本回退"  $(tput sgr0)
    exit 1
else
    echo -e "\e[1;32m" "选择回退的项目" $(tput sgr0)
fi

eval $( grep  '^Local_name' ${Conf_path}/main.conf )

select project_name in ${Local_name[@]}
do
    if `echo ${Local_name[@]} | grep -wq "${project_name}" `;then
        echo -e "\e[1;32m" "$(date +'%F %H:%M')  开始执行项目${project_name}版本回退"  ${resettem}  | tee -a  ${Logs_path}/reset.log
     	sh ${Auto_path}/script//back.sh    ${project_name}
        if [ $? -eq 0 ];then
            echo -e "\e[1;36m"  "$(date +'%F %H:%M') 项目${project_name}当前版本回退 " $(tput sgr0) "Success"      | tee -a  $Logs_path/reset.log
        else
            echo -e "\e[1;31m"  "$(date +'%F %H:%M') 项目${project_name}当前版本回退 " $(tput sgr0) "Failed"       | tee -a  $Logs_path/reset.log
            echo -e "\e[1;31m"  "$(date +'%F %H:%M') 本次版本回退"  $(tput sgr0) "Failed"  | tee -a  $Logs_path/reset.log

            exit
        fi
        echo -e "\e[1;36m" "本次版本回退"  $(tput sgr0)  "Success"  | tee -a  ${Logs_path}/reset.log
        exit
    else
        echo -e "\e[1;31m" "请选择正确的数字；结束请按ctrl+c"  ${resettem}
    fi
done
