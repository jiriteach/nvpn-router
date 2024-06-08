<img src="https://i.insider.com/64ca588995fe1f0019debe3a" width="150">

# NordVPN Router - Docker Container

Docker container designed to allow LAN devices to be routed through via an active NordVPN tunnel. This container acts as a gateway with DNS resolution via NordVPN. 
A NordVPN tunnel is established on container start-up based on specified environment variables. Uses OpenVPN to establish the NordVPN tunnel.

Based on the implementation from - https://github.com/azinchen/nordvpn⁠ - Thanks!

Can also be used to route other Docker containers through the NordVPN tunnel. See - https://github.com/azinchen/nordvpn for instructions.

## Status
[![GitHub latest version][github-latestversion]][github-releases]
[![GitHub last commit][github-lastcommit]][github-link]
[![GitHub build][github-build]][github-link]
[![Docker image size][dockerhub-size]][dockerhub-link]
[![Docker pulls][dockerhub-pulls]][dockerhub-link]
[![GitHub release date][github-releasedate]][github-link]

<!-- ## What is OpenVPN?

OpenVPN is an open-source software application that implements virtual private network (VPN) techniques for creating secure point-to-point or site-to-site connections in routed or bridged configurations and remote access facilities. It uses a custom security protocol that utilizes SSL/TLS for key exchange. It is capable of traversing network address translators (NATs) and firewalls. -->

## How do I use this image?

### Supported architectures

The image supports multiple architectures such as `amd64`, `x86`, `arm/v6`, `arm/v7` and `arm64`.

### Setup up the required Docker network

Setup a `macvlan` network in Docker which is bound to your ethernet or wlan device. A `macvlan` network allows the container to be bound to the LAN. 

```
sudo docker network create -d macvlan -o parent=[eth_device] --subnet 192.168.180.0/24 --gateway 192.168.180.1 --ip-range 192.168.180.10/31 nvpn_router_macvlan
```

`--subnet` is the LAN subnet.  
`--gateway` is the LAN gateway.  
`--ip-range` is an IP range within the LAN subnet that any containers connected to this network will use. This IP range needs to be outside of any existing DHCP ranges on the LAN.

### Starting the container using Docker Compose

```Dockerfile

version: "3"
services:
  vpn:
    image: jiriteach/nvpn-router:latest
    container_name: nvpn-router
    cap_add:
      - net_admin
    devices:
      - /dev/net/tun
    networks:
      nvpn_router_macvlan:
        ipv4_address: 192.168.180.10 
    #ports:
    #  - 8080:80
    environment:
      - USER=
      - PASS=
      - COUNTRY=United States
      - GROUP=Standard VPN servers
      - RANDOM_TOP=10
      - RECREATE_VPN_CRON=5 */3 * * *
      - NETWORK=192.168.180.0/24
      - OPENVPN_OPTS=--mute-replay-warnings
      - TZ=Pacific/Auckland      
    restart: unless-stopped

networks:
  nvpn_router_macvlan:
    external: true

```
`ipv4_address` is a static ip address within `--ip-range` specified when creating the Docker network for the container to use.

`USER=` is NordVPN service credential username for manual setups.
`PASS=` is NordVPN service credential password for manual setup.
These can be found on this page - https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/.

`NETWORK` is the LAN subnet where devices will be connecting from to the container.

### Checking the container is working as expected

Once the container is started, several checks can be run to ensure its working as expected -

* From the container check for connectivity - `ping 1.1.1.1`.

* From the container check for DNS resolution - `nslookup google.com`. Response should be from one of NordVPN's DNS servers - https://support.nordvpn.com/hc/en-us/articles/19587726859793-What-are-the-addresses-of-my-NordVPN-DNS-servers.

* From the container check that traffic is being routed via the country specified - `curl -L ipinfo.io`

### Setup LAN devices to route through the container

LAN devices can now be easily setup to route through the container. Set the `default gw` and `dns` of the device to point to the IP address of the container then run the same checks as above. The device should be routing through the container. Depedendant on LAN setup - the existing LAN DHCP could be setup to automatically provide the `default gw` and `dns` of the container.

## Additional configuration
  
### Filtering NordVPN servers

The container selects the NordVPN server randomly unless specific within the environment variables. The list of recommended servers can be filtered by setting `COUNTRY`, `GROUP` and/or `TECHNOLOGY` environment variables.

### Reconnect by cron

The container selects the NordVPN server and its configuration during startup and maintains a connection until stop. Selected server might be changed using cron via `RECREATE_VPN_CRON` environment variable.

As specifid above - the VPN connection will be reconnected in the 5th minute every 3 hours.

### Reconnect

By the fault the container will try to reconnect to the same server when disconnected, in order to reconnect to another recommended server automatically add env variable:

```bash
 - OPENVPN_OPTS=--pull-filter ignore "ping-restart" --ping-exit 180
```

## Reference - complete environment variables

* `COUNTRY`           - Use servers from countries in the list. Several countries can be selected using semicolon. Country can be defined by Country name, Code or ID.
* `GROUP`             - Use servers from specific group. Only one group can be selected. Group can be defined by Name, Identifier or ID.
* `TECHNOLOGY`        - User servers with specific technology supported. Only one technololgy can be selected. Technology can be defined by Name, Identifier or ID. NOTE: Only OpenVPN servers are supported by this container.
* `RANDOM_TOP`        - Place n servers from filtered list in random order. Useful with `RECREATE_VPN_CRON`.
* `RECREATE_VPN_CRON` - Set period of selecting new server in format for crontab file. Disabled by default.
* `CHECK_CONNECTION_CRON` - Set period of checking Internet connection in format for crontab file. Disabled by default.
* `CHECK_CONNECTION_URL` - Use list of URI for checking Internet connection.
* `CHECK_CONNECTION_ATTEMPTS` - Set number of attemps of checking. Default value is 5.
* `CHECK_CONNECTION_ATTEMPT_INTERVAL` - Set sleep timeouts between failed attepms. Default value is 10.
* `USER`              - NordVPN service credential username for manual setups.
* `PASS`              - NordVPN service credential password for manual setups.
* `WHITELIST`         - List of domains that are going to be accessible outside vpn.
* `NETWORK`           - CIDR network (192.168.1.0/24), add a route to allows replies once the VPN is up. Several networks can be added to route using semicolon.
* `NETWORK6`          - CIDR IPv6 network (fe00:d34d:b33f::/64), add a route to allows replies once the VPN is up. Several networks can be added to route using semicolon.
* `OPENVPN_OPTS`      - Used to pass extra parameters to openvpn.
* `DEBUG`             - info, trace or trace+. Set to 'trace' for troubleshooting, 'trace+' will log your User and Pass.

[dockerhub-badge]: https://img.shields.io/docker/pulls/jiriteach/nvpn-router?style=flat-square
[dockerhub-link]: https://hub.docker.com/repository/docker/jiriteach/nvpn-router
[dockerhub-pulls]: https://img.shields.io/docker/pulls/jiriteach/nvpn-router
[dockerhub-size]: https://img.shields.io/docker/image-size/jiriteach/nvpn-router/master
[github-lastcommit]: https://img.shields.io/github/last-commit/jiriteach/nvpn-router
[github-link]: https://github.com/jiriteach/nvpn-router
[github-issues]: https://github.com/jiriteach/nvpn-router/issues
[github-releases]: https://github.com/jiriteach/nvpn-router/releases
[github-build]: https://img.shields.io/github/actions/workflow/status/jiriteach/nvpn-router/deploy.yml?branch=master
[github-releasedate]: https://img.shields.io/github/release-date/jiriteach/nvpn-router
[github-latestversion]: https://img.shields.io/github/v/release/jiriteach/nvpn-router
[email-link]: mailto:jxs@s7n.dev