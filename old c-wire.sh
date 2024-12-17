#!/bin/bash


echo "                 ____________________________________________"
echo "                |                                            |"
echo "                |                 CENTRALE                   |"
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
echo "        ┌────────┴─────────────────────────────┐"
echo "        ▼                                      ▼"
echo "   ┌───────────────┐                  ┌───────────────┐"
echo "   │      LV       │                  │ HVA companies │"
echo "   └───────────────┘                  └───────────────┘"
echo "                |"                        
echo "                |"
echo "       ┌────────┴─────────┐"
echo "       ▼                  ▼"
echo "┌───────────────┐   ┌───────────────┐"
echo "│ LV individuals│   │ LV companies  │"
echo "└───────────────┘   └───────────────┘"

#!/bin/bash # Declares that the script should be interpreted with Bash.

# Help display
for arg in "$@"; do # Cycle through all arguments passed to the script. The "$@" variable contains the list of arguments.
    if [ "$arg" == "-h" ]; then # Checks if one of the arguments is "-h", which indicates that the user is requesting help.
        echo "Use: $0 <file_csv> <type_station> <type_consumer> [id_central]"
        echo "Description: This script allows you to process energy consumption data."
        echo "Settings:"
        echo "  <file_csv>         : Path to the CSV file containing the data."
        echo "  <type_station>        : Station type ('hva', 'hvb', 'lv')."
        echo "  <type_consumer>   : Consumer type ('comp', 'indiv', 'all')."
        echo "  [id_central]         : (Optional) Panel identifier (must be a number)."
        echo "Options:"
        echo "  -h                    : Show this help and quit."
        exit 0 # Terminates script execution after displaying help, as no further processing is necessary.
    fi
done # End of the loop which checks the passed arguments.


# Function to check and adjust file permissions, the function takes an argument `$1`, which represents the path of the file to check.
adjust_file_permissions() {
    if [ ! -r "$1" ]; then # Checks if the file specified by `$1` does not have read permission.
        echo "Adjusting read permissions for the file : $1"
        chmod +r "$1" # Adds read permission for the specified file to all users.
    fi

    if [ ! -w "$1" ] && [ -f "$1" ]; then # Checks if the file specified by `$1` does not have write permission
        echo "Adjusting write permissions for the file : $1"
        chmod +w "$1" # Adds write permission for the specified file to all users.
    fi # If none of the above conditions are met, the function does nothing.
}

# Checking passed arguments. The function takes into account arguments passed to the script via `$#` and `$1`, `$2`, etc.
check_arguments() {
    if [ $# -lt 3 ]; then # If the number of arguments is less than 3
        echo "Usage: $0 <file_csv> <type_station> <type_consumer> [id_central]"
        echo "Time : 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
    if [ "$2" != "hva" ] && [ "$2" != "hvb" ] && [ "$2" != "lv" ]; then # Checks if the second argument (station type) is neither "hva", "hvb", nor "lv".
        echo "Error: Station type must be 'hva' or 'hvb' or 'lv'."
        echo "Time : 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
    if [ "$3" != "comp" ] && [ "$3" != "indiv" ] && [ "$3" != "all" ]; then # Checks if the third argument (consumer type) is neither "comp", "indiv", nor "all".
        echo "Error: Consumer type must be 'comp' or 'indiv' or 'all'."
        echo "Time : 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
    if { [ "$2" == "hvb" ] || [ "$2" == "hva" ]; } && { [ "$3" == "all" ] || [ "$3" == "indiv" ]; }; then # Checks whether the station type is "hvb" or "hva", and whether the consumer type is "all" or "indiv".
        echo "Error: The following options are prohibited: hvb all, hvb indiv, hva all, hva indiv."
        echo "Time : 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
    if ! [[ "$4" =~ ^[1-5]+$ ]] && [ -n "$4" ]; then # Checks if the fourth argument is not a number between 1 and 5 (if this argument is provided).
        echo "Error: The panel identifier must be a number between 1,2,3,4 and 5."
        echo "Time : 0.0sec"
        exit 1 # Exits the script with an error code `1`.
    fi
}

INPUT_FILE=$1 # Assigns the first argument passed to the script to the `INPUT_FILE` variable.
STATION_TYPE=$2 # Assigns the second argument passed to the script to the `STATION_TYPE` variable.
CONSUMER_TYPE=$3 # Assigns the third argument passed to the script to the `CONSUMER_TYPE` variable.
CENTRAL_ID=${4:-"[^-]+"} # Assign the fourth argument to the `CENTRAL_ID` variable if provided.

# Checking if the CSV file exists and is not empty
check_file() {
    if [ ! -f "$INPUT_FILE" ]; then # Checks if the file specified by the `INPUT_FILE` variable does not exist.
        echo "Error: File '$INPUT_FILE' does not exist."
        exit 1 # Terminates the script with an error code `1`, signaling a critical error.
    elif [ ! -s "$INPUT_FILE" ]; then # Checks if the specified file exists but is empty.
        echo "Error: File '$INPUT_FILE' is empty."
        exit 1 # Terminates the script with an error code `1`, signaling a critical error.
    fi # End of checks. If both conditions are met (the file exists and is not empty).
}

adjust_file_permissions "$INPUT_FILE"

# Creation of the necessary folders for the script and deletion
check_directories() {
    rm -rf "./tmp/" # Recursively delete the temporary directory `tmp` and all its contents, if they exist.
    for directory in "tmp" "tests" "graphs"; do # Boucle sur une liste de répertoires nécessaires : `tmp`, `tests`, et `graphs`.
        if [ ! -d "$directory" ]; then # Checks if the `$directory` directory does not exist.
            mkdir "$directory" # Creates the `$directory` directory if it does not already exist.
        fi # If the directory already exists, no further action is taken.
    done # End of loop, all necessary directories are now in place.
}

# Checking the C program executable
executable_verification() {
    if [ ! -f ./codeC/bin/exec ]; then # Checks if the `program` executable file does not exist in the `CodeC` directory.
        echo "Compilation in progress..."
        make -C codeC || { echo "Compilation error"; exit 1; } # Run the `make` command in the `CodeC` directory to compile the program.
    fi # If the executable file already exists, no further action is taken.
}

 #PowerPlant;hvb;hva;LV;Company;Individual;Capacity;Load
 #[ "$a" = "$b" ] compare character strings

data_exploration() {
    # Construction of output file name
    echo "Data mining for station type : $STATION_TYPE"

    # Output file:
    OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.input.csv"

    # Special case where there is the ID of the control unit
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.input.csv"
    fi

    # Adding the first line of the output file
    # echo "${STATION_TYPE} Station ID:Capacity(kWh):Load ($CONSUMER_TYPE) (kWh)" > "$OUTPUT_FILE"

    case "$STATION_TYPE" in
    'hvb')
        # Extracting capacities with a "-" as default value for consumption
        grep -E "^$CENTRAL_ID;[^-]+;-;-;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f2,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"

        # Extraction of consumption by replacing column 5 with a “-”
        grep -E "^$CENTRAL_ID;[^-]+;-;-;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f2,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
         
        ;;
        'hva')
    # Extracting capacities with a "-" as default value for consumption
    grep -E "^$CENTRAL_ID;[^-]+;[^-]+;-;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f3,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"

    # Extraction of consumption by replacing column 5 with a “-”
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
        # Ajouter les consommateurs 'comp'
        grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"
        grep -E "$CENTRAL_ID;-;-;[^-]+;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
        # Ajouter les consommateurs 'indiv'
        grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"
        grep -E "$CENTRAL_ID;-;-;[^-]+;-;[^-]+;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
        ;;
        *) echo "Error: Invalid consumer type." && exit 1 ;;
        esac
        ;;
    *) echo "Error: Invalid station type." && exit 1 ;;
    esac

    # Replacing '-' with '0' in output file
    sed -i 's/-/0/g' "$OUTPUT_FILE"
# Sorting rows by capacity (column 2)
    mv "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp"
    head -n 1 "${OUTPUT_FILE}.tmp" > "$OUTPUT_FILE" # Keep the header
    tail -n +2 "${OUTPUT_FILE}.tmp" | sort -t":" -k2,2n >> "$OUTPUT_FILE" # Sort by increasing capacity
    rm "${OUTPUT_FILE}.tmp"
}
#--------------------------------------------------------------------------------------------------------------#

   execute_program(){
    # Define OUTPUT_FILE for case CENTRAL_ID is present
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.input.csv"
    else
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.input.csv"
    fi

   # Running the program based on CENTRAL_ID
    if [ ${CENTRAL_ID} = "[^-]+" ]; then
        # Case without CENTRAL_ID with sorting
        ./codeC/progO/exec < "$OUTPUT_FILE" | sort -t ":" -k2n > "./tests/${STATION_TYPE}_${CONSUMER_TYPE}.csv"
        # Add header to output file
        sed -i "1i ${STATION_TYPE} Station ID:Capacity(kWh):Load (${CONSUMER_TYPE}) (kWh)" "./tests/${STATION_TYPE}_${CONSUMER_TYPE}.csv"
    else
        # Case with CENTRAL_ID
        (./codeC/progO/exec < "$OUTPUT_FILE") | sort -t ":" -k2n > "./tests/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv"
        # Add header to output file
        sed -i "1i ${STATION_TYPE} Station ID:Capacity(kWh):Load (${CONSUMER_TYPE}) (kWh)" "./tests/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv"
    fi
    

# Specific case for CONSUMER_TYPE="all"
if [ "$CONSUMER_TYPE" = "all" ]; then
    # Specify the full path of the actual file (in /tests/)
    INPUT_FILE="tests/lv_all.csv"

    # Checking that the input file exists
    if [ ! -f "$INPUT_FILE" ]; then
    echo "Erreur : Le fichier $INPUT_FILE n'existe pas."
    exit 1
    fi
    # File to store min/max results
    OUTPUT_FILE="tests/lv_all_minmax.csv"

    # Exclude header and sort by consumption (column 3)
    tail -n +2 "$INPUT_FILE" | sort -t ":" -k3 -n > sorted_by_consumption.csv

    # Recover the 10 lowest consumptions
    head -n 10 sorted_by_consumption.csv > min_consumption.csv

    # Recover the 10 highest consumptions
    tail -n 10 sorted_by_consumption.csv > max_consumption.csv

    # Add header in final file
    echo "Station ID:Capacity(kWh):Consumption(kWh)" > "$OUTPUT_FILE"

    # Concatenate the results into the final file
    cat min_consumption.csv >> "$OUTPUT_FILE"
    cat max_consumption.csv >> "$OUTPUT_FILE"

    # Clean temporary files
    rm sorted_by_consumption.csv min_consumption.csv max_consumption.csv

    echo "Processing completed. Results saved in $OUTPUT_FILE."
else
    echo "Specific treatment for CONSUMER_TYPE='$CONSUMER_TYPE' not implemented."
    exit 1
fi

echo "C program executed successfully."
}



# Calling functions
check_arguments "$@"
check_file
adjust_file_permissions "$INPUT_FILE"
check_directories
executable_verification
data_exploration
execute_program
