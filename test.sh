#!/bin/bash

# Affichage de l'aide
for arg in "$@"; do
    if [ "$arg" == "-h" ]; then
        echo "Usage: $0 <fichier_csv> <type_station> <type_consommateur> [id_centrale]"
        echo "Description: Ce script permet de traiter des données de consommation énergétique."
        echo "Paramètres:"
        echo "  <fichier_csv>         : Chemin vers le fichier CSV contenant les données."
        echo "  <type_station>        : Type de station ('hva', 'hvb', 'lv')."
        echo "  <type_consommateur>   : Type de consommateur ('comp', 'indiv', 'all')."
        echo "  [id_centrale]         : (Optionnel) Identifiant de la centrale (doit être un nombre)."
        echo "Options:"
        echo "  -h                    : Affiche cette aide et quitte."
        exit 0
    fi
done


# Fonction pour vérifier et ajuster les permissions du fichier
adjust_file_permissions() {
    if [ ! -r "$1" ]; then
        echo "Ajustement des permissions de lecture pour le fichier : $1"
        chmod +r "$1"
    fi

    if [ ! -w "$1" ] && [ -f "$1" ]; then
        echo "Ajustement des permissions d'écriture pour le fichier : $1"
        chmod +w "$1"
    fi
}

# Vérification des arguments passés
check_arguments() {
    if [ $# -lt 3 ]; then # Si le nombre d'arguments est inférieur à 3
        echo "Usage: $0 <fichier_csv> <type_station> <type_consommateur> [id_centrale]"
        echo "Time : 0.0sec"
        exit 1
    fi
    if [ "$2" != "hva" ] && [ "$2" != "hvb" ] && [ "$2" != "lv" ]; then
        echo "Erreur : Le type de station doit être 'hva' ou 'hvb' ou 'lv' ."
        echo "Time : 0.0sec"
        exit 1
    fi
    if [ "$3" != "comp" ] && [ "$3" != "indiv" ] && [ "$3" != "all" ]; then
        echo "Erreur : Le type de consommateur doit être 'comp' ou 'indiv' ou 'all'."
        echo "Time : 0.0sec"
        exit 1
    fi
    if { [ "$2" == "hvb" ] || [ "$2" == "hva" ]; } && { [ "$3" == "all" ] || [ "$3" == "indiv" ]; }; then
        echo "Erreur : Les options suivantes sont interdites : hvb all, hvb indiv, hva all, hva indiv."
        echo "Time : 0.0sec"
        exit 1
    fi
    if ! [[ "$4" =~ ^[1-5]+$ ]] && [ -n "$4" ]; then
        echo "Erreur : L'identifiant de la centrale doit être un nombre entre 1,2,3,4 et 5."
        echo "Time : 0.0sec"
        exit 1
    fi
}

INPUT_FILE=$1
STATION_TYPE=$2
CONSUMER_TYPE=$3
CENTRAL_ID=${4:-"[^-]+"}

# Vérification si le fichier CSV existe et n'est pas vide
check_file() {
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Erreur : Le fichier '$INPUT_FILE' n'existe pas."
        exit 1
    elif [ ! -s "$INPUT_FILE" ]; then
        echo "Erreur : Le fichier '$INPUT_FILE' est vide."
        exit 1
    fi
}

adjust_file_permissions "$INPUT_FILE"

# Création des dossiers nécessaires pour le script et suppresion
check_directories() {
    rm -rf "./tmp/"
    for directory in "tmp" "tests" "graphs"; do
        if [ ! -d "$directory" ]; then
            mkdir "$directory"
        fi
    done
}

# Vérification de l'exécutable du programme C
executable_verification() {
    if [ ! -f ./CodeC/program ]; then
        echo "Compilation en cours..."
        make -C CodeC || { echo "Erreur de compilation"; exit 1; }
    fi
}

 #PowerPlant;hvb;hva;LV;Company;Individual;Capacity;Load
 #[ "$a" = "$b" ] compare character strings

data_exploration() {
    # Construction du nom du fichier de sortie
    echo "Exploration des données pour le type de station : $STATION_TYPE"

    #fichier de sortie :
    OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.csv"

    #cas particulier où il y a l'ID de la centrale
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}${CONSUMER_TYPE}${CENTRAL_ID}.csv"
    fi

    #ajout de la première ligne du fichier de sortie
    echo "${STATION_TYPE} Station ID:Capacity(kWh):Load ($CONSUMER_TYPE) (kWh)" > "$OUTPUT_FILE"

    case "$STATION_TYPE" in
    'hvb')
        # Extraction des capacités avec un "-" comme valeur par défaut pour consommation
        grep -E "^$CENTRAL_ID;[^-]+;-;-;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f2,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"

        # Extraction des consommations en remplaçant la colonne 5 par un "-"
        grep -E "^$CENTRAL_ID;[^-]+;-;-;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f2,8 | awk -F";" '{print $1":-:"$2}' >> "$OUTPUT_FILE"
         
        ;;
        'hva')
    # Extraction des capacités avec un "-" comme valeur par défaut pour consommation
    grep -E "^$CENTRAL_ID;[^-]+;[^-]+;-;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f3,7 | awk -F";" '{print $1":"$2":-"}' >> "$OUTPUT_FILE"

    # Extraction des consommations en remplaçant la colonne 5 par un "-"
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

                # Traitement supplémentaire pour lv all
                if [ "$CONSUMER_TYPE" == "all" ]; then
                    # Fichier pour les 10 postes avec la consommation max et min
                    MINMAX_FILE="tmp/lv_all_minmax.csv"
                    echo "Station ID;Capacity(kWh);Load (kWh)" > "$MINMAX_FILE"

                    # Extraction des 10 consommations minimales
                    tail -n +2 "$OUTPUT_FILE" | sort -t";" -k3,3n | head -n 10 >> "$MINMAX_FILE"

                    # Extraction des 10 consommations maximales
                    tail -n +2 "$OUTPUT_FILE" | sort -t";" -k3,3nr | head -n 10 >> "$MINMAX_FILE"

                    echo "Fichier des 10 postes min et max généré : $MINMAX_FILE"
                fi
                ;;
            *) echo "Erreur : Type de consommateur non valide." && exit 1 ;;
        esac
        ;;
    *) echo "Erreur : Type de station non valide." && exit 1 ;;
    esac

    # Remplacement des '-' par '0' dans le fichier de sortie
    sed -i 's/-/0/g' "$OUTPUT_FILE"
# Tri des lignes par la capacité (colonne 2)
    mv "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp"
    head -n 1 "${OUTPUT_FILE}.tmp" > "$OUTPUT_FILE" # Conserve l'en-tête
    tail -n +2 "${OUTPUT_FILE}.tmp" | sort -t":" -k2,2n >> "$OUTPUT_FILE" # Trie par capacité croissante
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
