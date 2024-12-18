#!/bin/bash  
# Declares that the script should be interpreted with Bash.

# Help display
for arg in "$@"; do # Cycle through all arguments passed to the script. The "$@" variable contains the list of arguments.
    if [ "$arg" == "-h" ]; then # Checks if one of the arguments is "-h", which indicates that the user is requesting help.
        echo "Use: $0 <file_csv> <type_station> <type_consumer> [id_central]"
        echo "Description: This script allows you to process energy consumption data."
        echo "Settings:"
        echo "  <file_csv>         : Path to the CSV file containing the data."
        echo "  <type_station>     : Station type ('hva', 'hvb', 'lv')."
        echo "  <type_consumer>    : Consumer type ('comp', 'indiv', 'all')."
        echo "  [id_central]       : (Optional) Panel identifier (must be a number)."
        echo "Options:"
        echo "  -h                 : Show this help and quit."
        exit 0 # Terminates script execution after displaying help, as no further processing is necessary.
    fi
done # End of the loop which checks the passed arguments.

# Displaying the structure of the power plant
echo "                 ____________________________________________"
echo "                |                                            |"
echo "                |                 POWER PLANT                |"
echo "                |____________________________________________|"
echo "                                     |"
echo "                                     ▼"
echo "                                ┌─────────┐"
echo "                                │   HVB   │"
echo "                                └─────────┘"
echo "                                     |"
echo "                ┌────────────────────┴───────────────────┐"
echo "                ▼                                        ▼"
echo "        ┌───────────────┐                         ┌───────────────┐"
echo "        │     HVA       │                         │ HVB companies │"
echo "        └───────────────┘                         └───────────────┘"
echo "                 |"
echo "         ┌───────┴─────────────────────────────┐"
echo "         ▼                                     ▼"
echo "    ┌───────────────┐                  ┌───────────────┐"
echo "    │      LV       │                  │ HVA companies │"
echo "    └───────────────┘                  └───────────────┘"
echo "                |"                        
echo "                |"
echo "       ┌────────┴─────────┐"
echo "       ▼                  ▼"
echo "┌───────────────┐   ┌───────────────┐"
echo "│ LV individuals│   │ LV companies  │"
echo "└───────────────┘   └───────────────┘"

# Function to check and adjust file permissions
adjust_file_permissions() {
    if [ ! -x "$1" ] && [ -f "$1" ]; then # Checks if the file specified by `$1` does not have execute permission.
        echo "Adjusting execute permissions for the file: $1"
        chmod +x "$1" # Adds execute permission for the specified file to all users.
    fi
}

# Function to check the passed arguments
check_arguments() {
    if [ $# -lt 3 ]; then # If the number of arguments is less than 3
        echo "Use: $0 <file_csv> <type_station> <type_consumer> [id_central]"
        echo "Time: 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
    if [ "$2" != "hva" ] && [ "$2" != "hvb" ] && [ "$2" != "lv" ]; then # Checks if the second argument (station type) is neither "hva", "hvb", nor "lv".
        echo "Error: Station type must be 'hva', 'hvb', or 'lv'."
        echo "Time: 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
    if [ "$3" != "comp" ] && [ "$3" != "indiv" ] && [ "$3" != "all" ]; then # Checks if the third argument (consumer type) is neither "comp", "indiv", nor "all".
        echo "Error: Consumer type must be 'comp', 'indiv', or 'all'."
        echo "Time: 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
    if { [ "$2" == "hvb" ] || [ "$2" == "hva" ]; } && { [ "$3" == "all" ] || [ "$3" == "indiv" ]; }; then # Checks whether the station type is "hvb" or "hva", and whether the consumer type is "all" or "indiv".
        echo "Error: The following options are prohibited: hvb all, hvb indiv, hva all, hva indiv."
        echo "Time: 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
    if ! [[ "$4" =~ ^[1-5]+$ ]] && [ -n "$4" ]; then # Checks if the fourth argument is not a number between 1 and 5 (if this argument is provided).
        echo "Error: The panel identifier must be a number between 1, 2, 3, 4, and 5."
        echo "Time: 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
}

# Assigning arguments to variables
INPUT_FILE=$1 # Assigns the first argument passed to the script to the `INPUT_FILE` variable.
STATION_TYPE=$2 # Assigns the second argument passed to the script to the `STATION_TYPE` variable.
CONSUMER_TYPE=$3 # Assigns the third argument passed to the script to the `CONSUMER_TYPE` variable.
CENTRAL_ID=${4:-"[^-]+"} # Assign the fourth argument to the `CENTRAL_ID` variable if provided.

# Function to check if the CSV file exists and is not empty
check_file() {
    if [ ! -f "$INPUT_FILE" ]; then # Checks if the file specified by the `INPUT_FILE` variable does not exist.
        echo "Error: File '$INPUT_FILE' does not exist."
        exit 1 # Terminates the script with an error code `1`, signaling a critical error.
    elif [ ! -s "$INPUT_FILE" ]; then # Checks if the specified file exists but is empty.
        echo "Error: File '$INPUT_FILE' is empty."
        exit 1 # Terminates the script with an error code `1`, signaling a critical error.
    fi
}

# Function to create necessary directories
check_directories() {
    rm -rf "./tmp/" # Recursively delete the temporary directory `tmp` and all its contents, if they exist.
    for directory in "tmp" "tests" "graphs"; do # Loop through a list of necessary directories: `tmp`, `tests`, and `graphs`.
        if [ ! -d "$directory" ]; then # Checks if the `$directory` directory does not exist.
            mkdir "$directory" # Creates the `$directory` directory if it does not already exist.
        fi
    done # End of loop, all necessary directories are now in place.
}

# Function to check the C program executable
executable_verification() {
    if [ ! -f ./codeC/bin/exec ]; then # Checks if the `exec` executable file does not exist in the `codeC` directory.
        echo "Compilation in progress..."
        make -C codeC || { echo "Compilation error"; exit 1; } # Run the `make` command in the `codeC` directory to compile the program.
    fi
}

# Function to explore data
data_exploration() {
    echo -e "\n====== Sorting data ======"
    echo "Data mining for station type: $STATION_TYPE"
    echo "Data mining for consumer type: $CONSUMER_TYPE"
    OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.input.csv"

    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.input.csv"
        echo "Data mining for central ID: $CENTRAL_ID"
    fi

    case "$STATION_TYPE" in
    'hvb')
        grep -E "^$CENTRAL_ID;[^-]+;-;-;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f2,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"
        grep -E "^$CENTRAL_ID;[^-]+;-;-;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f2,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
        ;;
    'hva')
        grep -E "^$CENTRAL_ID;[^-]+;[^-]+;-;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f3,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"
        grep -E "^$CENTRAL_ID;-;[^-]+;-;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f3,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
        ;;
    'lv')
        case "$CONSUMER_TYPE" in
        'comp')
            grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"
            grep -E "$CENTRAL_ID;-;-;[^-]+;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
            ;;
        'indiv')
            grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"
            grep -E "$CENTRAL_ID;-;-;[^-]+;-;[^-]+;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
            ;;
        'all')
            grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"
            grep -E "$CENTRAL_ID;-;-;[^-]+;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
            grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"
            grep -E "$CENTRAL_ID;-;-;[^-]+;-;[^-]+;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
            ;;
        *) echo "Error: Invalid consumer type." && exit 1 ;;
        esac
        ;;
    *) echo "Error: Invalid station type." && exit 1 ;;
    esac

    sed -i 's/-/0/g' "$OUTPUT_FILE" # Replacing '-' with '0' in output file
    
    mv "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp"
    head -n 1 "${OUTPUT_FILE}.tmp" > "$OUTPUT_FILE" # Keep the header
    tail -n +2 "${OUTPUT_FILE}.tmp" | sort -t":" -k2,2n >> "$OUTPUT_FILE" # Sort by increasing capacity
    rm "${OUTPUT_FILE}.tmp"
}

# Function to execute the C program
execute_program(){
    echo -e "====== Program execution ======"
    
    if [ "$CENTRAL_ID" != "[^-]+" ]; then # Checks if a specific plant ID is provided.
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.input.csv" # The input file includes the station type, consumer type, and panel ID.
    else
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.input.csv" # The input file only includes the station type and consumer type.
    fi
    if [ ${CENTRAL_ID} = "[^-]+" ]; then
        ./codeC/progO/exec < "$OUTPUT_FILE" | sort -t ":" -k2n > "./tests/${STATION_TYPE}_${CONSUMER_TYPE}.csv" # Runs the C program with the specified input file (`OUTPUT_FILE`).
        sed -i "1i ${STATION_TYPE} Station ID:Capacity(kWh):Load (${CONSUMER_TYPE}) (kWh)" "./tests/${STATION_TYPE}_${CONSUMER_TYPE}.csv" # Adds a header line to the output CSV file to describe its contents.
    else
        (./codeC/progO/exec < "$OUTPUT_FILE") | sort -t ":" -k2n > "./tests/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv" # Sorts the output by the second column and saves to a plant-specific output file in `tests/`.
        sed -i "1i ${STATION_TYPE} Station ID:Capacity(kWh):Load (${CONSUMER_TYPE}) (kWh)" "./tests/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv" # Adds a descriptive header line to the output file.
    fi
    
    echo "C program executed successfully. Output file saved in tests/."
}

# Function to handle the case where CONSUMER_TYPE="all"
all_consumer_type() {
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        INPUT_FILE="tests/lv_all_${CENTRAL_ID}.csv"
    else
        INPUT_FILE="tests/lv_all.csv"
    fi

    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: The file $INPUT_FILE does not exist."
        exit 1
    fi

    echo "====== Processing 'all' consumer type ======"
    OUTPUT_FILE="tests/lv_all_minmax.csv"

    tail -n +2 "$INPUT_FILE" | sort -t ":" -k3 -nr > tmp/sorted_by_consumption.csv

    head -n 10 "tmp/sorted_by_consumption.csv" > tmp/selected.csv
    tail -n 10 "tmp/sorted_by_consumption.csv" >> tmp/selected.csv

    echo "Calculating and sorting surplus..."
    awk -F":" '{print $0 ":" ($3-$2)}' tmp/selected.csv | sort -t ":" -k4,4nr | cut -d":" -f1-3 > tmp/sorted_surplus.csv

    echo "${STATION_TYPE} Station ID:Capacity(kWh):Consumption(kWh)" > "$OUTPUT_FILE"
    cat tmp/sorted_surplus.csv >> "$OUTPUT_FILE"

    echo "Processing completed. Results saved in $OUTPUT_FILE."
}

# Function that measures and displays the execution time of a given command
measure_time() {
    local start_time=$(date +%s.%N) # Start time
    "$@"                           # Execute the command
    local status=$?                # Capture the command status
    local end_time=$(date +%s.%N)  # End time
    local duration=$(echo "$end_time - $start_time" | bc -l) # Calculate the duration with maximum precision
    local formatted_duration=$(printf "%.1f" $duration) # Format the duration with 1 decimal place

    echo -e "Processing time for $1: ${formatted_duration}sec \n"
}

# Main script execution
rm -f tests/*.csv # Clean previously generated test files
adjust_file_permissions "$0" # Call the `adjust_file_permissions` function to check and adjust the permissions of the script itself (`$0`)
check_arguments "$@" # Calls the `check_arguments` function to check the arguments passed to the script.
check_file # Calls the `check_file` function to verify that the specified input file exists and is not empty.
adjust_file_permissions "$INPUT_FILE" # Checks and adjusts the permissions of the input file (`$INPUT_FILE`) to ensure it is readable.
check_directories # Calls the `check_directories` function to check and create the necessary directories
executable_verification # Checks if the C compiled program exists. If this is not the case, the script starts compiling.
measure_time data_exploration # Measures the time taken to run the `data_exploration` function, which analyzes the data and generates the necessary files.
measure_time execute_program # Measures the time taken to execute the `execute_program` function, which launches the main program.
if [ "$CONSUMER_TYPE" = "all" ]; then # If consumer type is "all", perform an additional function to handle this specific case.
    measure_time all_consumer_type # Measures the time taken to execute the `all_consumer_type` function, which processes data for all consumers.
fi

rm -f tmp/*.csv # Clean temporary files
