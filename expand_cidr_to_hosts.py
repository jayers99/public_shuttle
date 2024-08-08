import ipaddress
import os

def expand_cidr_to_hosts(file_path):
    """
    Reads a file containing IP addresses and CIDR blocks, expands CIDR blocks into individual host addresses,
    and writes the results to a new file with "_processed" appended to the original filename.
    
    Parameters:
    - file_path (str): The path to the input file containing IP addresses and CIDR blocks.
    """
    # Determine the output file path
    base, ext = os.path.splitext(file_path)
    output_file_path = f"{base}_processed{ext}"

    try:
        with open(file_path, 'r') as infile, open(output_file_path, 'w') as outfile:
            for line in infile:
                line = line.strip()
                if not line:
                    continue  # Skip empty lines
                try:
                    # Attempt to treat the line as a single IP address
                    ip = ipaddress.ip_address(line)
                    # Write the single IP address to the output file
                    outfile.write(f"{ip}\n")
                except ValueError:
                    try:
                        # Attempt to treat the line as a CIDR block
                        network = ipaddress.ip_network(line, strict=False)
                        # Expand and write each host address in the CIDR block
                        for ip in network.hosts():
                            outfile.write(f"{ip}\n")
                    except ValueError:
                        print(f"Invalid IP or CIDR block: {line}")
    except FileNotFoundError:
        print(f"File not found: {file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
input_file_path = 'ip_addresses.txt'  # Path to the input file
expand_cidr_to_hosts(input_file_path)
