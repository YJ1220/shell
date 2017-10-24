#!/bin/bash
#########################
# File Name: mdck
# Author:
# Mail:
# Craeted time: 2016年 05月 14日 星期六 20:57:28 CST
# Dsecription :mysql data back
# Note: 设置crontab,每天凌晨2:00运行
########################
mysqlPath=/usr/local/mysql
passwd=passwd
check_dump() {
if [ $? != 0 ];then
    echo -e  "$(date +%F) $(date +%T): The database has not ben  backed up successfully:" '\e[1;35m' $i '\e[1;0m'  &>> /databa/log/mysqldumperror.log
    exit 0
else
    echo -e  "$(date +%F) $(date +%T): The database has ben backed up successfully:" '\e[1;32m' $i '\e[1;0m' >> /databa/log/mysqldump.log
fi
}
creatlist() {
    $mysqlPath/bin/mysql -uroot -p${passwd} -e "show databases;"  > /databa/log/sql.txt 2>/dev/null
    if [ $? != 0 ];then
        echo -e '\e[1;33m' $(date +%T): $(tput sgr0)  " Error!sql.txt is no exist"  >>   /databa/log/mysqlerror.log
    fi
}
delold(){
    if  [ -f /databa/mysql/${i}$(date +%F --date="-2 day").sql ];then
        rm -rf /databa/mysql/${i}$(date +%F --date="-2 day").sql   &>/dev/null
        if [  $? != 0 ];then
            echo -e  "$(date +%T): The database delete  has not ben  successfully:" '\e[1;36m' $i '\e[1;0m'  &>> /databa/log/mysqlerror.log
        fi
    fi
    if [ -f /databa/tar/${i}$(date +%F --date="-3 day").sql.tar.gz ];then
        rm -rf /databa/tar/${i}$(date +%F --date="-3 day").sql.tar.gz &>/dev/null
        if [  $? != 0 ];then
            echo -e  "$(date +%T): The tar  delete  has not ben  successfully:" '\e[1;33m' $i '\e[1;0m'  &>> /databa/log/mysqlerror.log
        fi
    fi
}
dumpsql() {
for i in `cat /databa/log/sql.txt`;do
    if [ $i != "Database" -a $i != "information_schema" -a $i != "test"  -a $i != "performance_schema"  -a $i != "mysql" ] ; then
          $mysqlPath/bin/mysqldump -uroot -p${passwd} --opt -R  $i  > /databa/mysql/${i}$(date +%F).sql 2>/dev/null
          check_dump
          tar -zcf  /databa/tar/${i}$(date +%F).sql.tar.gz /databa/mysql/${i}$(date +%F).sql   &>/dev/null
          if [ $? != 0 ];then
  	    	    echo -e  "$(date +%T): The database tar has not ben  successfully:" '\e[1;35m' $i '\e[1;0m'  &>> /databa/log/mysqlerror.log
	      fi
          delold
    fi
done
}
creatlist
dumpsql
