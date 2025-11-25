#!/bin/bash

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Configure iptables
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8883 -j REDIRECT --to-port 8080
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Start mitmproxy in transparent mode
sudo mitmdump --mode transparent --showhost --listen-port 8080 -s mqtt_filter_prefix.py --set tls_version_server_min=TLS1


# Start mitmproxy with web GUI
#sudo mitmweb --mode transparent --showhost --listen-port 8080 --web-host <CONTAINER_IP_ADDRESS> -s mqtt_filter_prefix.py --ssl-insecure --set tls_version_server_min=TLS1



