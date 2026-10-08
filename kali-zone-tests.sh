#!/bin/bash
# ABC Freight Forwarders - Zone access tests from Kali
# Kali acts as every zone by holding one IP per zone on eth1.
# Extra IPs are temporary: re-run the "ip addr add" lines after a reboot.

SERVER="http://192.168.56.1:8080"

# Zone IPs (.101 = Guest, assigned by DHCP)
sudo ip addr add 192.168.56.45/24 dev eth1   # Finance
sudo ip addr add 192.168.56.15/24 dev eth1   # IT Admin
sudo ip addr add 192.168.56.35/24 dev eth1   # Office
sudo ip addr add 192.168.56.55/24 dev eth1   # Warehouse

# Baseline scan (before rules)
# nmap -Pn 192.168.56.1

echo "Test 1 - Guest     (expect BLOCK)";  curl --max-time 5 --interface 192.168.56.101 $SERVER; echo
echo "Test 2 - Finance   (expect ALLOW)";  curl --max-time 5 --interface 192.168.56.45  $SERVER; echo
echo "Test 3 - IT Admin  (expect ALLOW)";  curl --max-time 5 --interface 192.168.56.15  $SERVER; echo
echo "Test 4 - Office    (expect BLOCK)";  curl --max-time 5 --interface 192.168.56.35  $SERVER; echo
echo "Test 5 - Warehouse (expect BLOCK)";  curl --max-time 5 --interface 192.168.56.55  $SERVER; echo
