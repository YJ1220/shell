#!/bin/baash
############################main###############################################
# Note: 项目部署脚本
# Author:YJ
# Date: 2017年 8月10日 星期四 15时57分56秒 CST
# Email:
############################说明###############################################
# 项目部署具体脚本
# 工作变量
# 项目work环境
# 脚本返回信息处理
#########################function##############################################
#判断文件夹是否存在；不存在进行创建；
function mk_dire() {
    if [ ! -d $1 ];then
        mkdir -p $1
        if [ $? -ne 0  ];then
            echo -e "\e[1;31m" "$(date +'%F %H:%M') 创建目录$1 " $(tput sgr0) "Failed" | tee -a  ${Logs_path}/local.log
            echo -e "\e[1;31m" "$(date +'%F %H:%M') 自动部署失败" $(tput sgr0)  | tee -a  $Logs_path/local.log
            exit 1
        else
            echo -e "\e[1;32m" "$(date +'%F %H:%M') 创建目录$1 "$(tput sgr0) "Success" | tee -a  ${Logs_path}/local.log
        fi
    fi
}
#判断上条命令执行结果
function check_work() {
    if [ $? -eq 0 ];then
        echo -e "\e[1;32m"  "$(date +'%F %H:%M') $1 "  $(tput sgr0) "Success"  | tee -a  ${Work_logs}/script.log
    else
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') $1 "  $(tput sgr0) "Failed"   | tee -a  ${Work_logs}/script.log
        exit 1
    fi
}
#判断目录是否正确
function dic_path() {
    dire=`pwd`
    if [ $dire != $1 ];then
        echo -e "\e[1;31m"  "$(date +'%F %H:%M') 切换到目录$1 "  $(tput sgr0) "失败" | tee -a  ${Work_logs}/script.log
        exit 1
    else
        echo -e "\e[1;32m"  "$(date +'%F %H:%M') 切换到目录$1 "  $(tput sgr0) | tee -a  ${Work_logs}/script.log
    fi
}
#获取配置文件变量
function eval_variate() {
	if [ $? -ne 0 ];then
		echo -e "\e[1;31m" "$(date +'%F %H:%M') 配置文件编写错误,不能正确获取变量；请重新修改配置文件"  | tee -a  ${Logs_path}/local.log
		exit 1
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


# Repo_name:项目项目地址（不能为空）
# Bran_name:项目的分支(默认为master)
# Sou_name:git clone的项目名；即项目clone下的文件名;存放在code目录（不能为空）
# Com_name:mvn编译的文件名;有时编译后，会将clone下来的文件名改变
# Des_name:各生产项目名;即存放于webapps下的 (默认与Sou_name一样)
# Ser_name:项目Server工作唯一识别信息（默认即为tomcat;多tomcat服务下，需要使用唯一特定标识）
# Ser_path:Tomcat目录（默认为/usr/local/tomcat）
######################################配置文件校验########################################
project_name=$1

#判断是否存在
if [ ! -f ${Conf_path}/${project_name}.conf ];then
	echo -e "\e[1;31m" "$(date +'%F %H:%M') ${project_name}项目部署配置文件不存在；退出部署" ${resettem} | tee -a ${Logs_path}/local.log
	exit 1
fi

#获取变量Repo_name
eval $( grep '^Repo_name' ${Conf_path}/${project_name}.conf)   &>/dev/null
eval_variate
#获取变量Branch_name
eval $( grep '^Bran_name' ${Conf_path}/${project_name}.conf)   &>/dev/null
eval_variate
#获取变量Sou_name
eval $( grep '^Sou_name' ${Conf_path}/${project_name}.conf)    &>/dev/null
eval_variate
#获取变量Com_name
eval $( grep '^Com_name' ${Conf_path}/${project_name}.conf)    &>/dev/null
eval_variate
#获取变量Des_name
eval $( grep '^Des_name' ${Conf_path}/${project_name}.conf)    &>/dev/null
eval_variate
#获取变量Ser_name
eval $( grep '^Ser_name' ${Conf_path}/${project_name}.conf)    &>/dev/null
eval_variate
#获取变量Ser_path
eval $( grep '^Ser_path' ${Conf_path}/${project_name}.conf)    &>/dev/null
eval_variate


#判断变量是否为空
if [ -z ${Repo_name} ];then
	echo -e "\e[1;31m" "$(date +'%F %H:%M') 变量Repo_name为空 "  ${resettem}  |  tee -a ${Logs_path}/local.log
	exit 1
elif [ -z ${Sou_name} ]; then
	echo -e "\e[1;31m" "$(date +'%F %H:%M') 变量Sou_name为空 "  ${resettem}  |  tee -a ${Logs_path}/local.log
	exit 1
else
	echo -e "\e[1;32m" "$(date +'%F %H:%M') 获取配置文件变量完成 "  ${resettem}  |  tee -a ${Logs_path}/local.log
fi

#空值变量为空的赋予默认值
if [ -z ${Bran_name} ];then
    Bran_name="master"
fi
if [ -z ${Com_name} ];then
	Com_name=${Sou_name}
fi
if [ -z ${Des_name} ];then
	Des_name=${Sou_name}
fi
if [ -z ${Ser_name} ];then
	Ser_name="Tomcat"
fi
if [ -z ${Ser_path} ];then
	Ser_path="/usr/local/tomcat"
fi

#####################################work各目录######################################

#部署项目目录
Project_work=${Project_path}/${project_name}
#build.tx
Build_id=${Project_work}/build.txt

#创建项目的部署目录
mk_dire ${Project_work}

#创建项目的本地commit目录
Project_repo=${Local_repo}/${project_name}_repo
mk_dire ${Project_repo}


#项目的工作目录
Work_path=${Project_work}/workspace

mk_dire ${Work_path}

#判断build_id是否存在;同时判断build_id的值是否准确
if [ ! -f ${Build_id} ];then
    echo -e  "\e[1;32m" "初始化build_id"  ${resettem}
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
        echo -e "\e[1;32m" "$(date +'%F %H:%M') Build版本id值错误；文件内的值为${id_old};work目录内当前的版本为${id_num}" ${resettem}| tee -a $Logs_path/local.log
        exit 1
    fi
fi
#获取本次build_id
get_id=`cat $Build_id `
Build_num=$(( $get_id + 1 ))

if [ $? -ne 0 ];then
    echo -e "\e[1;31m" "$(date +'%F %H:%M') 获取本次build_id失败"  ${resettem} | tee  -a ${Logs_path}/local.log
    echo -e "\e[1;31m" "$(date +'%F %H:%M') 部署停止"  ${resettem}   | tee  -a ${Logs_path}/local.log
    exit 1
else
    echo -e "\e[1;32m" "$(date +'%F %H:%M') 获取本次build_id为"  ${resettem}  ${Build_num} | tee  -a $Logs_path/local.log
fi

#更新build_id
echo $Build_num > $Build_id

#每次work目录
Work_num=${Work_path}/${Build_num}

#每次部署下的具体工作
Work_logs=${Work_num}/logs
Work_old=${Work_num}/old_web
Work_new=${Work_num}/new_web
#git_diff.log
#status.log

mk_dire ${Work_num}
mk_dire ${Work_new}
mk_dire ${Work_old}
mk_dire ${Work_logs}

#####################################具体操作######################################
#项目git clone;编译；移动
echo  -e "\e[1;32m" "$(date +'%F %H:%M') 开始项目构建"  $(tput sgr0) | tee -a  ${Work_logs}/script.log


if [ ! -d  ${Code_path}/${Sou_name} ];then
	cd   ${Code_path}
	dic_path "${Code_path}"
	git clone ${Repo_name} &>${Work_logs}/pull.log
    check_work  "clone项目${project_name}"
    cd  ${Code_path}/${Sou_name}
    if [ ${Bran_name} != "master" ];then
        git checkout --track origin/${Bran_name}
    fi
else
	cd  ${Code_path}/${Sou_name}
	dic_path ${Code_path}/${Sou_name}
    ##切换分支
    if [ ${Bran_name} != "master" ];then
        git checkout ${Bran_name}
    fi
	git pull &> ${Work_logs}/pull.log
    #分支拉取 git pull origin ${Bran_name}
	check_work  "项目pull"
fi

##项目maven编译
echo -e "\e[1;32m" "$(date +'%F %H:%M') 开始编译项目${project_name}"  $(tput sgr0) | tee -a  ${Work_logs}/script.log


/usr/local/maven/bin/mvn clean package -DskipTests  &> ${Work_logs}/build.log
check_work "项目打包"



##移除Project_repo目录内部署项目文件
if [ -d ${Project_repo}/${Des_name} ];then
    echo  -e  "\e[1;33m" "$(date +'%F %H:%M') 删除${Project_repo}目录内原${Des_name}目录" $(tput sgr0) | tee -a ${Work_logs}/script.log
    rm -rf ${Project_repo}/${Des_name}
    check_work  "删除${Project_repo}目录下原有${Des_name}"
fi

##Project_repo目录下git初始化

cd ${Project_repo}
dic_path ${Project_repo}

if [ $Build_num -eq 1 ] &&  [ ! -f ${Project_repo}/init ];then
    git init
    echo "初始化build目录"  > init
    git add *
    git commit -m "初始化"
fi



#移动项目生成文件到build
mv ${Code_path}/${Sou_name}/target/${Com_name}  ${Project_repo}/${Des_name}   &>/dev/null
check_work  "Code源码编译后生成${Sou_name}移动到${Project_repo}"


#获取目录改变列表
cd ${Project_repo}
dic_path ${Project_repo}

git add *
git diff HEAD --name-status >  ${Work_logs}/git_diff.log
git commit -m "项目${project_name}第${Build_num}次提交"  &>/dev/null

#判断本次提交状态；成功、没变化或者失败
if [ $? -eq 0  ];then
    echo -e "\e[1;32m" "$(date +'%F %H:%M') 项目${Des_name}第${Build_num}次部署;获取项目目录变动列表 "  ${resettem} "Success"| tee -a ${Work_logs}/script.log
    echo 1 > ${Work_logs}/gitstatus
elif [ $? -eq 1 ];then
    echo -e "\e[1;31m" "$(date +'%F %H:%M') 项目${Des_name}第${Build_num}次部署;项目内容没有变动;中止部署"    ${resettem} | tee -a ${Work_logs}/script.log
    exit 1
else
    echo -e "\e[1;31m" "$(date +'%F %H:%M') 项目${Des_name}第${Build_num}次部署;获取项目目录改变列表失败；停止部署"  ${resettem}  | tee -a ${Work_logs}/script.log
    exit 1
fi



#进入项目本地repo目录；获取本次构建新增和修改文件进行压缩；将压缩后的文件移动到本次work下的new_web目录
cd ${Project_repo}
dic_path "${Project_repo}"

awk '{ if ( $1 == "A") { print $2 } else if ( $1 == "M") {print $2}}'   ${Work_logs}/git_diff.log  | grep "^${Des_name}" |   xargs zip -r ${Des_name}.zip
check_work  "根据变量列表;本次编译变更文件压缩包生成"


awk '{print $1}'  ${Work_logs}/git_diff.log >  ${Work_logs}/status.log
check_work "获取变动文件状态列表"


mv ${Des_name}.zip ${Work_new}
check_work  "移动编译后增量压缩文件到new_web"

#进入生产环境目录；将原有项目在本次构建中修改和删除的文件进行打包压缩，将压缩后的文件移动到本次work下的old_web目录下
if [ -f ${Ser_path}/webapps/${Des_name}.zip ];then
    rm -rf ${Ser_path}/webapps/${Des_name}.zip
    check_work "删除生产环境目录下${Des_name}.zip"
fi


cd ${Ser_path}/webapps
dic_path "${Ser_path}/webapps"

#将生产项目内需要修改和删除的文件进行打包，同时删除本次需要移除的文件

if ` grep  -q '^M\|^D'  ${Work_logs}/status.log` ;then
    awk '{ if ( $1 == "M") { print $2 } else if ( $1 == "D") {print $2}}'  ${Work_logs}/git_diff.log  | grep  "^${Des_name}" | xargs zip -r ${Des_name}.zip
    check_work  "根据变量列表;生产环境项目变更文件备份压缩包生成"
    mv ${Des_name}.zip  ${Work_old}
    check_work   "移动项目server环境改变备份压缩文件到old_web"
else
    echo -e "\e[1;31m"  "$(date +'%F %H:%M') 本次只有新增文件，没有删除和修改文件"   $(tput sgr0)  | tee -a  ${Work_logs}/script.log
fi

if `grep -q '^D'  ${Work_logs}/status.log `;then
    awk '{ if ($1 == "D") { print $2 }}'  ${Work_logs}/git_diff.log | grep "^${Des_name}" | xargs rm -rf
    check_work  "删除生产项目内本次变更移除文件"
fi

#copy本次build生成的压缩包
cp ${Work_new}/${Des_name}.zip ${Ser_path}/webapps
check_work "本次编译生成增量文件压缩包移动到生产环境目录${Ser_path}/webapps下"

cd ${Ser_path}/webapps
dic_path  "${Ser_path}/webapps"

#解压USTrade.zip
unzip -o ${Des_name}.zip
check_work "解压 ${Des_name}.zip;生产环境文件更新覆盖"
