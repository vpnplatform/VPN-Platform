#!/bin/bash

ls /etc/openvpn/keys/*.crt | sed 's/.crt//g' | sed 's/\/etc\/openvpn\/keys\///g' | uniq
