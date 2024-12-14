# C-Wire - Gestionnaire de réseau électrique

> Réalisé par Tiroumourougane Synthia, Achour Hajar et BARHILI Samia (Trinôme-MEF1-B)

## Description

C-Wire est un gestionnaire de réseau électrique qui permet d'analyser la distribution d'énergie à travers différents niveaux de stations (HVB, HVA, LV) et types de consommateurs.

### Fonctionnalités principales:

Fonctionnalités
    Analyse de la capacité des stations électriques par type
    Calcul de la consommation par type de client
    Génération de rapports sur l'utilisation du réseau 
    Mesure du temps d'exécution

Le programme traite les données d'entrée via un script shell et génère des fichiers de sortie détaillant:
- La liste des stations par type
- Les capacités de transmission
- La consommation totale par point de connexion


- Plus de détails sur le projet [ici]()     #j'aimerais mettre un lien vers le sujet pdf ou bien on dit juste où il doit le trouver


## Utilisation

1. Cloner le repository ou ouvrer un codespace
2. Placer le fichier de données dans le dossier 'input/'

``bash
./c-wire.sh <fichier_csv> <type_station> <type_consommateur> [id_centrale]
> ⚠ il faut au minimum 3 arguments pour exécuter correctement le programme : le chemin vers le fichier à traiter + les traitements souhaités.


Paramètres
    fichier_csv : Chemin vers le fichier de données (ex: input/c-wire_v25.dat)
    type_station : Type de station (hvb, hva, lv)
    type_consommateur : Type de consommateur (comp, indiv, all)
    id_centrale : (Optionnel) Identifiant de la centrale (1-5)


Exemple : ./c-wire.sh input/c-wire_v25.dat hvb comp 


##Structure du réseau 
CENTRALE
   └── HVB
       ├── HVA
       │   ├── LV
       │   │   ├── Particuliers
       │   │   └── Entreprises
       │   └── Entreprises HVA
       └── Entreprises HVB


## Prérequis techniques

- GCC (compilateur C) - [Documentation](https://doc.ubuntu-fr.org/gcc)
- Make (utilitaire de compilation) - [Documentation](https://linuxhint.com/install-make-ubuntu/)
- Bash (shell Unix) - [Documentation](https://howtoinstall.co/package/bash)
- BC (calculatrice en ligne de commande)

## Bugs et limitations
  Les traitements peuvent être relativement longs en fonction de la taille des fichiers de données.
