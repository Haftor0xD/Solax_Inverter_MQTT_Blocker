#!/bin/bash

# Terminate all running instances of mitmproxy/mitmdump
echo "Terminating running mitmproxy instances..."
sudo pkill -f "mitm(dump|proxy)"

# Remove iptables rules for port redirection
echo "Removing iptables rules..."
sudo iptables -t nat -D PREROUTING -i eth0 -p tcp --dport 8883 -j REDIRECT --to-port 8080 2>/dev/null
sudo iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null

# Disable IP forwarding (optional - depends on whether you want to keep IP forwarding active)
# echo "Disabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=0

# Check if processes were successfully terminated
if pgrep -f "mitm(dump|proxy)" > /dev/null; then
    echo "WARNING: Some mitmproxy instances are still running. Use 'sudo pkill -9 -f \"mitm(dump|proxy)\"' to force termination."
else
    echo "All mitmproxy instances have been successfully terminated."
fi

# Check if iptables rules were removed
if sudo iptables -t nat -C PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080 2>/dev/null; then
    echo "WARNING: Some iptables rules were not removed. Check manually with 'sudo iptables -t nat -L'."
else
    echo "All iptables rules have been removed."
fi

echo "MITM proxy has been stopped."
