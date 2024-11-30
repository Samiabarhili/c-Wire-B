#!/bin/bash
# Fonction pour afficher l'aide

function display_help() {
    echo "Usage: $0 <chemin_du_fichier>"
    echo ""
    echo "Description :"
    echo "  Ce script vérifie les propriétés d'un fichier de données donné en argument."
    echo ""
    echo "Options :"
    echo "  -h              Affiche cette aide."
    echo ""
    echo "Exemple :"
    echo "  $0 chemin/vers/votre_fichier.csv"
    exit 0
}

# Vérification si l'utilisateur a demandé l'aide
if [[ "$1" == "-h" ]]; then
    display_help
fi

# Vérification qu'un argument est fourni
if [[ -z "$1" ]]; then
    echo "Erreur : Vous devez fournir le chemin d'un fichier en argument."
    echo "Utilisez '-h' pour afficher l'aide."
    exit 1
fi

# Récupération du chemin du fichier depuis l'argument
input_file="$1"

# Vérification de l'existence et des propriétés du fichier
if [ -e "$input_file" ]; then
    echo "- Le fichier '$input_file' existe."
    
    # Vérifie si c'est un fichier ordinaire
    if [ -f "$input_file" ]; then
        echo "  * C'est un fichier ordinaire."
    else
        echo "  * Ce n'est pas un fichier ordinaire."
    fi

    # Vérifie si le fichier est lisible
    if [ -r "$input_file" ]; then
        echo "  * Il est lisible."
    else
        echo "  * Attention : Le fichier n'est pas lisible par l'utilisateur courant."
    fi

    # Vérifie si le fichier est modifiable
    if [ -w "$input_file" ]; then
        echo "  * Il est modifiable."
    else
        echo "  * Attention : Le fichier n'est pas modifiable par l'utilisateur courant."
    fi

    # Vérifie si le fichier a été modifié depuis la dernière lecture
    if [ -N "$input_file" ]; then
        echo "  * Le fichier a été modifié depuis la dernière lecture."
    else
        echo "  * Le fichier n'a pas été modifié depuis la dernière lecture."
    fi
else
    echo "- Le fichier '$input_file' n'existe pas."
    exit 1
fi#!/bin/bash
