#!/command/with-contenv bash

[[ "${DEBUG,,}" == trace* ]] && set -x

echo "Bypass requests to local network thru regular connection"

docker_network="$(ip -o addr show dev eth0 | awk '$3 == "inet" {print $4}')"
docker6_network="$(ip -o addr show dev eth0 | awk '$3 == "inet6" {print $4; exit}')"

if [[ -n ${docker_network} ]]; then
    iptables -A INPUT -s "${docker_network}" -j ACCEPT
    iptables -A FORWARD -d "${docker_network}" -j ACCEPT
    iptables -A FORWARD -s "${docker_network}" -j ACCEPT
    iptables -A OUTPUT -d "${docker_network}" -j ACCEPT
fi
if [[ -n ${docker6_network} ]]; then
    ip6tables -A INPUT -s "${docker6_network}" -j ACCEPT 2>/dev/null
    ip6tables -A FORWARD -d "${docker6_network}" -j ACCEPT 2>/dev/null
    ip6tables -A FORWARD -s "${docker6_network}" -j ACCEPT 2>/dev/null
    ip6tables -A OUTPUT -d "${docker6_network}" -j ACCEPT 2>/dev/null
fi

if [[ -n ${docker_network} && -n ${NETWORK} ]]; then
    gw=$(ip route | awk '/default/ {print $3}')
    for net in ${NETWORK//[;,]/ }; do
        echo "Enabling connection to network ${net}"
        ip route | grep -q "$net" || ip route add to "$net" via "$gw" dev eth0
        iptables -A INPUT -s "$net" -j ACCEPT
        iptables -A FORWARD -d "$net" -j ACCEPT
        iptables -A FORWARD -s "$net" -j ACCEPT
        iptables -A OUTPUT -d "$net" -j ACCEPT
    done
fi
if [[ -n ${docker6_network} && -n ${NETWORK6} ]]; then
    gw6=$(ip -6 route | awk '/default/{print $3}')
    for net6 in ${NETWORK6//[;,]/ }; do
        echo "Enabling connection to network ${net6}"
        ip -6 route | grep -q "$net6" || ip -6 route add to "$net6" via "$gw6" dev eth0
        ip6tables -A INPUT -s "$net6" -j ACCEPT
        ip6tables -A FORWARD -d "$net6" -j ACCEPT
        ip6tables -A FORWARD -s "$net6" -j ACCEPT
        ip6tables -A OUTPUT -d "$net6" -j ACCEPT
    done
fi

exit 0
