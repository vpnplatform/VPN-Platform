# Copyright (C) 2012 VPN Platform Project
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#
# this shell script automates the installation process of pptp,openvpn, webmin & usermin
# for more information please visit http://vpnplatform.org or drop an email to the mailing list
# general@vpnplatform.org

#!/bin/sh

#Recognizing the system
if test -s myos; then
rm -rf myos
fi

perl oschooser.pl os_list.txt myos 1
rm -rf *.rpm

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
echo "error, charachtars count is not accurate, exiting ..."
exit 1
fi
}

rpmcheck()
{
rpm -q $1 | grep "not installed"
if test $? -eq 0; then
rpm -i $1*.rpm
checkerr
else
echo Package $1 already installed   &> /dev/null
fi
}

yumcheck()
{
rpm -q $1 | grep "not installed"
if test	$? -ne 1; then
yum -y install $1
checkerr
else
echo Package $1	already	installed   &> /dev/null
fi
}


checkval()
{
if test -z $1 ; then
echo "invalid value, please restart"
exit 1
fi
}


checkerr ()
{ 
if test $? -ne 0 ; then
echo error, function failed - exiting ..
exit 1
fi
} 

chkport ()
{
lsof -i :$1 | grep LISTEN &> /dev/null
if test $? -ne 1 &&  ! test -s /root/vpnplatform/.version; then
echo sorry, but the port $1 is already leased by other software, please get it freed and try again..
exit 1
fi
}


ver=`cat vpnplatform/.version`


echo "Welcome to VPN-Platform VPN installer Version $ver... Checking system .."
yum_os=`which yum`

modprobe ppp-compress-18
checkerr


for port in 20000 1194 1195 10000 53 1723 80
do
chkport $port 
done


modprobe tun
checkerr

if ! test -x $yum_os; then

echo "Not redhat-based system, exiting ..."

exit 1

else
echo "redhat-based system has been detected, proceeding with the installation"
echo "###################################################"
echo "### CAUTION ### CAUTION ### CAUTION ### CAUTION ###"
echo "THIS INSTALLATION SHOULD BE DONE ON A CLEAN NEW SYSTEM FOR TESTING PURPOSES."
echo "MANY SYSTEM FILES WILL BE ALTERED INCLUDING APACHE, NETWORK SETTINGS AND SO ON."
echo "KINDLY REFER TO THE install.sh FILE FOR MORE DETAILS WHAT THINGS WILL BE MODIFIED ON YOUR SYSTEM."
echo "CONTINUING HOLDS NO RESPOSIBILITY TOWARD VPN PLATFORM PROJECT OR ITS DEVELOPERS COMMUNITY."
echo "###################################################"
echo ""
echo "VPN PLATFORM DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL VPN PLATFORM BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE."

fi



/sbin/ifconfig | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' | grep -v "127.0.0.1"   &>  myips 
checkerr

ipscount=`wc -l myips  | awk '{ print $1}'`

if test $ipscount -gt 1; then
echo ""
echo ""
echo 'Please choose your external IP by entering the N) in front of the IP not the actual IP: '

select mainip in `cat myips`


do
  echo
  checkval $mainip
  echo "Your external IP is : $mainip"
  echo
  break  # What happens if there is no 'break' here?
done

else
mainip=`cat myips`

fi

if test -s /root/vpnplatform/.email -a -s /root/vpnplatform/.myorg -a -s /root/vpnplatform/.country  -a -s /root/vpnplatform/.province  -a -s /root/vpnplatform/.city; then
echo "found previous installation information using them for this installation"
echo "if you wish to use new information kindly delete the /root/vpnplatform/ folder"

 . /root/vpnplatform/.city
 . /root/vpnplatform/.country
 . /root/vpnplatform/.email
 . /root/vpnplatform/.myorg
 . /root/vpnplatform/.province

else

echo "Please provide the following information for the self-signed SSL certificate of OpenVPN to get generated using OpenSSL:"


read -p "Your Email : " myemail
checkval $myemail

read -p "Your City : " mycity
checkval $mycity

read -p "Your ISO Country code (2 letters), e.g. \"KW\" for Kuwait or \"US\" for USA: " mycountry
checkval $mycountry
checkwc $mycountry 3

read -p "Your Province : " myprovince
checkval $myprovince

read -p "Your Organization : " myorg
checkval $myorg

clear

if test -d /root/vpnplatform/scripts ; then

rm -rf /root/vpnplatform/scripts
fi

if test -d /root/vpnplatform/1.0 ; then
rm -rf /root/vpnplatform/1.0
fi


mkdir -p /root/vpnplatform/

cp -ru vpnplatform/* /root/vpnplatform/

checkerr

line=`grep -r $mainip /etc/sysconfig/network-scripts/`
checkerr
echo $line > /root/vpnplatform/.iface
checkerr
sed -i 's/\/etc\/sysconfig\/network-scripts\/ifcfg-//g' /root/vpnplatform/.iface
checkerr
extface=`cat /root/vpnplatform/.iface | cut -d: -f1`
checkerr

echo "Your information:"
echo "Country  	 		: $mycountry"
echo "Email			: $myemail"
echo "City			: $mycity"
echo "Province	 		: $myprovince"
echo "Organization		: $myorg"
echo "version			: $ver"
echo "main ip			: $mainip"
echo "external interface	: $extface"

echo ""
echo "Please note: the information above will be sent to VPN Platform development team of statistics purposes only"
echo "if you wish not to participate in these statistics please answer (no) below"

read -p "I accept to send the information to VPN Platform installation team (yes/NO)" Answer



echo export KEY_COUNTRY=\"$mycountry\" >> /root/vpnplatform/scripts/vars-2011
echo export KEY_PROVINCE=\"$myprovince\" >> /root/vpnplatform/scripts/vars-2011
echo export KEY_CITY=\"$mycity\" >> /root/vpnplatform/scripts/vars-2011
echo export KEY_ORG=\"$myorg\" >> /root/vpnplatform/scripts/vars-2011


echo export KEY_EMAIL=\"$myemail\" > /root/vpnplatform/.email
echo export KEY_COUNTRY=\"$mycountry\" > /root/vpnplatform/.country
echo export KEY_PROVINCE=\"$myprovince\" > /root/vpnplatform/.province
echo export KEY_CITY=\"$mycity\" > /root/vpnplatform/.city
echo export KEY_ORG=\"$myorg\" > /root/vpnplatform/.myorg




fi


 . /root/vpnplatform/.city
 . /root/vpnplatform/.country
 . /root/vpnplatform/.email
 . /root/vpnplatform/.myorg
 . /root/vpnplatform/.province

if ! test -d /root/vpnplatform/$KEY_ORG; then

cp -ru vpnplatform/empty /root/vpnplatform/$KEY_ORG

checkerr
fi

rm -rf /root/vpnplatform/scripts
cp -ru vpnplatform/scripts /root/vpnplatform/
checkerr


echo New client installation happend, with the following info : > /root/vpnplatform/message-body
echo client email  : $KEY_EMAIL >> /root/vpnplatform/message-body
echo version 	   : $ver	>> /root/vpnplatform/message-body
echo client country: $KEY_COUNTRY	>> /root/vpnplatform/message-body
echo client city   : $KEY_CITY	>> /root/vpnplatform/message-body
echo client main ip: $mainip	>> /root/vpnplatform/message-body
echo client extface: $extface	>> /root/vpnplatform/message-body
echo client org    : $KEY_ORG	>> /root/vpnplatform/message-body
echo client prov   : $KEY_PROVINCE	>> /root/vpnplatform/message-body



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

echo "disabling SELINUX and updating /etc/selinux/config file"
sleep 2
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

#2nd add repo and install

rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt &> /dev/null



cp webmin.repo /etc/yum.repos.d/ &> /dev/null

wget -c http://www.webmin.com/jcameron-key.asc &> /dev/null

rpm --import jcameron-key.asc &> /dev/null


arch=`uname -i`
echo $arch | grep x86_64 &> /dev/null
if test $? = 0 ;then
export os_arch=64
else
export os_arch=32
fi

grep real_os_version myos | grep 6 &> /dev/null
if test $? = 0  ;then
echo it is 6  &> /dev/null
if test $os_arch -eq 64; then
echo it is 64 bit  &> /dev/null
wget -c http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm &> /dev/null
checkerr
wget -c http://poptop.sourceforge.net/yum/stable/packages/pptpd-1.3.4-2.el6.x86_64.rpm
checkerr
#rpm -i rpmforge-release-0.5.2-2.el6.rf.*.rpm
rpmcheck rpmforge-release
#checkerr
fi




if test $os_arch -eq 32; then
echo it is 32 bit   &> /dev/null
wget -c http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.i686.rpm  &> /dev/null
checkerr
wget -c http://poptop.sourceforge.net/yum/stable/packages/pptpd-1.3.4-2.el6.i686.rpm
#rpm -i rpmforge-release-0.5.2-2.el6.rf.*.rpm
rpmcheck rpmforge-release

fi

export os_recognized=1
fi


if test $os_recognized -ne 1; then
echo "your os is not supported yet, exiting ..."
exit 1
fi



for pkg in webmin usermin perl-Crypt-CBC perl-Crypt-SSLeay perl-Net-SSLeay openvpn httpd apg dnsmasq p7zip p7zip-plugins ppp mailx redhat-lsb
do
yumcheck $pkg
done

rpmcheck pptpd

#plans to change it to yes/no question/answer in next release
echo "deleting /var/www/html and doing the required modifications for apache"
echo "hit ^C in the next 5 seconds if you wish to exit"
sleep 15

rm -rf /var/www/html
checkerr
ln -s /var/www/ovpn/ /var/www/html
checkerr
sed -i 's/AllowOverride\ None/AllowOverride\ All/g' /etc/httpd/conf/httpd.conf
mkdir -p /var/www/ovpn
linedel DocumentRoot /etc/httpd/conf/httpd.conf "DocumentRoot /var/www/ovpn"
checkerr

/etc/init.d/httpd restart

#plans to change it to yes/no question/answer in next release
echo "altering /etc/ppp and /etc/pptpd.conf , if you wish to exit hit ^C in the next 5 seconds"
sleep 15

grep "10.0.12.1" /etc/pptpd.conf &> /dev/null

if test $? -eq 1; then
echo "localip 10.0.12.1" >>  /etc/pptpd.conf
echo "remoteip 10.0.12.2-25" >>  /etc/pptpd.conf
fi

if test -s /etc/ppp/options.pptpd; then
rm -rf /etc/ppp/options.pptpd
fi
cp options.pptpd /etc/ppp/options.pptpd

/etc/init.d/pptpd stop && /etc/init.d/pptpd start

chkconfig pptpd on
chkconfig httpd on
chkconfig openvpn on
chkconfig usermin on
chkconfig dnsmasq on
/etc/init.d/dnsmasq restart

#plans to change it to yes/no question/answer in next release
echo "All prerequestes are ready, proceeding with webmin/usermin alteration in 5 seconds or hit ^C to cancel"
sleep 15

if test -d /etc/webmin/custom/; then
rm -rf /etc/webmin/custom/
fi

cp -ru custom/ /etc/webmin/

sed -i 's/ssl=0/ssl=1/g' /etc/webmin/miniserv.conf 
sed -i 's/ssl=0/ssl=1/g' /etc/usermin/miniserv.conf

rm -rf /etc/usermin/webmin.acl

cp webmin.acl /etc/usermin/

grep "gotomodule=commands" /etc/usermin/config &> /dev/null
if test $? -ne 0; then
tmpf=`gettmpfile`
grep -v gotomodule /etc/usermin/config > $tmpf
echo "gotomodule=commands" >> $tmpf
cat $tmpf > /etc/usermin/config
rm -rf $tmpf
fi

sh /etc/webmin/restart
checkerr
sh /etc/usermin/stop
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




if ! test -s /var/spool/cron/root; then
mkdir -p /var/spool/cron/
echo "installing the required cronjob scripts for killing expired accounts"
sleep 5
echo "1 0 * * * sh /root/vpnplatform/kill-expired.sh" >> /var/spool/cron/root
else
echo "installing the required cronjob scripts for killing expired accounts"
grep /root/vpnplatform/kill-expired.sh /var/spool/cron/root &> /dev/null
if test $? -ne 0; then
echo "1 0 * * * sh /root/vpnplatform/kill-expired.sh" >> /var/spool/cron/root
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
. /root/vpnplatform/scripts/vars-2011
if ! test -s /etc/openvpn/dh1024.pem; then
sh /root/vpnplatform/1.0/build-dh
fi
. /root/vpnplatform/.myorg
export commonName=$KEY_ORG
export CN=$commonName-server
. /root/vpnplatform/.email
if ! test -s /etc/openvpn/ca.crt; then
sh /root/vpnplatform/1.0/build-ca
fi
if ! test -s /etc/openvpn/$KEY_ORG.crt; then
sh /root/vpnplatform/1.0/build-key-server $KEY_ORG
fi
if ! test -s /etc/openvpn/crl-list.pem; then
sh /root/vpnplatform/1.0/make-crl /etc/openvpn/crl-list.pem
fi
mkdir -p /etc/openvpn/ccd-tcp
mkdir -p /etc/openvpn/ccd-udp
if ! test -s /etc/openvpn/ta.key; then
openvpn --genkey --secret /etc/openvpn/ta.key
fi


/etc/init.d/openvpn restart


echo "remote $mainip 1195" >> /root/vpnplatform/scripts/tcp.ovpn
echo "remote $mainip 1194" >> /root/vpnplatform/scripts/udp.ovpn

cp tcp.conf /etc/openvpn
cp udp.conf /etc/openvpn
echo "local $mainip" >> /etc/openvpn/tcp.conf
echo "local $mainip" >>	/etc/openvpn/udp.conf

 . /root/vpnplatform/.city
 . /root/vpnplatform/.country
 . /root/vpnplatform/.email
 . /root/vpnplatform/.myorg
 . /root/vpnplatform/.province


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
sh /root/vpnplatform/scripts/new-client demo $KEY_EMAIL $expDate $PASWD
checkerr

echo $mainip > /root/vpnplatform/.mainip
# updating iptables
echo "updating iptables config files, if you wish to exit hit ^C in the next 5 seconds"
sleep 15

/etc/init.d/iptables stop
cp -rp /etc/sysconfig/iptables /etc/sysconfig/iptables.vpnp
rm -fr /etc/sysconfig/iptables
cp iptables /etc/sysconfig/iptables

#line=`grep -r $mainip /etc/sysconfig/network-scripts/`
#echo $line > /root/vpnplatform/.iface
#sed -i 's/\/etc\/sysconfig\/network-scripts\/ifcfg-//g' /root/vpnplatform/.iface
#extface=`cat /root/vpnplatform/.iface | cut -d: -f1`
if test $extface != eth0; then
sed -i 's/eth0/'$extface'/g' /etc/sysconfig/iptables
fi



/etc/init.d/iptables start

iptables-save | grep POSTROUTING	&> /dev/null
checkerr

iptables-save | grep 1194 &> /dev/null
checkerr

# updating sysctl.conf
echo "enabling net.ipv4.ip_forward in /etc/sysctl.conf"
cp /etc/sysctl.conf /etc/sysctl.conf.vpnp
sed -i 's/net.ipv4.ip_forward\ \=\ 0/net.ipv4.ip_forward\ \=\ 1/g' /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

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
echo " "
echo "On behalf of the VPN Platform we invite you to participate in the project and grow it for the better of the community!"
echo "Best Regards"

# deleting downlaoded RPMs
rm -rf *.rpm &> /dev/null
