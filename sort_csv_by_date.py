import csv
from datetime import datetime

def sort_csv_by_date(input_file, output_file):
    # Read the CSV file
    with open(input_file, 'r') as csvfile:
        reader = csv.reader(csvfile)
        # Extract the header
        header = next(reader)
        # Sort the rows by the second column (index 1)
        sorted_rows = sorted(reader, key=lambda row: datetime.strptime(row[1], '%Y-%m-%d'))
    
    # Write the sorted data to a new CSV file
    with open(output_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        # Write the header
        writer.writerow(header)
        # Write the sorted rows
        writer.writerows(sorted_rows)

# Example usage
input_file = 'input.csv'
output_file = 'sorted_output.csv'
sort_csv_by_date(input_file, output_file)
