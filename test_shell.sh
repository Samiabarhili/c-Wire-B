#!/bin/bash  
# Declares that the script should be interpreted with Bash.

#Modif faites :
#- Chmod +x dans permission
#- ⁠measure_time (je remercie coco avec la collab de chacha pour ça), ya le temps de data exploration, execute program et celui de 
#all et jsp si c'est bien tout cela qu'il fallait prendre en compte ...
#- ⁠l’appel des fonctions + suppression des fichiers
#- ⁠all consumer type (jai transformé le 'if' en fonction) et j'ai apporté qlq modif … 
#- le code est fonctionnel ! encore qlq trucs à régler (faut des valeurs absolues pour le tri des surplus), revoir le lv min max.
#- jai pas pensé à tout mettre en anglais sorry...

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

#----------------------------------File permissions----------------------------------------------------------#

# Function to check and adjust file permissions, the function takes an argument `$1`, which represents the path of the file to check.
adjust_file_permissions() {
    if [ ! -r "$1" ]; then # Checks if the file specified by `$1` does not have read permission.
        echo "Adjusting read permissions for the file : $1"
        chmod +r "$1" # Adds read permission for the specified file to all users.
    fi

    if [ ! -w "$1" ] && [ -f "$1" ]; then # Checks if the file specified by `$1` does not have write permission.
        echo "Adjusting write permissions for the file : $1"
        chmod +w "$1" # Adds write permission for the specified file to all users.
    fi

    if [ ! -x "$1" ] && [ -f "$1" ]; then # Checks if the file specified by `$1` does not have execute permission.
        echo "Adjusting execute permissions for the file : $1"
        chmod +x "$1" # Adds execute permission for the specified file to all users.
    fi # If none of the above conditions are met, the function does nothing.
}

#----------------------------------Argument verification----------------------------------------------------------#

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

#----------------------------------File verification----------------------------------------------------------#

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


#----------------------------------Creation of the necessary folders-----------------------------------------#

# Creation of the necessary folders for the script and deletion
check_directories() {
    rm -rf "./tmp/" # Recursively delete the temporary directory `tmp` and all its contents, if they exist.
    for directory in "tmp" "tests" "graphs"; do # Boucle sur une liste de répertoires nécessaires : `tmp`, `tests`, et `graphs`.
        if [ ! -d "$directory" ]; then # Checks if the `$directory` directory does not exist.
            mkdir "$directory" # Creates the `$directory` directory if it does not already exist.
        fi # If the directory already exists, no further action is taken.
    done # End of loop, all necessary directories are now in place.
}



#----------------------------------Executable verification---------------------------------------------------#

# Checking the C program executable
executable_verification() {
    if [ ! -f ./codeC/bin/exec ]; then # Checks if the `program` executable file does not exist in the `CodeC` directory.
        echo "Compilation in progress..."
        make -C codeC || { echo "Compilation error"; exit 1; } # Run the `make` command in the `CodeC` directory to compile the program.
    fi # If the executable file already exists, no further action is taken.
}

 #PowerPlant;hvb;hva;LV;Company;Individual;Capacity;Load
 #[ "$a" = "$b" ] compare character strings



#----------------------------------Data exploration----------------------------------------------------------#

data_exploration() {
    echo -e "\n=== Sorting data ==="
    # Construction of output file name
    echo "Data mining for station type : $STATION_TYPE"
    echo "Data mining for consumer type : $CONSUMER_TYPE"
    # Output file:
    OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.input.csv"

    # Special case where there is the ID of the control unit
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.input.csv"
        echo "Data mining for central ID : $CENTRAL_ID"
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

#-----------------------------------------Program execution---------------------------------------------------------------#

# Function to execute the C program
execute_program(){
    echo -e "=== Program execution ==="
    
    # Définir OUTPUT_FILE pour le cas où CENTRAL_ID est présent
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.input.csv"
        
    else
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.input.csv"
    fi

    # Exécution du programme en fonction de CENTRAL_ID
    if [ ${CENTRAL_ID} = "[^-]+" ]; then
        # Cas sans CENTRAL_ID avec tri
        ./codeC/progO/exec < "$OUTPUT_FILE" | sort -t ":" -k2n > "./tests/${STATION_TYPE}_${CONSUMER_TYPE}.csv"
        # Ajouter l'entête au fichier de sortie
        sed -i "1i ${STATION_TYPE} Station ID:Capacity(kWh):Load (${CONSUMER_TYPE}) (kWh)" "./tests/${STATION_TYPE}_${CONSUMER_TYPE}.csv"
    else
        # Cas avec CENTRAL_ID
        (./codeC/progO/exec < "$OUTPUT_FILE") | sort -t ":" -k2n > "./tests/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv"
        # Ajouter l'entête au fichier de sortie
        sed -i "1i ${STATION_TYPE} Station ID:Capacity(kWh):Load (${CONSUMER_TYPE}) (kWh)" "./tests/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv"
    fi
    
    echo "Programme C exécuté avec succès. Fichier de sortie sauvegardé dans tests/."
    
   }

#------------------------------------Specific case for CONSUMER_TYPE="all"----------------------------------------------#

# Fonction pour traiter le cas où CONSUMER_TYPE="all"
all_consumer_type() {
    # Spécifier le chemin complet du fichier réel (dans /tests/)
    INPUT_FILE="tests/lv_all.csv"
    # Vérification que le fichier d'entrée existe
    if [ ! -f "$INPUT_FILE" ]; then
       echo "Erreur : Le fichier $INPUT_FILE n'existe pas."
       exit 1
    fi
    echo "=== Traitement du type 'all' ==="
    #Fichier pour stocker les résultats min/max
    OUTPUT_FILE="tests/lv_all_minmax.csv"

    #Exclure l'en-tête et trier par consommation totale (colonne 3) décroissante avec la commande 'nr'
    tail -n +2 "$INPUT_FILE" | sort -t ":" -k3 -nr > tmp/sorted_by_consumption.csv

    # Récupérer les 10 plus fortes consommations
    head -n 10 "tmp/sorted_by_consumption.csv" > tmp/selected.csv
    # Récupérer les 10 plus faibles consommations
    tail -n 10 "tmp/sorted_by_consumption.csv" >> tmp/selected.csv
    

    echo "Calcul et tri des surplus..."
    awk -F":" '{print $0 ":" ($3-$2)}' tmp/selected.csv | sort -t ":" -k4,4nr > tmp/sorted_surplus.csv
    
    echo "${STATION_TYPE} Station ID:Capacity(kWh):Consumption(kWh):Surplus(kWh)" > "$OUTPUT_FILE"
    cat tmp/sorted_surplus.csv >> "$OUTPUT_FILE"
    
    # Nettoyer le fichier temporaire  (pour les tests je retire les suppressions de fichiers mais faut remettre)
    # rm -f tmp/sorted_by_consumption.csv tmp/selected.csv tmp/sorted_surplus.csv
    echo "Traitement terminé. Résultats sauvegardés dans $OUTPUT_FILE."
}




#---------------------------------Time measurement---------------------------------------------------------------#

measure_time() {
       # echo "=== début de la mesure du temps pour $1 ==="
        local start_time=$(date +%s.%N) # Temps de début
        "$@"                           # Exécution de la commande
        local status=$?                # Capture du statut de la commande
        local end_time=$(date +%s.%N)  # Temps de fin
        local duration=$(printf "%.1f" "$(echo "$end_time - $start_time" | bc)") # Calcul de la durée avec 2 chiffres après la virgule

        echo -e "Durée de traitement pour $1 : ${duration}sec \n"
        return $status # Retourne le statut d'origine de la commande
    }


#---------------------------------Main---------------------------------------------------------------------------#

# Nettoyer les fichiers tests générés précédemment
rm -f tests/*.csv

# Appel des fonctions
check_arguments "$@"
check_file
adjust_file_permissions "$INPUT_FILE"
check_directories
executable_verification

measure_time data_exploration
measure_time execute_program
if [ "$CONSUMER_TYPE" = "all" ]; then
    measure_time all_consumer_type
fi

# Nettoyer uniquement les fichiers temporaires  (pour les tests je la retire mais faut la remettre)
#rm -f tmp/*.csv
