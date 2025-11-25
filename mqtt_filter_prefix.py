from mitmproxy import tcp
from mitmproxy import ctx

# Filtered prefixes
BLOCK_PREFIXES_CLIENT = [
    "base/bup",
]

BLOCK_PREFIXES_SERVER = [
    "base/bdown",
]

def decode_remaining_length(data, index):
    multiplier = 1
    value = 0
    while True:
        digit = data[index]
        value += (digit & 0x7F) * multiplier
        index += 1
        if (digit & 0x80) == 0:
            break
        multiplier *= 128
    return value, index

def parse_mqtt_publish(data: bytes):
    if len(data) < 4:
        return None

    first = data[0]
    # MQTT PUBLISH fixed header (0x30–0x3F)
    if not (first >> 4 == 0x3):
        return None

    # 2) Remaining Length
    rl, index = decode_remaining_length(data, 1)

    # 3) Variable Header – Topic length
    topic_len = (data[index] << 8) | data[index + 1]
    index += 2

    # 4) Topic string
    topic = data[index:index + topic_len].decode("utf-8", errors="replace")
    index += topic_len

    return topic


def tcp_message(flow: tcp.TCPFlow):
    
    msg = flow.messages[-1]
    topic = parse_mqtt_publish(msg.content)
    if topic is None:
        return

    # Determine message direction
    if msg.from_client:
        direction = "CLIENT → SERVER"
    else:
        direction = "SERVER → CLIENT"

    ctx.log.info(f"MQTT PUBLISH {direction}, topic={topic}")

    # --- FILTER CLIENT → SERVER ---
    if msg.from_client:
        for prefix in BLOCK_PREFIXES_CLIENT:
            if topic.startswith(prefix):
                ctx.log.info(f"*** BLOCK CLIENT PUBLISH topic={topic} ***")
                msg.content = b""
                return

    # --- FILTER SERVER → CLIENT ---
    if not msg.from_client:
        for prefix in BLOCK_PREFIXES_SERVER:
            if topic.startswith(prefix):
                ctx.log.info(f"*** BLOCK SERVER PUBLISH topic={topic} ***")
                msg.content = b""
                return
