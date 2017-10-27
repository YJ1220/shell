#!/bin/bash
#网卡流量监控
eth=eth1
date_cw=$(date "+%Y/%m/%d_%H:%M:%S")
pwd_cw=/root/$(/sbin/ifconfig $eth |grep Mask |awk '{print $2}'|awk -F : '{print $2}').txt
RXpre=$(/sbin/ifconfig $eth |grep bytes |awk '{print $2}' |awk -F : '{print $2}')
TXpre=$(/sbin/ifconfig $eth |grep bytes |awk '{print $6}' |awk -F : '{print $2}')
#echo $RXpre $TXpre
sleep 1
RXnext=$(/sbin/ifconfig $eth |grep bytes |awk '{print $2}' |awk -F : '{print $2}')
TXnext=$(/sbin/ifconfig $eth |grep bytes |awk '{print $6}' |awk -F : '{print $2}')
RX="$(((${RXnext}-${RXpre})/1024*8))Kb/s"
TX="$(((${TXnext}-${TXpre})/1024*8))Kb/s"
#echo $RXnext $TXnext
echo $date_cw $RX $TX >> $pwd_cw
pwd_hlwz=/HLW_Z/cw/bandwidth/$(/sbin/ifconfig $eth |grep Mask |awk '{print $2}'|awk -F : '{print $2}').txt
echo $date_cw $RX $TX >> $pwd_hlwz
