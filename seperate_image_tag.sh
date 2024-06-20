awk -F, '{
    # Find the position of the last `/` in the second column
    last_slash_pos = match($2, /.*\//);
    # Find the position of the last `:` in the second column
    last_colon_pos = match($2, /.*:/);
    
    # Check if the last colon is after the last slash
    if (last_colon_pos > last_slash_pos) {
        # Replace the last colon with a comma
        sub(/:([^:]*)$/, ",\\1", $2);
    }
    # Print the modified line
    print $0;
}' OFS=, inputfile
