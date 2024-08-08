import ipaddress

def get_host_ips(cidr_block):
    """
    Returns a list of valid host IP addresses for a given CIDR block.
    
    Parameters:
    - cidr_block (str): The CIDR notation of the IP address block, e.g., '192.168.1.0/24'.
    
    Returns:
    - List[str]: A list of valid host IP addresses in the CIDR block.
    """
    try:
        # Create an IPv4 network object
        network = ipaddress.ip_network(cidr_block, strict=False)
        # Get the list of all valid host addresses
        host_ips = [str(ip) for ip in network.hosts()]
        return host_ips
    except ValueError as e:
        # Handle invalid CIDR block input
        print(f"Invalid CIDR block: {e}")
        return []

# Example usage
cidr_block = '192.168.1.0/24'
host_ips = get_host_ips(cidr_block)
print(f"Valid host IPs in {cidr_block}:")
print(host_ips)
