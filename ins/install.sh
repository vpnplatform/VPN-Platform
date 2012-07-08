#!/bin/bash
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



#Checking for root priviledge

id | grep "uid=0(" >/dev/null
if [ $? != "0" ]; then
        uname -a | grep -i CYGWIN >/dev/null
        if [ $? != "0" ]; then
                echo "ERROR: The VPN Portal install script must be run as root";
                echo "";
                exit 1;
        fi
fi



#removing development files while testing

if test -s devel.sh; then
sh devel.sh
fi

#defining functions and variables

checkerr()
{
if test $? -ne 0 ; then
echo error, function failed - exiting ..
exit 1
fi
} 

chkport()
{
lsof -i :$1 | grep LISTEN > /dev/null
if test $? -eq 0 &&  ! test -s /root/vpnplatform/.version; then
echo sorry, but the port $1 is already leased by other software, please get it freed and try again..
exit 1
fi
}

export ver=`cat vpnplatform/.version`
export ppid=`$$`

#
# Starting script
#
clear

echo Welcome to VPN-Portal VPN installer Version $ver... Checking system ..


#checking drivers status in the kernel
modprobe ppp-compress-18
checkerr

modprobe tun
checkerr

#Checking if needed ports is free

for port in 20000 1194 443 10000 53 1723 80
do
chkport $port 
done


#We should recognize the system type :

perl oschooser.pl os_list.txt myos 1
checkerr
chmod +x myos
checkerr
 . ./myos
checkerr

#displaying the legal notice

echo  -e '\E[1;33;44m'"                                                             "
echo "###################################################"
echo "### CAUTION ### CAUTION ### CAUTION ### CAUTION ###"
echo "THIS INSTALLATION SHOULD BE DONE ON A CLEAN NEW SYSTEM FOR TESTING PURPOSES."
echo "MANY SYSTEM FILES WILL BE ALTERED INCLUDING APACHE, NETWORK SETTINGS AND SO ON."
echo "KINDLY REFER TO THE install.sh FILE FOR MORE DETAILS WHAT THINGS WILL BE MODIFIED ON YOUR SYSTEM$
echo "CONTINUING HOLDS NO RESPOSIBILITY TOWARD VPN PLATFORM PROJECT OR ITS DEVELOPERS COMMUNITY."
echo "###################################################"
echo ""
echo "VPN PLATFORM DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRAN$
echo  -en '\E[47;31m'"Please press enter to continue, or ctrl + c to exit"; tput sgr0
read -ers
checkerr
printf \\n
clear

echo "                             "
mkdir -p /root/vpnplatform/
clear

#redirecting installer to the right direction :

export log_ins="/root/vpnp-`date +%Y-%m-%d_%H-%M`.log"

if test "$os_type" = "redhat-linux"; then

echo redhat-based system detected, installing packages... &> /dev/null
echo "                             "

sh install-rh.sh | tee $log_ins
checkerr
exit 0
elif test "$os_type" = "debian-linux"; then
cd /bin/
rm -rf sh &> /dev/null
ln -s bash sh
cd $OLDPWD
echo debian-based system detected, installing packages...
echo "                             "

sh install-deb.sh  | tee $log_ins
checkerr
exit 
else
 echo No redhat-based system nor a debian-based one detected, $os_type is not supported yet, exiting ...
exit 1
fi

exit
