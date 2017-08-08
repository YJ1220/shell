#!/bin/bash
###############################################################################
# Note:自动部署
# Author:
# Dat:e2017年 8月 7日 星期一
# Email:
# versions： v1.0
# READ:第一次构建，echo 颜色未配置，目前只针对单独项目做部署，需要一些初始条件；配置

#############################说明###############################################
#全局日志存放于Logs_path目录
#每次发布单独日志存放于各自工作目录下
#环境配置需要git maven
#提前git clone 项目到code文件夹
#########################function##############################################
#判断文件夹是否存在；不存在进行创建；
function mk_dire() {
    if [ ! -d $1 ];then
        echo "$Time 创建目录$1"  | tee -a  $Logs_path/local.log
        mkdir -p $1
        if [ ! -d $1 ];then
            echo "$Time 创建目录$1失败" | tee -a  $Logs_path/local.log
            exit 1
        fi
    fi
}

################################################################################

#脚本全局变量
Code_path='/root/autodeployment/code'
Build_path='/root/autodeployment/build'
Logs_path='/root/autodeployment/logs'
Work_path='/root/autodeployment/work'
Build_id='/root/autodeployment/build.txt'
Time=`date +'%F %H:%M'`
resettem=$(tput sgr0)
export Code_path Build_path Logs_path Work_path  Time Build_id resettem

#变量数组;判断文件夹是否存在
declare  -a   Local_path
Local_path=($Code_path $Build_path $Logs_path $Work_path )
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
        echo -e "\e[1;31m" "$Time Build版本id值错误；文件内的值为${id_old};work下的版本为${id_num}" | tee -a $Logs_path/error.log
        exit 1
    fi
fi

#获取本次build_id
get_id=`cat $Build_id `
Build_num=$(( $get_id + 1 ))
export Build_num
if [ $? -ne 0 ];then
    echo -e  "\e[1;31m" "$Time 获取本次build_id失败"  ${resettem} | tee  -a $Logs_path/error.log
    exit 1
else
    echo -e "\e[1;36m" "$Time 本次build_id为"  ${resettem}  ${Build_num}
fi
#更新build_id
echo $Build_num >$Build_id

#创建本次build目录和目录下的日志
/bin/mkdir  -p   ${Work_path}/${Build_num}/logs
if [ ! -d  ${Work_path}/${Build_num}/logs ];then
    echo "$Time 第${Build_num}次构建  创建${Build_num}目录失败 "  | tee -a ${Logs_path}/error.log
fi

#项目build
echo "本次build的时间 $Time" | tee -a  ${Work_path}/$Build_num/logs/script.log
cd $Code_path/USTrade_YJ
git pull &>${Work_path}/$Build_num/logs/pull.log
if [ $? -ne  0 ];then
    echo "$Time 项目pull失败"  | tee -a ${Work_path}/$Build_num/logs/script.log
fi
/usr/local/maven/bin/mvn clean package -DskipTests  &> ${Work_path}/$Build_num/logs/build.log
if [ $? -ne 0 ];then
    echo "$Time 项目打包失败"  | tee -a ${Work_path}/$Build_num/logs/script.log
    exit 1
else
    echo "$Time 项目打包成功"  | tee -a ${Work_path}/$Build_num/logs/script.log
fi

#git 初始化
cd $Build_path
if [ $Build_num -eq 1 ] &&  [ ! -f ${Build_path}/init ];then
    git init
    echo "初始化build目录"  > init
    git add *
    git commit -m "初始化"
fi

#清除build目录内USTrade项目文件
if [ -d ${Build_path}/USTrade ];then
    echo "$Time 清除Build目录内的USTrade项目"  | tee -a ${Work_path}/$Build_num/logs/script.log
    rm -rf ${Build_path}/USTrade
    if [ -d ${Build_path}/USTrade ];then
        echo "$Time 删除Build原有目录失败" | tee -a  ${Logs_path}/error.log
    fi
fi

#移动项目生成文件到build
mv ${Code_path}/USTrade_YJ/target/USTrade_yj  ${Build_path}/USTrade   &>/dev/null
if [ $? -ne 0 ];then
    echo "$Time build文件迁移失败" | tee -a ${Logs_path}/error.log
    exit 1
fi

#获取目录改变列表
cd ${Build_path}
git add *
git diff HEAD --name-status >  ${Work_path}/$Build_num/git_diff.log
git commit -m "第${Build_num}次提交"  &>/dev/null
if [ $? -eq 0  ];then
    echo "$Time 第${Build_num}次部署;获取项目目录变动列表success"| tee -a  ${Work_path}/$Build_num/logs/script.log
elif [ $? -eq 1 ];then
    echo "$Time 第${Build_num}次部署；项目内容没有变动；停止部署" | tee -a ${Logs_path}/error.log
    exit 1
else
    echo "$Time 第${Build_num}次部署;获取项目目录改变列表失败"  | tee -a ${Logs_path}/error.log
    exit 1
fi
sh  /root/autodeployment/script/file_move.sh
if [ $?  -ne 0 ];then
    echo "file_move脚本执行出现错误"  | tee -a ${Work_path}/$Build_num/logs/script.log
else
    echo "脚本执行完毕"
fi
