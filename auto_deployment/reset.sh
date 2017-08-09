#!/bin/bash
##############################版本回退###########################################
# Note:当前版本回退
# Author：
# DAte:2017年 8月 7日 星期一
# Email:#
#############################function##########################################




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

mv  $Work_path/$Build_id $Work_path/$Build_id_`date +%F`

cd $Build_path
git reset --hard HEAD^
cd
