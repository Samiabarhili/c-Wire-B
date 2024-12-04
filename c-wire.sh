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
    if [ $# -lt 3 ]; then # Si le nombre d'arguments est inférieur à 3 (lt : less than)
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
    if ! [[ "$4" =~ ^[1-5]$ ]] && [ -n "$4" ]; then
        echo "Erreur : L'identifiant de la centrale doit être au choix 1,2,3,4 ou 5."
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

# Création des dossiers nécessaires pour le script s'ils n'existent pas
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
    if [ ! -f codeC/program ]; then   #si le code c n'existe pas, pas encore compilé
        echo "Compilation en cours..."
        make -C codeC || { echo "Erreur de compilation"; exit 1; }    #si la compilation a échoué, message d'erreur.
    fi
}

# Exploration des données
data_exploration() {
    echo "Exploration des données pour le type de station : $STATION_TYPE"

    #fichier de sortie :
    OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}.csv"

    #cas particulier où il y a l'ID de la centrale
    if [ "$CENTRAL_ID" != "*" ]; then
        OUTPUT_FILE="tmp/${STATION_TYPE}_${CONSUMER_TYPE}_${CENTRAL_ID}.csv"
    fi

    #ajout de la première ligne du fichier de sortie
    echo "${STATION_TYPE} Station ID:Capacity(kWh):Load ($CONSUMER_TYPE) (kWh)" > "$OUTPUT_FILE"

    case "$STATION_TYPE" in     #ATTENTION, je n'ai pas pris en compte le fait qu'il y ait des 
     #erreurs dans le fichier d'entrée, risque d'avoir autre que des comp.
        'hvb')
            if [ "$CENTRAL_ID" != "*" ]; then     #cas où on étudie les HVB sur une centrale en particulier
                grep "$CENTRAL_ID;;-;-;-;;-" "$INPUT_FILE" | awk -F ":" '$5 != "-" {print $2 ":" $7 ":" $8}' >> $OUTPUT_FILE
                if [ -s $OUTPUT_FILE ]; then
                    echo "Données filtrées sauvegardées dans $OUTPUT_FILE"
                else
                    echo "Aucune donnée trouvée pour hvb avec CENTRAL_ID=$CENTRAL_ID"
                    exit 1
                fi
            else #on prend les HVB de toutes les centrales.
                grep ";;-;-;-;;-" "$INPUT_FILE" | awk -F ":" '$5 != "-" {print $2 ":" $7 ":" $8}' >> $OUTPUT_FILE
                if [ -s $OUTPUT_FILE ]; then
                    echo "Données filtrées sauvegardées dans $OUTPUT_FILE"
                else
                    echo "Aucune donnée trouvée pour hvb avec CENTRAL_ID=$CENTRAL_ID"
                    exit 1
                fi
            fi
        ;;
        'hva')
            if [ "$CENTRAL_ID" != "*" ]; then   
                grep "$CENTRAL_ID;;;-;-;;-" "$INPUT_FILE" |  awk -F ":" '$5 != "-" {print $3 ":" $7 ":" $8}' >> $OUTPUT_FILE
                if [ -s $OUTPUT_FILE ]; then
                    echo "Données filtrées sauvegardées dans $OUTPUT_FILE"
                else
                    echo "Aucune donnée trouvée pour hva avec CENTRAL_ID=$CENTRAL_ID"
                    exit 1
                fi
            else #on prend les HVA de toutes les centrales.
                grep ";;-;-;-;;-" "$INPUT_FILE" |  awk -F ":" '$5 != "-" {print $3 ":" $7 ":" $8}' >> $OUTPUT_FILE
                if [ -s $OUTPUT_FILE ]; then
                    echo "Données filtrées sauvegardées dans $OUTPUT_FILE"
                else
                    echo "Aucune donnée trouvée pour hvb avec CENTRAL_ID=$CENTRAL_ID"
                    exit 1
                fi
            fi
        ;;
        'lv')
            echo"Traitement des postes LV..."
            if [ "$CONSUMER_TYPE" == "all" ]; then
                if [ "$CENTRAL_ID" != "*" ]; then
                    grep "$CENTRAL_ID" "$INPUT_FILE" | cut -d ":" -f4,7,8 >> "$OUTPUT_FILE"
                else 
                    grep ";;-;-;;-" "$INPUT_FILE" | cut -d ":" -f4,7,8 >> "$OUTPUT_FILE"
                fi

                #prendre les 10 postes avec la + grande conso et les 10 avec la + petite
                head -n 10 "$OUTPUT_FILE" >> tmp/lv_all_minmax.csv
                tail -n 10 "$OUTPUT_FILE" >> tmp/lv_all_minmax.csv

                #trier encore ? 
                # sort -t ";" -k3n tmp/lv_all_minmax.csv -o tmp/lv_all_minmax.csv
                echo "Données LV (min et max consommation) sauvegardées dans tmp/lv_all_minmax.csv"
            else 
                if [ "$CONSUMER_TYPE" == "comp" ]; then
                    if [ "$CENTRAL_ID" != "*" ]; then
                        grep "$CENTRAL_ID" "INPUT_FILE" | awk -F ":" '$5 != "-" {print $4 ":" $7 ":" $8}' >> "$OUTPUT_FILE"
                        echo "Données LV (comp) filtrées par capacité pour CENTRAL_ID=$CENTRAL_ID et sauvegardées dans $OUTPUT_FILE"
                    else
                        grep ";;-;-;;-" "$INPUT_FILE" | awk -F ":" '$5 != "-" {print $4 ":" $7 ":" $8}' >> "$OUTPUT_FILE"
                        echo "Données LV (comp) filtrées par capacité et sauvegardées dans $OUTPUT_FILE"
                    fi
                elif [ "$CONSUMER_TYPE" == "indiv" ]; then
                    if [ "$CENTRAL_ID" != "*" ]; then
                        grep "$CENTRAL_ID" "INPUT_FILE" | awk -F ":" '$6 != "-" {print $4 ":" $7 ":" $8}' >> "$OUTPUT_FILE"
                        echo "Données LV (comp) filtrées par capacité pour CENTRAL_ID=$CENTRAL_ID et sauvegardées dans $OUTPUT_FILE"
                    else
                        grep ";;-;-;;-" "$INPUT_FILE" | awk -F ":" '$6 != "-" {print $4 ":" $7 ":" $8}' >> "$OUTPUT_FILE"
                        echo "Données LV (comp) filtrées par capacité et sauvegardées dans $OUTPUT_FILE"
                    fi
                fi
            fi
        ;;
        *)
            echo "Erreur : Type de station non reconnu."
            exit 1
        ;;
    esac   #fin du case
}

#Trier les données par capacité dans l'ordre croissant en préservant l'entête
{
    head -n 1 "$OUTPUT_FILE"
    tail -n +2 "$OUTPUT_FILE" | sort -t ":" -k2n
} > tmp/sorted_output.csv && mv tmp/sorted_output.csv "$OUTPUT_FILE"


#JE M'ARRETE A LA !, manque la durée, DANS LE FICHIER FINAL, 
#ID HVB  : CAPACITY : LOAD



# Exécution du programme C
execute_program() {
    echo "Exécution du programme C..."
    CodeC/progO/program "$OUTPUT_FILE" tmp/results.csv "$CONSUMER_TYPE"  #tmp results ? 
    #chemin d'accès au program, input ,  output ,    type de conso pour entrer dans le c.

    if [ $? -eq 0 ]; then
        echo "Résultats sauvegardés dans tmp/results.csv"    #si le prog c'est exé correctement alors 0
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
