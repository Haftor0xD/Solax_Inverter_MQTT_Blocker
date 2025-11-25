# podivat se na certose, proc mi to jde na kali, ale tady ne

# Solax MQTT Filter - MITM Proxy

A Man-in-the-Middle (MITM) proxy for Solax inverters that filters and controls MQTT communication between your Solax inverter and the Solax cloud.

## Table of Contents
- [Motivation](#motivation)
- [Solution](#solution)
- [How It Works](#how-it-works)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Supported Devices](#supported-devices)
- [Troubleshooting](#troubleshooting)
- [Disclaimer](#disclaimer)

## Motivation

Solax inverters can be controlled remotely from the cloud. There are concerns that in case of cloud compromise or directives from the Chinese government, unwanted manipulation of inverters could occur, potentially leading to:
- Disruption of electricity supply
- Damage to equipment
- Security vulnerabilities

Therefore, it's essential to have the ability to:
- Monitor communication between the inverter and Solax cloud
- Filter unwanted commands from the cloud
- Maintain statistics and overview functionality

## Solution

This project implements a MITM (Man-in-the-Middle) proxy that:
1. Intercepts traffic from Pocket WiFi 3.0 (configured via default gateway)
2. Listens on port 8080 and redirects traffic from port 8883 (MQTT over TLS)
3. Uses a Python script (`mqtt_filter_prefix.py`) to filter specific MQTT publish messages
4. By default, blocks messages that have been observed to actively change inverter settings from the cloud

## How It Works

```
[Solax Inverter] ←→ [Pocket WiFi 3.0] ←→ [MITM Proxy:8080] ←→ [Solax Cloud]
                         (gateway)              ↓
                                         [MQTT Filter]
                                    (blocks unwanted commands)
```

The proxy uses:
- **iptables** to redirect port 8883 → 8080
- **mitmproxy** in transparent mode to intercept MQTT traffic
- **mqtt_filter_prefix.py** to parse and filter MQTT PUBLISH messages

### Filtered Topics

**From Client (Inverter):**
- `base/bup` - Blocks configuration updates from inverter to cloud

**From Server (Cloud):**
- `base/bdown` - Blocks configuration downloads from cloud to inverter (active setting changes)

## Requirements

- Linux-based system (tested on Ubuntu/Debian)
- Python 3.7+
- mitmproxy
- iptables
- Root/sudo access

## Installation

1. **Install Python and mitmproxy:**
```bash
# Update package list
sudo apt-get update

# Install Python 3 and pip
sudo apt-get install -y python3 python3-pip

# Install mitmproxy
sudo pip3 install mitmproxy
```

2. **Clone the repository:**
```bash
git clone https://github.com/yourusername/Solax_mqtt_filter.git
cd Solax_mqtt_filter
```

3. **Make scripts executable:**
```bash
chmod +x start-mitm-proxy.sh
chmod +x stop-mitm-proxy.sh
```

4. **Configure your network:**
   - Set the machine running this proxy as the default gateway on your Pocket WiFi 3.0
   - Ensure the proxy machine can route traffic to the internet

## Configuration

### Filtering Rules

Edit `mqtt_filter_prefix.py` to customize which MQTT topics to block:

```python
# Block messages FROM CLIENT (inverter → cloud)
BLOCK_PREFIXES_CLIENT = [
    "base/bup",
    # Add more prefixes here
]

# Block messages FROM SERVER (cloud → inverter)
BLOCK_PREFIXES_SERVER = [
    "base/bdown",
    # Add more prefixes here
]
```

### Network Configuration

**On Pocket WiFi 3.0:**
1. Log in to the web interface
2. Navigate to Network Settings
3. Set the default gateway to the IP address of the machine running this proxy
4. Ensure DNS servers are configured (e.g., 8.8.8.8, 1.1.1.1)

**On the Proxy Machine:**
- The script automatically configures IP forwarding and iptables rules
- Traffic on port 8883 is redirected to port 8080 where mitmproxy listens

### Network Interface

By default, the scripts use `eth0`. If your network interface has a different name:

Edit `start-mitm-proxy.sh`:
```bash
# Change eth0 to your interface name (e.g., enp0s3, wlan0)
sudo iptables -t nat -A PREROUTING -i YOUR_INTERFACE -p tcp --dport 8883 -j REDIRECT --to-port 8080
sudo iptables -t nat -A POSTROUTING -o YOUR_INTERFACE -j MASQUERADE
```

## Usage

### Starting the Proxy

```bash
sudo ./start-mitm-proxy.sh
```

The proxy will start and display filtered MQTT messages in the console.

### Stopping the Proxy

```bash
sudo ./stop-mitm-proxy.sh
```

### Monitoring Traffic

To enable the web interface for monitoring:

1. Edit `start-mitm-proxy.sh` and uncomment the line:
```bash
sudo mitmweb --mode transparent --showhost --listen-port 8080 --web-host 0.0.0.0 -s mqtt_filter_prefix.py --ssl-insecure -set tls_version_server_min=TLS1
```

2. Access the web interface at `http://YOUR_IP:8081`

### Logs

- Logs are displayed in the terminal where you ran `start-mitm-proxy.sh`
- You'll see messages like:
  - `MQTT PUBLISH CLIENT → SERVER, topic=base/status`
  - `*** BLOCK SERVER PUBLISH topic=base/bdown ***`

## Supported Devices

### Tested Configuration
- **Device:** Pocket WiFi 3.0
- **Firmware:** Version 3.005.01
- **Download:** [Pocket WiFi 3.0 Firmware](https://app.box.com/s/3nvo7ic523fhojf8uuto105q9a8dgk9n/folder/145866811000)

## Troubleshooting

### Traffic Not Being Intercepted

1. Verify IP forwarding is enabled:
```bash
cat /proc/sys/net/ipv4/ip_forward
# Should return: 1
```

2. Check iptables rules:
```bash
sudo iptables -t nat -L -n -v
```

3. Verify mitmproxy is listening:
```bash
sudo netstat -tlnp | grep 8080
```

### SSL/TLS Certificate Errors

The proxy operates in transparent mode and should handle SSL/TLS automatically. If you encounter certificate issues:
- Ensure `--ssl-insecure` flag is used in mitmweb mode
- Ensure `--set tls_version_server_min=TLS1` flag is set as solax cloud uses obsolete TLS parameters
- The Pocket WiFi device should trust the connection

### No Messages Being Logged

1. Verify the Pocket WiFi default gateway is correctly set
2. Check that port 8883 traffic is being generated (test by accessing Solax cloud portal)
3. Increase logging verbosity by adding `-v` flag to mitmdump/mitmweb

## Disclaimer

**IMPORTANT NOTICE:**

This code is provided as-is and is freely available for anyone to use and modify.

**THE AUTHOR ACCEPTS NO RESPONSIBILITY OR LIABILITY FOR:**
- Use of this code in its current form
- Use of any modifications or derivatives of this code
- Any damages, direct or indirect, resulting from the use of this software
- Any disruption to service or equipment
- Any security vulnerabilities or issues arising from deployment

**USE AT YOUR OWN RISK**

By using this software, you acknowledge that:
- You understand the risks involved in intercepting network traffic
- You are responsible for compliance with all applicable laws and regulations
- You are responsible for the security and operation of your equipment
- The author provides no warranty, express or implied
- You will not hold the author liable for any consequences of using this software

This tool is intended for educational and research purposes to enhance personal security and control over your own equipment.

## License

This project is released into the public domain. Feel free to use, modify, and distribute as you see fit.

---

**Version:** 1.0.0
**Last Updated:** 2025-11-24
