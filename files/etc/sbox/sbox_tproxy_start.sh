#!/bin/sh

TPROXY_PORT=9898
PROXY_FWMARK=1
PROXY_ROUTE_TABLE=100


echo "$(date) Creating firewall..."
cat > /etc/nftables.d/99-singbox.nft << EOF
#!/usr/sbin/nft -f

add table inet sing-box

# Create new chain
add chain inet sing-box prerouting { type filter hook prerouting priority mangle; policy accept; }
add chain inet sing-box output { type route hook output priority mangle; policy accept; }

# Add rules
table inet sing-box {
    chain prerouting {
        meta nfproto ipv6 accept
        # Make sure DHCP is not filter by UDP 67/68
        udp dport { 67, 68 } accept comment "Allow DHCP traffic"
        # Make sure DNS and TProxy work
        meta l4proto { tcp, udp } th dport 53 tproxy to :$TPROXY_PORT accept comment "DNS Transparent Proxy"
        fib daddr type local meta l4proto { tcp, udp } th dport $TPROXY_PORT reject
        fib daddr type local accept
        # Bypass local Networks
        ip daddr { 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16 } accept
        # Bypass DNAT
        ct status dnat accept comment "Allow forwarded traffic"
        # Mark others to Tproxy
        meta l4proto { tcp, udp } tproxy to :$TPROXY_PORT meta mark set 0x1 accept
        meta l4proto { tcp, udp } th dport { 80, 443 } tproxy to :$TPROXY_PORT meta mark set 0x1 accept
    }

    chain output {
        meta nfproto ipv6 accept
        # Bypass marked traffic
        meta mark 0x1 accept
        # Make sure DNS work
        meta l4proto { tcp, udp } th dport 53 meta mark set 0x1 accept
        # Bypass local traffic
        ip daddr { 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16 } accept
        # Bypass DNAT
        ct status dnat accept comment "Allow forwarded traffic"
        # Mark others to Tproxy
        meta l4proto { tcp, udp } meta mark set 0x1 accept
    }
}
EOF

# Set privilege for nft
chmod 644 /etc/nftables.d/99-singbox.nft

# Apply firewall rules
if ! nft -f /etc/nftables.d/99-singbox.nft; then
    error_exit "Apply firewall failure"
fi

ip rule del table $PROXY_ROUTE_TABLE >/dev/null 2>&1
ip rule add fwmark $PROXY_FWMARK table $PROXY_ROUTE_TABLE

ip route flush table $PROXY_ROUTE_TABLE >/dev/null 2>&1
ip route add local default dev lo table $PROXY_ROUTE_TABLE


echo "$(date) Ready for sing-box"
