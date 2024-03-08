import csv

def sort_csv(file_path, column, output_file_path):
    """
    Sorts a CSV file based on a given column number.

    :param file_path: Path to the input CSV file.
    :param column: The column number to sort the data by.
    :param output_file_path: Path to the output sorted CSV file.
    """
    try:
        with open(file_path, mode='r', newline='', encoding='utf-8') as csvfile:
            # Reading the CSV file and converting it to a list of dictionaries
            reader = csv.DictReader(csvfile)
            sorted_list = sorted(reader, key=lambda row: row[reader.fieldnames[column]])

        with open(output_file_path, mode='w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=reader.fieldnames)
            writer.writeheader()
            for row in sorted_list:
                writer.writerow(row)
                
        print(f"CSV file has been sorted based on column number {column} and saved to {output_file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
file_path = 'yourfile.csv'
column_to_sort_by = 2  # Column number you want to sort by
output_file_path = 'sorted_file.csv'
sort_csv(file_path, column_to_sort_by, output_file_path)
