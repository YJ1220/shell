#!/bin/bash
########################文件移动############################
# Note:根据获取的git_diff.log来对文件进行移动
# Author：
# DAte:2017年 8月 7日 星期一
# Email:
############################################################


function dic_path {
    dire=`pwd`
    if [ $dire != $1 ];then
        echo "当前目录错误"  |  tee -a ${Work_path}/$Build_num/logs/script.log
        exit 1
    else
        echo $dire
    fi
}
echo "#####################################################"

Web_Path="/usr/local/tomcat_trade/webapps"

mkdir ${Work_path}/${Build_num}/new_web   ${Work_path}/${Build_num}/old_web

#进入本次build目录；获取本次构建新增和修改文件进行压缩；将压缩后的文件移动到本次build下的new_web目录
cd $Build_path
dic_path $Build_path

awk '{ if ( $1 == "A") { print $2 } else if ( $1 == "M") {print $2}}'   ${Work_path}/$Build_num/git_diff.log  | grep "^USTrade" |   xargs zip -r USTrade.zip {}

mv USTrade.zip ${Work_path}/$Build_num/new_web

#进入生产环境目录；将原有项目在本次构建中修改和删除的文件进行打包压缩，将压缩后的文件移动到本次build下的old_web目录下

cd $Web_Path
dic_path $Web_Path

awk '{ if ( $1 == "M") { print $2 } else if ( $1 == "D") {print $2}}'   ${Work_path}/$Build_num/git_diff.log  | grep "^USTrade" | xargs zip -r USTrade.zip {}

mv USTrade.zip  ${Work_path}/$Build_num/old_web

# awk '{if ( $1 == "D" ) { print $2}}'  | xargs rm -rf {}

#
if [ -f $Web_Path/USTrade.zip ];then
    rm -rf $Web_Path/USTrade.zip
    if [ -f $Web_Path/USTrade.zip ]; then
        echo "删除生产环境目录下的USTrade.zip失败" | tee -a ${Work_path}/$Build_num/logs/script.log
        exit 2
    fi
fi
cd  ${Work_path}/$Build_num/new_web
dic_path ${Work_path}/$Build_num/new_web

cp USTrade.zip $Web_Path
echo "本次build后USTrade.zip，移动到生产环境目录${Web_Path}下sussess "



# cd $Web_Path
# dic_path $Web_Path
#
# unzip -o USTrade.zip
