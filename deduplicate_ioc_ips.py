#!/usr/bin/env python3

import csv
import sys
from datetime import datetime
import os

def import_csv(file_path):
    data = []

    # Read the CSV file
    with open(file_path, mode='r', newline='') as file:
        csv_reader = csv.DictReader(file)
        for row in csv_reader:
            data.append(row)
    
    return data

def deduplicate(data):
    deduplicated_data = {}
    
    for row in data:
        ip_address = row['ip_address']
        date = datetime.strptime(row['date'], '%Y-%m-%d')  # Assuming the date format is YYYY-MM-DD

        # If the IP address is not in the data or the current row has a later date, update the data
        if ip_address not in deduplicated_data or deduplicated_data[ip_address]['date'] < date:
            deduplicated_data[ip_address] = row
            deduplicated_data[ip_address]['date'] = date  # Store the date as a datetime object for comparison

    # Convert the 'date' field back to string format
    for row in deduplicated_data.values():
        row['date'] = row['date'].strftime('%Y-%m-%d')

    return list(deduplicated_data.values())

def write_csv(file_path, data):
    base, ext = os.path.splitext(file_path)
    new_file_path = f"{base}_clean{ext}"

    # Sort the data by date in ascending order
    data.sort(key=lambda row: datetime.strptime(row['date'], '%Y-%m-%d'))

    # Extract field names from the first row of data
    if data:
        fieldnames = list(data[0].keys())

    # Write the deduplicated and sorted data to a new CSV file
    with open(new_file_path, mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)

    print(f"Deduplicated data written to {new_file_path}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]
    data = import_csv(file_path)
    deduplicated_data = deduplicate(data)
    write_csv(file_path, deduplicated_data)

if __name__ == "__main__":
    main()
