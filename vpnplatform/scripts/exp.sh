echo expiring date is : $1

#  date +%Y-%m-%d | awk -F- '{print $3}'

expY=`echo $1 | awk -F- '{print $1}'`
expM=`echo $1 | awk -F- '{print $2}'`
expD=`echo $1 | awk -F- '{print $3}'`

echo expiration year is : $expY
echo expiration month is : $expM
echo expiration day is : $expD

