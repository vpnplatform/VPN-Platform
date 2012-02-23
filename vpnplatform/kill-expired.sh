
today=`date +%Y-%m-%d`
echo today is :  $today
echo killing expired users ...

expY=`echo $today | awk -F- '{print $1}'`
expM=`echo $today | awk -F- '{print $2}'`
expD=`echo $today | awk -F- '{print $3}'`

if ! test -d /root/vpnplatform/expdb/$expY/$expM/$expD/; then
echo we have nobody for killing today !
exit 
fi


for i in `ls -1 /root/vpnplatform/expdb/$expY/$expM/$expD/`
do
echo killing user $i
sh /root/vpnplatform/scripts/revoke-cron.sh $i
done
rm -rf  /root/vpnplatform/expdb/$expY/$expM/$expD/ 


