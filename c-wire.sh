# Affichage de l'aide
for arg in "$@"; do
    if [ "$arg" = "-h" ]; then
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

# Vérification des arguments passés
check_arguments() {
    echo "arg : $@"
    if [ $# -lt 3 ]; then # Si le nombre d'arguments est inférieur à 3
        echo "Usage: $0 <fichier_csv> <type_station> <type_consommateur> [id_centrale]"
        exit 1
    fi

    # Vérification du type de station
    if [ "$2" != "hva" ] && [ "$2" != "hvb" ] && [ "$2" != "lv" ]; then
        echo "Erreur : Le type de station doit être 'hva', 'hvb' ou 'lv'."
        exit 1
    fi

    # Vérification du type de consommateur
    if [ "$3" != "comp" ] && [ "$3" != "indiv" ] && [ "$3" != "all" ]; then
        echo "Erreur : Le type de consommateur doit être 'comp', 'indiv' ou 'all'."
        exit 1
    fi

    # Vérification des combinaisons interdites
    if ([ "$2" = "hvb" ] || [ "$2" = "hva" ]) && ([ "$3" = "all" ] || [ "$3" = "indiv" ]); then
        echo "Erreur : Les combinaisons suivantes sont interdites : hvb all, hvb indiv, hva all, hva indiv."
        exit 1
    fi

    # Vérification de l'identifiant de centrale
    if ! [[ "$4" =~ ^[0-9]+$ ]] && [ -n "$4" ]; then
        echo "Erreur : L'identifiant de la centrale doit être un nombre."
        exit 1
    fi
}

INPUT_FILE=$1
STATION_TYPE=$2
CONSUMER_TYPE=$3
CENTRAL_ID=${4:-"*"}

# Vérification si le fichier CSV existe et n'est pas vide
check_file() {
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Erreur : Le fichier '$INPUT_FILE' n'existe pas."
        exit 1
    elif [ ! -s "$INPUT_FILE" ]; then
        echo "Erreur : Le fichier '$INPUT_FILE' est vide."
        exit 1
    fi
    echo "- Le fichier '$INPUT_FILE' existe."
    echo "  * C'est un fichier ordinaire."
    echo "  * Il est lisible."
    echo "  * Il est modifiable."
}

# Création des dossiers nécessaires pour le script
create_directories() {
    for directory in "tmp" "tests" "graphs"; do
        if [ ! -d "$directory" ]; then
            mkdir "$directory"
            echo "Répertoire '$directory' créé."
        fi
    done
}

# Vérification de l'exécutable du programme C
executable_verification() {
    if [ ! -f CodeC/program ]; then
        echo "Compilation en cours..."
        make -C CodeC || { echo "Erreur de compilation"; exit 1; }
    fi
}

# Exploration des données
data_exploration() {
    echo "Exploration des données pour le type de station : $STATION_TYPE"
    case "$STATION_TYPE" in
        'hvb')
            grep "$CENTRAL_ID;;-;-;-;;-" "$INPUT_FILE" | grep -v "$CENTRAL_ID;-;-;-;-;*;-" | cut -d ";" -f7 > tmp/filtered_hvb.csv
            if [ -s tmp/filtered_hvb.csv ]; then
                echo "Données filtrées sauvegardées dans tmp/filtered_hvb.csv"
            else
                echo "Aucune donnée trouvée pour hvb avec CENTRAL_ID=$CENTRAL_ID"
                exit 1
            fi
        ;;
        'hva')
            grep "$CENTRAL_ID;;;-;-;;-" "$INPUT_FILE" | grep -v "$CENTRAL_ID;;-;-;-;*;-" | cut -d ";" -f7 > tmp/filtered_hva.csv
            if [ -s tmp/filtered_hva.csv ]; then
                echo "Données filtrées sauvegardées dans tmp/filtered_hva.csv"
            else
                echo "Aucune donnée trouvée pour hva avec CENTRAL_ID=$CENTRAL_ID"
                exit 1
            fi
        ;;
        'lv')
            echo "Traitement spécifique pour LV non encore implémenté."
        ;;
        *)
            echo "Erreur : Type de station non reconnu."
            exit 1
        ;;
    esac
}

# Exécution du programme C
execute_program() {
    echo "Exécution du programme C..."
    CodeC/progO/program tmp/filtered_data.csv tmp/results.csv "$CONSUMER_TYPE"

    if [ $? -eq 0 ]; then
        echo "Résultats sauvegardés dans tmp/results.csv"
    else
        echo "Erreur lors de l'exécution du programme C"
        exit 1
    fi
}

# Appel des fonctions
echo "Vérification des arguments..."
check_arguments "$@"
echo "Validation des arguments terminée."
check_file
create_directories
#executable_verification
data_exploration
#execute_program
