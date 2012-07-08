rm -rf *.rpm &> /dev/null
rm -rf *.deb &> /dev/null

/etc/init.d/usermin stop &> /dev/null
/etc/init.d/webmin stop &> /dev/null
/etc/init.d/apache2 stop &> /dev/null
/etc/init.d/httpd stop &> /dev/null
/etc/init.d/openvpn stop &> /dev/null
/etc/init.d/pptpd stop &> /dev/null
/etc/init.d/dnsmasq stop  &> /dev/null
