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

# PowerPlant;hvb;hva;LV;Company;Individual;Capacity;Load
# [ "$a" = "$b" ] compare character strings

data_exploration() {
    # Construction du nom du fichier de sortie
    
    echo "Exploration des données pour le type de station : $STATION_TYPE"

    #fichier de sortie :
    OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.csv"

    #cas particulier où il y a l'ID de la centrale
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv"
    fi
    #ajout de la première ligne du fichier de sortie
    echo "Station $STATION_TYPE ID;Capacity(kWh);Load ($CONSUMER_TYPE) (kWh)" > "$OUTPUT_FILE"
   # echo "Station ID;Capacity(kWh);Load ($CONSUMER_TYPE) (kWh)" > "$OUTPUT_FILE"

    case "$STATION_TYPE" in
        'hvb')
           
    echo "Exploration des données pour le type de station : $STATION_TYPE"

    # Construction du nom du fichier de sortie
    OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.csv"
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv"
    fi

    # Ajout de l'en-tête au fichier de sortie
    echo "Station $STATION_TYPE ID;Capacity(kWh);Load ($CONSUMER_TYPE) (kWh)" > "$OUTPUT_FILE"

    # Extraction brute des lignes contenant la capacité
    capacity_lines=$(grep -E "^$CENTRAL_ID;[^-]+;-;-;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f2,7)

    # Extraction brute des lignes contenant la consommation
    consumption_lines=$(grep -E "^$CENTRAL_ID;[^-]+;-;-;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f2,5,8)

    # Association des deux sources d'information dans une seule ligne
    echo "$capacity_lines" | while IFS=";" read -r id capacity; do
        # Vérification : ignorer les lignes incomplètes
        if [ -z "$id" ] || [ -z "$capacity" ]; then
            continue
        fi

        # Chercher la consommation correspondant à l'identifiant
        consumption=$(echo "$consumption_lines" | grep -E "^$id;" | cut -d ";" -f3)
        # Si aucune consommation trouvée, mettre un défaut "-"
        consumption=${consumption:--}

        # Écrire la ligne combinée dans le fichier
        echo "$id;$capacity;$consumption" >> "$OUTPUT_FILE"
    done

    # Nettoyage et filtrage final du fichier pour s'assurer qu'il n'y a que des lignes valides
    mv "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp"
    awk -F";" 'NF == 3 {print $0}' "${OUTPUT_FILE}.tmp" > "$OUTPUT_FILE"
    rm "${OUTPUT_FILE}.tmp"
;;

        'hva')

    # Extraction brute des lignes contenant la capacité
    capacity_lines=$(grep -E "^$CENTRAL_ID;[^-]+;[^-]+;-;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f3,7)

    # Extraction brute des lignes contenant la consommation
    consumption_lines=$(grep -E "^$CENTRAL_ID;-;[^-]+;-;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f3,8)

    # Association des deux sources d'information dans une seule ligne
    echo "$capacity_lines" | while IFS=";" read -r id capacity; do
        # Vérification : ignorer les lignes incomplètes
        if [ -z "$id" ] || [ -z "$capacity" ]; then
            continue
        fi

        # Chercher la consommation correspondant à l'identifiant
        consumption=$(echo "$consumption_lines" | grep -E "^$id;" | cut -d ";" -f2)
        # Si aucune consommation trouvée, mettre un défaut "-"
        consumption=${consumption:--}

        # Écrire la ligne combinée dans le fichier
        echo "$id;$capacity;$consumption" >> "$OUTPUT_FILE"
    done

    # Nettoyage et filtrage final du fichier pour s'assurer qu'il n'y a que des lignes valides
    mv "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp"
    awk -F";" 'NF == 3 {print $0}' "${OUTPUT_FILE}.tmp" > "$OUTPUT_FILE"
    rm "${OUTPUT_FILE}.tmp"
;;

        'lv')
           
    echo "Exploration des données pour le type de station : $STATION_TYPE et le type de consommateur : $CONSUMER_TYPE"

    # Construction du nom du fichier de sortie
    OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.csv"
    if [ "$CENTRAL_ID" != "[^-]+" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv"
    fi

    # Ajout de l'en-tête au fichier de sortie
    echo "Station LV ID;Capacity(kWh);Load ($CONSUMER_TYPE) (kWh)" > "$OUTPUT_FILE"

    # Extraction des lignes contenant la capacité et la consommation
    case "$CONSUMER_TYPE" in
        'comp')
            # Capacité
            capacity_lines=$(grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7)
            # Consommation
            consumption_lines=$(grep -E "$CENTRAL_ID;-;-;[^-]+;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,5,8)
        ;;
        'indiv')
            # Capacité
            capacity_lines=$(grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7)
            # Consommation
            consumption_lines=$(grep -E "$CENTRAL_ID;-;-;[^-]+;-;[^-]+;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,6,8)
        ;;
        'all')
            # Capacité
            capacity_lines=$(grep -E "$CENTRAL_ID;-;[^-]+;[^-]+;-;-;[^-]+;-$" "$INPUT_FILE" | cut -d ";" -f4,7)
            # Consommation
            consumption_lines=$(grep -E "$CENTRAL_ID;-;-;[^-]+;[^-]+;-;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,5,8)
            consumption_lines+="\n$(grep -E "$CENTRAL_ID;-;-;[^-]+;-;[^-]+;-;[^-]+$" "$INPUT_FILE" | cut -d ";" -f4,6,8)"
        ;;
        *)
            echo "Erreur : Type de consommateur non valide." && exit 1
        ;;
    esac

    # Association des deux sources d'information dans une seule ligne
    echo "$capacity_lines" | while IFS=";" read -r id capacity; do
        # Vérification : ignorer les lignes incomplètes
        if [ -z "$id" ] || [ -z "$capacity" ]; then
            continue
        fi

        # Chercher la consommation correspondant à l'identifiant
        consumption=$(echo "$consumption_lines" | grep -E "^$id;" | cut -d ";" -f2)
        # Si aucune consommation trouvée, mettre un défaut "-"
        consumption=${consumption:--}

        # Écrire la ligne combinée dans le fichier
        echo "$id;$capacity;$consumption" >> "$OUTPUT_FILE"
    done

    # Nettoyage et filtrage final du fichier pour s'assurer qu'il n'y a que des lignes valides
    mv "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp"
    awk -F";" 'NF == 3 {print $0}' "${OUTPUT_FILE}.tmp" > "$OUTPUT_FILE"
    rm "${OUTPUT_FILE}.tmp"
;;

}



    # Suppression des doublons
    #mv "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp"
    #awk '!seen[$0]++' "${OUTPUT_FILE}.tmp" > "$OUTPUT_FILE"
   # rm "${OUTPUT_FILE}.tmp"

    #echo "Fichier généré : $OUTPUT_FILE"



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


# Appel des fonctions
check_arguments "$@"
check_file
check_directories
# executable_verification
#execute_program
data_exploration
