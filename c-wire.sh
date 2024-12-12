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

# Checking passed arguments
check_arguments() {
    if [ $# -lt 3 ]; then # If the number of arguments is less than 3
        echo "Usage: $0 <file_csv> <type_station> <type_consumer> [id_central]"
        echo "Time : 0.0sec"
        exit 1
    fi
    if [ "$2" != "hva" ] && [ "$2" != "hvb" ] && [ "$2" != "lv" ]; then
        echo "Error: Station type must be 'hva' or 'hvb' or 'lv'."
        echo "Time : 0.0sec"
        exit 1
    fi
    if [ "$3" != "comp" ] && [ "$3" != "indiv" ] && [ "$3" != "all" ]; then
        echo "Error: Consumer type must be 'comp' or 'indiv' or 'all'."
        echo "Time : 0.0sec"
        exit 1
    fi
    if { [ "$2" == "hvb" ] || [ "$2" == "hva" ]; } && { [ "$3" == "all" ] || [ "$3" == "indiv" ]; }; then
        echo "Error: The following options are prohibited: hvb all, hvb indiv, hva all, hva indiv."
        echo "Time : 0.0sec"
        exit 1
    fi
    if ! [[ "$4" =~ ^[1-5]+$ ]] && [ -n "$4" ]; then
        echo "Error: The panel identifier must be a number between 1,2,3,4 and 5."
        echo "Time : 0.0sec"
        exit 1
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
        exit 1
    elif [ ! -s "$INPUT_FILE" ]; then # Checks if the specified file exists but is empty.
        echo "Error: File '$INPUT_FILE' is empty."
        exit 1 # Terminates the script with an error code `1`, signaling a critical error.
    fi # End of checks. If both conditions are met (the file exists and is not empty).
}

adjust_file_permissions "$INPUT_FILE"

# Creation of the necessary folders for the script and deletion
check_directories() {
    rm -rf "./tmp/"
    for directory in "tmp" "tests" "graphs"; do
        if [ ! -d "$directory" ]; then
            mkdir "$directory"
        fi
    done
}

# Checking the C program executable
executable_verification() {
    if [ ! -f ./CodeC/program ]; then # Checks if the `program` executable file does not exist in the `CodeC` directory.
        echo "Compilation in progress..."
        make -C CodeC || { echo "Compilation error"; exit 1; } # Run the `make` command in the `CodeC` directory to compile the program.
    fi # If the executable file already exists, no further action is taken.
}

 #PowerPlant;hvb;hva;LV;Company;Individual;Capacity;Load
 #[ "$a" = "$b" ] compare character strings

data_exploration() {
    # Construction of output file name
    echo "Data mining for station type : $STATION_TYPE"

    # Output file:
    OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.csv"

    # Special case where there is the ID of the control unit
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}${CONSUMER_TYPE}${CENTRAL_ID}.csv"
    fi

    # Adding the first line of the output file
    echo "${STATION_TYPE} Station ID:Capacity(kWh):Load ($CONSUMER_TYPE) (kWh)" > "$OUTPUT_FILE"

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
            'comp'|'indiv'|'all')
                grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"
                grep -E "$CENTRAL_ID;-;-;[^-]+;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
                if [ "$CONSUMER_TYPE" == "all" ]; then
                    grep -E "$CENTRAL_ID;-;-;[^-]+;-;[^-]+;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
                fi

                # Additional processing for lv all
                if [ "$CONSUMER_TYPE" == "all" ]; then
                    # File for the 10 stations with max and min consumption
                    MINMAX_FILE="tmp/lv_all_minmax.csv"
                    echo "Station ID;Capacity(kWh);Load (kWh)" > "$MINMAX_FILE"

                    # Extraction of the 10 minimum consumptions
                    tail -n +2 "$OUTPUT_FILE" | sort -t";" -k3,3n | head -n 10 >> "$MINMAX_FILE"

                    # Extraction of the 10 maximum consumptions
                    tail -n +2 "$OUTPUT_FILE" | sort -t";" -k3,3nr | head -n 10 >> "$MINMAX_FILE"

                    echo "File of 10 min and max positions generated : $MINMAX_FILE"
                fi
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


execute_program() {
    echo "Exécution du programme C..."
    start=$SECONDS
    ./CodeC/exec ./tmp/prod_data.csv ./tmp/cons_data.csv ./tmp/results.csv "$CONSUMER_TYPE" 

    if [[ $? -eq 0 ]]; then
        echo "Résultats sauvegardés dans tmp/results.csv"
        echo "$duration sec"
    else
        echo "Erreur lors de l'exécution du programme C"
        echo "$duration sec"
        exit 1
    fi
}


#Appel des fonctions
check_arguments "$@"
check_file
check_directories
# executable_verification
#execute_program
data_exploration
