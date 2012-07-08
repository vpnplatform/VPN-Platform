#!/bin/bash

#defining functions and variables

gettmpfile()
{
  local tmppath=${1:-/tmp}
  local tmpfile=$2${2:+-}
  tmpfile=$tmppath/$tmpfile$RANDOM$RANDOM.tmp
  if [ -e $tmpfile ]
  then
    # if file already exists, recurse and try again
    tmpfile=$(gettmpfile $1 $2)
  fi
  echo $tmpfile
}


linedel()
{
tmpf=`gettmpfile`
grep -v "$1" $2 > $tmpf
echo "$3" >> $tmpf
cat $tmpf > $2
rm -rf $tmpf
}


checkwc()
{
wcc=`echo $1 | wc -c `
if test $wcc -ne $2; then
echo error, charachtars count is not accurate, exiting ...
exit 1
fi
}

dpkgcheck()
{
dpkg -s $1 | grep "ok installed"   &> /dev/null
if test $? -ne 0; then
dpkg -i $2
checkerr
else
echo Package $1 is installed
fi
}



aptcheck()
{
apt-get -fy install
dpkg -s $1 | grep "ok installed"   &> /dev/null
if test $? -ne 0; then
apt-get -fy install $1
checkerr
apt-get -fy install
else
echo Package $1 is installed
fi
}

checkval()
{
if test -z $1 ; then
echo error, this value cant is empty
exit 1
fi
}

checkval2()
{
echo $Answer | grep -i accept &> /dev/null
if test $? -eq 0; then
echo OK, Moving to next step...
else
echo Please try again later, exiting ...
exit 1
fi
}


checkval3()
{
echo "$1" | grep -i "$2" &> /dev/null
if test $? -ne 0; then
echo OK, Moving to next step...
else
echo Error - please try again later, exiting ...
exit 1
fi
}


 

checkerr()
{ 
if test $? -ne 0 ; then
echo error, function failed - exiting ..
echo "You can find installation log at : $log_ins"
exit 1
fi
} 

# gathering information

perl oschooser.pl os_list.txt myos 1
checkerr
chmod +x myos
checkerr
 . ./myos
checkerr

if test "$real_os_type" = "Debian Linux"; then

cp -ru deb-repos /etc/apt/sources.list

fi

/sbin/ifconfig | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' | grep -v "127.0.0.1"   &>  myips 
checkerr

ipscount=`wc -l myips  | awk '{ print $1}'`

if test "$ipscount" -eq 1; then
mainip=`cat myips`
else
echo 'Please enter your external IP serial : '
select mainip in `cat myips`
 do
  echo
  checkval $mainip
  echo "Your external IP is : $mainip"
  echo
  break
 done
fi

if test -s /root/vpnplatform/.email -a -s /root/vpnplatform/.myorg -a -s /root/vpnplatform/.country  -a -s /root/vpnplatform/.province  -a -s /root/vpnplatform/.city; then
echo Using your exist information ...

 . /root/vpnplatform/.city
 . /root/vpnplatform/.country
 . /root/vpnplatform/.email
 . /root/vpnplatform/.myorg
 . /root/vpnplatform/.province

else

echo "Please provide the following information for the self-signed SSL certificate of OpenVPN to get generated using OpenSSL:"

echo "                 "
echo "" 
printf "Your Email : "


read -p " " myemail
checkval $myemail

read -p "Your City : " mycity
checkval $mycity

read -p "Your Country code (2 letters), e.g. \"KW\" : " mycountry
checkval $mycountry
checkwc $mycountry 3

read -p "Your Province : " myprovince
checkval $myprovince

read -p "Your Organization (no spaces please!) : " myorg
checkval $myorg
checkval3 "$myorg" " "
clear


echo Your information is :
echo Country  	 : $mycountry
echo Email   	 : $myemail
echo City	 : $mycity
echo Province	 : $myprovince
echo Organization: $myorg

echo ""
echo "Please note: the information above will be sent to VPN Platform development team of statistics purposes only"
echo "if you wish not to participate in these statistics please answer (no) below"

read -p "I accept to send the information to VPN Platform installation team (yes/NO)" Answer



if test -d /etc/apparmor -o -d /etc/apparmor.d/; then
/etc/init.d/apparmor stop
/etc/init.d/apparmor teardown
fi

if test -d /root/vpnplatform/scripts ; then
rm -rf /root/vpnplatform/scripts
fi

if test -d /root/vpnplatform/1.0 ; then
rm -rf /root/vpnplatform/1.0
fi


mkdir -p /root/vpnplatform/

cp -ru vpnplatform/* /root/vpnplatform/

checkerr

echo export KEY_COUNTRY=\"$mycountry\" >> /root/vpnplatform/scripts/vars-2011
checkerr
echo export KEY_PROVINCE=\"$myprovince\" >> /root/vpnplatform/scripts/vars-2011
checkerr
echo export KEY_CITY=\"$mycity\" >> /root/vpnplatform/scripts/vars-2011
checkerr
echo export KEY_ORG=\"$myorg\" >> /root/vpnplatform/scripts/vars-2011
checkerr

echo export KEY_EMAIL=\"$myemail\" > /root/vpnplatform/.email
checkerr
echo export KEY_COUNTRY=\"$mycountry\" > /root/vpnplatform/.country
checkerr
echo export KEY_PROVINCE=\"$myprovince\" > /root/vpnplatform/.province
checkerr
echo export KEY_CITY=\"$mycity\" > /root/vpnplatform/.city
checkerr
echo export KEY_ORG=\"$myorg\" > /root/vpnplatform/.myorg




fi


 . /root/vpnplatform/.city
 . /root/vpnplatform/.country
 . /root/vpnplatform/.email
 . /root/vpnplatform/.myorg
 . /root/vpnplatform/.province




if test -d /root/vpnplatform/scripts ; then
rm -rf /root/vpnplatform/scripts
fi

if test -d /root/vpnplatform/1.0 ; then
rm -rf /root/vpnplatform/1.0
fi


mkdir -p /root/vpnplatform/


if ! test -d /root/vpnplatform/"$KEY_ORG"; then

cp -ru vpnplatform/empty /root/vpnplatform/"$KEY_ORG" &> /dev/null

checkerr
fi

rm -rf /root/vpnplatform/scripts
cp -ru vpnplatform/scripts /root/vpnplatform/
checkerr



# searching for the external interface

interfaces=`ifconfig -s | awk '{print $1}' | grep -v Iface | grep -v lo`
ifaces_count=`echo "$interfaces" | wc -w`
ifconfig -s | awk '{print $1}' | grep -v Iface | grep -v lo > my-interfaces

if test "$ifaces_count" -eq 1; then
extface="$interfaces"
else
for iface in `cat my-interfaces`
do
ifconfig "$iface" | grep "$mainip" > /dev/null
if test "$?" -eq 0; then
extface="$iface"
break
fi
done
fi
checkerr

echo external interface is : "$extface"
sleep 2

echo New client installation happend, with the following info : > /root/vpnplatform/message-body
echo client email  : "$KEY_EMAIL" >> /root/vpnplatform/message-body
echo version 	   : "$ver"	>> /root/vpnplatform/message-body
echo client country: "$KEY_COUNTRY"	>> /root/vpnplatform/message-body
echo client city   : "$KEY_CITY"	>> /root/vpnplatform/message-body
echo client main ip: "$mainip"	>> /root/vpnplatform/message-body
echo client extface: "$extface"	>> /root/vpnplatform/message-body
echo client org    : "$KEY_ORG"	>> /root/vpnplatform/message-body
echo client prov   : "$KEY_PROVINCE"	>> /root/vpnplatform/message-body
cat myos >> /root/vpnplatform/message-body

#If Answer is yes then send email and continue else send no email and continue
echo $Answer |grep -i yes &> /dev/null
if [ $? -eq 0 ]
        then
                echo "Sending email to VPN Platform installation team"
                mail -s "New VPN Server" "installations@vpnplatform.org" < /root/vpnplatform/message-body
                sleep 2
        else
                echo "no email is being sent to installation team"
                sleep 2
fi



#installing packages

apt-get update
checkerr
apt-get -fy upgrade
checkerr


wget -c http://www.webmin.com/download/deb/webmin-current.deb
checkerr
wget -c http://prdownloads.sourceforge.net/webadmin/usermin_1.500_all.deb
checkerr

apt-get -fy install  perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
checkerr

dpkgcheck webmin webmin-current.deb
dpkgcheck usermin usermin_1.500_all.deb



#defining os arch (for future development use)

arch=`uname -i`
echo $arch | grep x86_64 &> /dev/null
if test $? = 0 ;then
export os_arch=64
else
export os_arch=32
fi




for pkg in  libcrypt-ssleay-perl libnet-ssleay-perl p7zip p7zip-full apache2 heirloom-mailx ppp apg dnsmasq openvpn pptpd chkconfig iptables
do
aptcheck $pkg
done

cp ovpn-apache2 /etc/apache2/sites-available/default -r
checkerr
mkdir -p /var/www/ovpn
checkerr
sed -i 's/\${APACHE_LOG_DIR}/\/var\/log/g' /etc/apache2/sites-enabled/000-default
/etc/init.d/apache2 restart 2> /dev/null
checkerr

grep "10.0.12.1" /etc/pptpd.conf &> /dev/null

if test $? -eq 1; then
echo "localip 10.0.12.1" >>  /etc/pptpd.conf
echo "remoteip 10.0.12.2-254" >>  /etc/pptpd.conf
fi

if test -s /etc/ppp/pptpd-options; then
rm -rf /etc/ppp/pptpd-options
fi
cp pptpd-options /etc/ppp/pptpd-options
checkerr
chmod 600 /etc/ppp/chap-secrets
/etc/init.d/pptpd stop  2> /dev/null && /etc/init.d/pptpd start  2> /dev/null

chkconfig pptpd on
checkerr
chkconfig apache2 on
chkconfig openvpn on
chkconfig usermin on
chkconfig dnsmasq on
/etc/init.d/dnsmasq restart

echo All prerequestes are ready, next ...

if test -d /etc/webmin/custom/; then
rm -rf /etc/webmin/custom/
fi

cp -ru custom/ /etc/webmin/

sed -i 's/ssl=0/ssl=1/g' /etc/webmin/miniserv.conf 
sed -i 's/ssl=0/ssl=1/g' /etc/usermin/miniserv.conf

rm -rf /etc/usermin/webmin.acl

rm -rf /etc/ppp/ip-up
cp ip-up /etc/ppp/
rm -rf /etc/ppp/ip-down
cp ip-down /etc/ppp/


cp webmin.acl /etc/usermin/

grep "gotomodule=commands" /etc/usermin/config &> /dev/null
if test $? -ne 0; then
tmpf=`gettmpfile`
grep -v gotomodule /etc/usermin/config > $tmpf
echo "gotomodule=commands" >> $tmpf
cat $tmpf > /etc/usermin/config
rm -rf $tmpf
fi

sh /etc/webmin/stop 2> /dev/null
sh /etc/webmin/start
checkerr
sh /etc/usermin/stop  2> /dev/null
sh /etc/usermin/start
checkerr


if test -d /etc/openvpn/; then
tar_backup=/etc/openvpn_`date +%Y-%m-%d_%H-%M`.tar
tar -cf $tar_backup /etc/openvpn/
rm -rf /etc/openvpn/
rm -rf /etc/ppp/chap-secrets
fi


if test -d /etc/openvpn/; then
tar_backup=/etc/openvpn_`date +%Y-%m-%d_%H-%M`.tar
tar -cf $tar_backup /etc/openvpn/
rm -rf /etc/openvpn/
fi


mkdir -p /etc/openvpn/keys/
mkdir -p /etc/openvpn_backup/
mv $tar_backup /etc/openvpn_backup/

rm -rf /var/www/ovpn/ &> /dev/null

mkdir -p /var/www/ovpn/

touch /etc/openvpn/index.txt
echo 01 > /etc/openvpn/serial




if ! test -s /var/spool/cron/crontabs/root; then
mkdir -p /var/spool/cron/crontabs/
echo "1 0 * * * sh /root/vpnplatform/kill-expired.sh" >> /var/spool/cron/crontabs/root
echo "@reboot /etc/init.d/iptables restart"  >> /var/spool/cron/crontabs/root

else
grep /root/vpnplatform/kill-expired.sh /var/spool/cron/crontabs/root &> /dev/null
if test $? -ne 0; then
echo "1 0 * * * sh /root/vpnplatform/kill-expired.sh" >> /var/spool/cron/crontabs/root
echo "@reboot /etc/init.d/iptables restart"  >> /var/spool/cron/crontabs/root

fi
fi

#sh setupvpn.sh
chmod +x /root/vpnplatform/.*

 . /root/vpnplatform/.city
 . /root/vpnplatform/.country
 . /root/vpnplatform/.email
 . /root/vpnplatform/.myorg
 . /root/vpnplatform/.province


#cd /root/vpnplatform/1.0/
cp -ru vpnplatform/* /root/vpnplatform/
. /root/vpnplatform/scripts/vars-2011 
if ! test -s /etc/openvpn/dh1024.pem; then
sh /root/vpnplatform/1.0/build-dh
checkerr
fi
. /root/vpnplatform/.myorg
export commonName="$KEY_ORG"
export CN="$commonName-server"
. /root/vpnplatform/.email
if ! test -s /etc/openvpn/ca.crt; then
sh /root/vpnplatform/1.0/build-ca
checkerr
fi
if ! test -s /etc/openvpn/"$KEY_ORG".crt; then
sh /root/vpnplatform/1.0/build-key-server "$KEY_ORG"
checkerr
fi
if ! test -s /etc/openvpn/crl-list.pem; then
sh /root/vpnplatform/1.0/make-crl /etc/openvpn/crl-list.pem
checkerr
fi
mkdir -p /etc/openvpn/ccd-tcp
mkdir -p /etc/openvpn/ccd-udp
if ! test -s /etc/openvpn/ta.key; then
openvpn --genkey --secret /etc/openvpn/ta.key
fi


/etc/init.d/openvpn restart
echo $mainip > /root/vpnplatform/.mainip
checkerr

echo "remote $mainip 443" >> /root/vpnplatform/scripts/tcp.ovpn
echo "remote $mainip 1194" >> /root/vpnplatform/scripts/udp.ovpn
checkerr
cp tcp.conf /etc/openvpn/
cp udp.conf /etc/openvpn/
cp logTraffic.sh  /etc/openvpn/
chmod +x /etc/openvpn/logTraffic.sh
echo "local $mainip" >> /etc/openvpn/tcp.conf
echo "local $mainip" >>	/etc/openvpn/udp.conf
checkerr
 . /root/vpnplatform/.city
 . /root/vpnplatform/.country
 . /root/vpnplatform/.email
 . /root/vpnplatform/.myorg
 . /root/vpnplatform/.province
checkerr

echo "cert $KEY_ORG.crt" >> /etc/openvpn/tcp.conf
echo "cert $KEY_ORG.crt" >> /etc/openvpn/udp.conf

echo "key $KEY_ORG.key" >> /etc/openvpn/tcp.conf
echo "key $KEY_ORG.key" >> /etc/openvpn/udp.conf






PASWD=`apg -m 7 -x 10 -n 1 -M LN`

today=`date +%Y-%m-%d`

expY=`echo $today | awk -F- '{print $1}'`
expM=`echo $today | awk -F- '{print $2}'`
expD=`echo $today | awk -F- '{print $3}'`
expM=$(expr $expM + 1)

expDate=`echo $expY-$expM-$expD`

#for cl in `seq 1 5`
sh /root/vpnplatform/scripts/new-client demo $KEY_EMAIL  $expDate $PASWD
checkerr

echo $mainip > /root/vpnplatform/.mainip


cp iptables-init /etc/init.d/iptables
chmod +x /etc/init.d/iptables
/etc/init.d/iptables stop  2> /dev/null
rm -fr /etc/network/iptables
cp iptables /etc/network/iptables

if test $extface != eth0; then
sed -i 's/eth0/'$extface'/g' /etc/network/iptables
fi

/etc/init.d/iptables start

iptables-save | grep POSTROUTING	&> /dev/null
checkerr

iptables-save | grep 1194 &> /dev/null
checkerr


sed -i 's/net.ipv4.ip_forward\ \=\ 0/net.ipv4.ip_forward\ \=\ 1/g' /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

grep net.ipv4.ip_forward /etc/sysctl.conf | grep -v '#' &> /dev/null
if test $? -ne 0; then
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi
service openvpn restart

clear

echo "Congratulations, your installation of VPN-Platform is ready,"
echo "you may login to your service using root user at URL : https://$mainip:20000 to manage the users"
echo "you may also download a demo user at package for OpenVPN at : http://$mainip/demo/demo.7z the archive file is protected using the same password of the user account"
echo "Please instruct your users to download p7zip package from http://www.7-zip.org/download.html"
echo "or by apt-get install p7zip"
echo " "
echo "your demo user account details as follows:"
echo "username: demo"
echo "password is $PASWD"
echo " "
echo "You may also connect to PPTP service with the following details:"
echo "Server IP : $mainip"
echo "username: demo"
echo "password: $PASWD"
echo " "
echo " "
echo "Note: The demo account will work for 1 month only, you may create others for your use."
echo " "
echo "Thank you for using VPN Platform, please feel free to post bugs, support requests at the mailing list http://mail.vpnplatform.org/mailman/listinfo/general_vpnplatform.org"
echo "You can find installation log at : $log_ins"
echo " "
echo "On behalf of the VPN Platform we invite you to participate in the project and grow it for the better of the community!"
echo "Best Regards"
# deleting downlaoded DEBs
rm -rf *.deb &> /dev/null
