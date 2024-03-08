from datetime import datetime
import re

# Function to try parsing the date using different formats
def parse_date(date_str):
    formats = [
        "%d/%m/%Y", "%m/%d/%Y", "%Y/%m/%d",
        "%B %d, %Y",  # 'January 31, 2020'
        "%b %d, %Y"   # 'Jan 31, 2020'
    ]
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt)
        except ValueError:
            continue
    return None  # Return None if all parse attempts fail

# Function to read, parse, and rewrite dates in a file
def convert_dates_in_file(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()
    
    with open(output_file, 'w') as f:
        for line in lines:
            # Find all date-like patterns in the line
            date_candidates = re.findall(r'\b(?:\d{1,2}/\d{1,2}/\d{4}|\d{4}/\d{1,2}/\d{1,2}|\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\b \d{1,2}, \d{4}|\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b \d{1,2}, \d{4})\b', line)
            for date_str in date_candidates:
                parsed_date = parse_date(date_str)
                if parsed_date:
                    # Replace the found date with its normalized version
                    line = line.replace(date_str, parsed_date.strftime('%Y-%m-%d'))
            f.write(line)

# Example usage
input_file_path = 'input.txt'  # The path to the input file
output_file_path = 'output.txt'  # The path to the output file

convert_dates_in_file(input_file_path, output_file_path)
