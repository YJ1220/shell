#!/bin/bash
###################################文件移动#####################################
# Note:根据获取的git_diff.log来对文件进行移动
# Author：
# DAte:2017年 8月 7日 星期一
# Email:

##############################function#########################################
#判断文件夹是否存在；不存在进行创建；
function mk_dire() {
    if [ ! -d $1 ];then
        mkdir -p $1
        if [ $? -ne 0  ];then
            echo -e "\e[1;31m" "$Time 创建目录$1 " $(tput sgr0) "Failed" | tee -a  ${Work_path}/$Build_num/logs/script.log
            exit 1
        else
            echo -e "\e[1;36m" "$Time 创建目录$1 " $(tput sgr0) "Success" | tee -a  ${Work_path}/$Build_num/logs/script.log
        fi
    fi
}
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

#############################工作目录###############################
#创建本次build目录和目录下的日志
mk_dire ${Work_path}/${Build_num}/logs


#项目build
echo  -e "\e[1;32m" "$Time Build构建开始"  $(tput sgr0) | tee -a  ${Work_path}/$Build_num/logs/script.log

cd $Code_path/USTrade_YJ
dic_path $Code_path/USTrade_YJ

git pull &> ${Work_path}/$Build_num/logs/pull.log
check_work  "项目pull"



/usr/local/maven/bin/mvn clean package -DskipTests  &> ${Work_path}/$Build_num/logs/build.log
check_work "项目打包"

#清除build目录内USTrade项目文件
if [ -d ${Build_path}/USTrade ];then
    echo  -e  "\e[1;33m" "$Time 开始删除Build目录内的USTrade项目" $(tput sgr0) | tee -a ${Work_path}/$Build_num/logs/script.log
    rm -rf ${Build_path}/USTrade
    check_work  "删除Build目录下原USTrade"
fi

#git 初始化
cd $Build_path
if [ $Build_num -eq 1 ] &&  [ ! -f ${Build_path}/init ];then
    git init
    echo "初始化build目录"  > init
    git add *
    git commit -m "初始化"
fi



#移动项目生成文件到build
mv ${Code_path}/USTrade_YJ/target/USTrade_yj  ${Build_path}/USTrade   &>/dev/null
check_work  "Code源码编译生成USTrade移动到${Build_path}"


#获取目录改变列表
cd ${Build_path}
dic_path ${Build_path}

git add *
git diff HEAD --name-status >  ${Work_path}/$Build_num/git_diff.log
git commit -m "第${Build_num}次提交"  &>/dev/null
if [ $? -eq 0  ];then
    echo -e "\e[1;36m" "$Time 第${Build_num}次部署;获取项目目录变动列表 "  ${resettem} "Success"| tee -a ${Work_path}/$Build_num/logs/script.log
elif [ $? -eq 1 ];then
    echo -e "\e[1;34m" "$Time 第${Build_num}次部署;项目内容没有变动;中止部署"    ${resettem} | tee -a ${Work_path}/$Build_num/logs/script.log
    exit 1
else
    echo -e "\e[1;31m" "$Time 第${Build_num}次部署;获取项目目录改变列表失败；停止部署"  ${resettem}  | tee -a ${Work_path}/$Build_num/logs/script.log
    exit 1
fi


mk_dire ${Work_path}/${Build_num}/new_web
mk_dire ${Work_path}/${Build_num}/old_web


#进入本次build目录；获取本次构建新增和修改文件进行压缩；将压缩后的文件移动到本次build下的new_web目录
cd $Build_path
dic_path $Build_path

awk '{ if ( $1 == "A") { print $2 } else if ( $1 == "M") {print $2}}'   ${Work_path}/$Build_num/git_diff.log  | grep "^USTrade" |   xargs zip -r USTrade.zip

check_work  "根据变量列表;本次编译变更文件压缩包生成"

mv USTrade.zip ${Work_path}/$Build_num/new_web
check_work  "移动编译后增量压缩文件到new_web"
#进入生产环境目录；将原有项目在本次构建中修改和删除的文件进行打包压缩，将压缩后的文件移动到本次build下的old_web目录下

if [ -f $Web_Path/USTrade.zip ];then
    rm -rf $Web_Path/USTrade.zip
    check_work "删除生产环境目录下USTrade.zip"
fi

cd $Web_Path
dic_path $Web_Path

awk '{print $1}'  ${Work_path}/$Build_num/git_diff.log >  ${Work_path}/$Build_num/status.log
check_work "获取变动文件状态列表"

#将生产项目内需要修改和删除的文件进行打包，同时删除本次需要移除的文件
if ` grep  -q '^M\|^D'  ${Work_path}/$Build_num/status.log` ;then
    awk '{ if ( $1 == "M") { print $2 } else if ( $1 == "D") {print $2}}'   ${Work_path}/$Build_num/git_diff.log  | grep  "^USTrade" | xargs zip -r USTrade.zip
    check_work  "根据变量列表;生产环境项目变更文件压缩包生成"
    mv USTrade.zip  ${Work_path}/$Build_num/old_web
    check_work   "移动项目改变压缩文件到old_web"
else
    echo -e "\e[1;31m"  "$Time 本次只有新增文件，没有删除和修改文件"   $(tput sgr0)  | tee -a ${Work_path}/$Build_num/logs/script.log
fi

if `grep -q '^D'  ${Work_path}/$Build_num/status.log `;then
    awk '{ if ($1 == "D") { print $2 }}'  ${Work_path}/$Build_num/git_diff.log | grep "^USTrade" | xargs
    rm -rf
    check_work  "删除生产项目内本次变更移除文件"
fi


#copy本次build生成的压缩包
cp ${Work_path}/$Build_num/new_web/USTrade.zip $Web_Path
check_work "本次编译生成增量文件压缩包移动到生产环境目录${Web_Path}下"

cd $Web_Path
dic_path  $Web_Path

#解压USTrade.zip
unzip -o USTrade.zip
check_work "解压 USTrade.zip;文件覆盖"
