set datafile separator ';'
output_directory = 'output/'.output_dir

files_glob = output_directory."/*.csv"

apps_directories = system("ls -1 ".files_glob)

set print

# Disables handling of the 1st row in the CSV file
set key autotitle columnhead

# Disables legend panel
unset key

# Boxes for right-part of the plot
    set boxwidth 0.8
    set style fill solid
