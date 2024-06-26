#!/command/with-contenv bash

[[ "${DEBUG,,}" == trace* ]] && set -x

echo "Firewall is up, everything has to go through the vpn"
iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
ip6tables -P OUTPUT DROP 2>/dev/null
ip6tables -P INPUT DROP 2>/dev/null
ip6tables -P FORWARD DROP 2>/dev/null
iptables -F
iptables -X
ip6tables -F 2>/dev/null
ip6tables -X 2>/dev/null

docker_network="$(ip -o addr show dev eth0 | awk '$3 == "inet" {print $4}')"
docker6_network="$(ip -o addr show dev eth0 | awk '$3 == "inet6" {print $4; exit}')"

echo "Enabling connection to secure interfaces"
if [[ -n ${docker_network} ]]; then
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -i lo -j ACCEPT
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -o tap+ -j ACCEPT
    iptables -A OUTPUT -o tun+ -j ACCEPT
    iptables -t nat -A POSTROUTING -o tap+ -j MASQUERADE
    iptables -t nat -A POSTROUTING -o tun+ -j MASQUERADE
fi
if [[ -n ${docker6_network} ]]; then
    ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A INPUT -p icmp -j ACCEPT
    ip6tables -A INPUT -i lo -j ACCEPT
    ip6tables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A FORWARD -p icmp -j ACCEPT
    ip6tables -A FORWARD -i lo -j ACCEPT
    ip6tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A OUTPUT -o lo -j ACCEPT
    ip6tables -A OUTPUT -o tap+ -j ACCEPT
    ip6tables -A OUTPUT -o tun+ -j ACCEPT
    ip6tables -t nat -A POSTROUTING -o tap+ -j MASQUERADE
    ip6tables -t nat -A POSTROUTING -o tun+ -j MASQUERADE
fi

echo "Enabling connection to nordvpn group"
if [[ -n ${docker_network} ]]; then
    iptables -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -m owner --gid-owner nordvpn -j ACCEPT || {
        echo "group match failed, fallback to open necessary ports"
        iptables -A OUTPUT -p udp -m udp --dport 1194 -j ACCEPT
        iptables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT
    }
fi
if [[ -n ${docker6_network} ]]; then
    ip6tables -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
    ip6tables -A OUTPUT -m owner --gid-owner nordvpn -j ACCEPT || {
        echo "ip6 group match failed, fallback to open necessary ports"
        ip6tables -A OUTPUT -p udp -m udp --dport 1194 -j ACCEPT
        ip6tables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT
    }
fi

exit 0
