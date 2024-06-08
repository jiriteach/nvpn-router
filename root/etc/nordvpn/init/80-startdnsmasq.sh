#!/command/with-contenv bash

[[ "${DEBUG,,}" == trace* ]] && set -x

echo "Start dnsmasq"
dnsmasq

exit 0
