import ipaddress

def extract_ips(input_string):
    # Split the input string by lines, handling both \n and \r\n
    lines = input_string.splitlines()
    result = []

    for line in lines:
        line = line.strip()  # Remove any leading/trailing whitespace
        if not line:  # Skip blank lines
            continue

        try:
            # Try to parse the line as an IPv4 network
            network = ipaddress.ip_network(line, strict=False)
            # Check if the network is a single address or a range
            if network.num_addresses > 1:
                # If it's a range, iterate over each host IP
                for ip in network.hosts():
                    result.append(str(ip))
            else:
                # If it's a single address, just add it to the result
                result.append(str(network.network_address))
        except ValueError as e:
            # Print an error message for lines that cause ValueError
            print(f"Invalid IP or CIDR notation: {line} ({e})")

    # Join the result list into a single string with newline separation
    return '\n'.join(result)

# Example usage:
input_data = """192.168.1.1

192.168.1.0/30
10.0.0.0/29\r

172.16.5.4
invalid_ip\r\n
300.300.300.300/24
"""

expanded_ips = extract_ips(input_data)
print(expanded_ips)


