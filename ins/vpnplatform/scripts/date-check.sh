
expY=`echo $1 | awk -F- '{print $1}'`
expM=`echo $1 | awk -F- '{print $2}'`
expD=`echo $1 | awk -F- '{print $3}'`

if ! test $expY -ge 2011 || ! test $expY -le 2020 ||  ! test $expD -le 31\\
|| ! test $expD -ge 1 || ! test $expM -ge 1 ||  ! test $expM -le 12 ; then
echo malformed date !
exit
fi



echo your date has passed the test!



