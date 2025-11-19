#!/bin/sh

# uci to set up new openwrt routers 

while uci -q delete https-dns-proxy.@https-dns-proxy[0]; do :; done
uci batch <<EOF
set network.X=interface
set network.X.proto='mbim'
set network.X.device='/dev/cdc-wdm0'
set network.X.apn='vzwinternet'
set network.X.auth='none'
set network.X.pdptype='ipv4v6'
del firewall.cfg03dc81.network
add_list firewall.cfg03dc81.network='wan'
add_list firewall.cfg03dc81.network='wan6'
add_list firewall.cfg03dc81.network='X'
set https-dns-proxy.dns='https-dns-proxy'
set https-dns-proxy.dns.bootstrap_dns='94.140.14.49,94.140.14.59'
set https-dns-proxy.dns.resolver_url='https://d.adguard-dns.com/dns-query/f1935cc1'
set https-dns-proxy.dns.listen_addr='127.0.0.1'
set https-dns-proxy.dns.listen_port='5053'
add dhcp host # =cfg06fe63
set dhcp.@host[-1].name='AC68U'
add_list dhcp.@host[-1].mac='40:B0:76:AF:CD:30'
set dhcp.@host[-1].ip='192.168.1.2'
add dhcp host # =cfg07fe63
set dhcp.@host[-1].name='Fractal'
add_list dhcp.@host[-1].mac='A8:A1:59:9D:C6:CF'
set dhcp.@host[-1].ip='192.168.1.5'
set dhcp.lan.start='10'
set dhcp.lan.limit='250'
set dhcp.lan.leasetime='6h'
set dhcp.cfg01411c.sequential_ip='1'
EOF
uci commit network
uci commit dhcp
uci commit firewall
uci commit https-dns-proxy
/etc/init.d/network restart
/etc/init.d/dnsmasq restart
/etc/init.d/firewall restart
/etc/init.d/https-dns-proxy restart

mkdir /usr/share/nftables.d/chain-pre/mangle_postrouting/
echo "ip ttl set 66" > /usr/share/nftables.d/chain-pre/mangle_postrouting/01-set-ttl.nft
fw4 reload
