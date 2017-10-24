#!/bin/bash
####################################
#Note: IFPM日志压缩备份，迁移至NAS存储，每天执行,保留15天的日志
#CreateTime:2017年 7月25日 星期二
#Author:
#Email:
#####################################

log_path='/usr/local/tomcat_trade/logs/IFPM'
Month=`date +%Y-%m --date='-7 day'`
Date=`date +%F --date='-7 day'`
check_ok(){
if [ $?  != 0 ];then
    echo '命令执行失败'
    exit 1   
 
fi
}
if [  ! -d /wocloud/backup/log_back/${Month} ];then
    mkdir -p /wocloud/backup/log_back/${Month}
fi

cd ${log_path}
dir_path=`pwd`
if [ ${dir_path} != ${log_path} ];then 
    echo '`date +'%F %H:%M'`当前目录错误' > /root/script/log_backup.log
    exit 1
fi


if [ -f /wocloud/backup/log_back/${Month}/${Date}.tar.gz ];then
	/bin/mv /wocloud/backup/log_back/${Month}/${Date}.tar.gz    /wocloud/backup/log_back/${Month}/${Date}_`date +'%H:%M'`.tar.gz
fi


if [ -f IFPM.${Date}.log ];then
    tar -zcf  ${Date}.tar.gz IFPM.${Date}.log
    check_ok
	/bin/mv ${Date}.tar.gz /wocloud/backup/log_back/${Month}
	check_ok
	rm -rf IFPM.${Date}.log
	check_ok
fi





