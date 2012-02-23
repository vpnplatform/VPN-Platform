#!/bin/bash

# revoke a certificate, regenerate CRL,
# and verify revocation
sh /root/vpnplatform/scripts/vars-2011
CRL="crl-list.pem"
RT="revoke-test.pem"

if [ $# -ne 1 ]; then
    echo "usage: revoke-full <cert-name-base>";
    exit 1
fi


if ! test -s /etc/openvpn/keys/$1.crt; then
                echo "Error! this user is not exists .. exiting ...";
                exit 1
fi



export KEY_CONFIG=/root/vpnplatform/scripts/openssl3.cnf
export D=/root/vpnplatform/scripts
export KEY_DIR=/etc/openvpn/
export KEY_SIZE=1024
export cipher=RC2-40-CBC
export commonName=$1

 . /root/vpnplatform/.city
 . /root/vpnplatform/.country
 . /root/vpnplatform/.email
 . /root/vpnplatform/.myorg
 . /root/vpnplatform/.province


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

tmpf=`gettmpfile`
touch $tmpf
while read line1; do
line=`echo $line1 | cut -d" " -f1`
if test "$line" != "$1"; then
echo "$line1" >> $tmpf
fi
done < /etc/ppp/chap-secrets

cat $tmpf > /etc/ppp/chap-secrets



if [ "$KEY_DIR" ]; then
    cd "$KEY_DIR"
    rm -f "$RT"

    # set defaults
export KEY_CONFIG=/root/vpnplatform/scripts/openssl3.cnf



    # revoke key and generate a new CRL
    openssl ca -revoke "$1.crt" -config "$KEY_CONFIG"  

    # generate a new CRL -- try to be compatible with
    # intermediate PKIs
    openssl ca -gencrl   -out "$CRL" -config "$KEY_CONFIG"
    if [ -e export-ca.crt ]; then
	cat export-ca.crt "$CRL" >"$RT"
    else
	cat ca.crt "$CRL" >"$RT"
    fi
    
    # verify the revocation
    openssl verify -CAfile "$RT" -crl_check "$1.crt"  | sed 's/error 23 at 0 depth lookup/sucess/g'

else
    echo 'Please source the vars script first (i.e. "source ./vars")'
    echo 'Make sure you have edited it to reflect your configuration.'
fi

rm -rf $KEY_DIR/keys/$1*
rm -rf /var/www/ovpn/$1
echo `date +%Y-%m-%d_%H-%M` EDT : User $1 removed for being expired >> /root/vpnplatform/scripts/users-log
