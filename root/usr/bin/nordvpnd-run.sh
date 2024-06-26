#!/command/with-contenv bash

[[ "${DEBUG,,}" == trace* ]] && set -x

authfile="/tmp/auth"
ovpnfile="/tmp/nordvpn.ovpn"

exec sg nordvpn -c "openvpn --config "$ovpnfile" --auth-user-pass "$authfile" --auth-nocache ${OPENVPN_OPTS}"
