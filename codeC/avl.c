#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "avl.h"

AVLNode* creerAVL(int station_id, long capacity, long consumption) {
    AVLNode* new = (AVLNode*)malloc(sizeof(AVLNode));
    if (new == NULL) {
        perror("Erreur d'allocation mémoire");
        exit(EXIT_FAILURE);
    }
    new->station_id = station_id;
    new->capacity = capacity;
    new->total_consumption = consumption;
    new->balance_factor = 0;
    new->left = NULL;
    new->right = NULL;
    return new;
}

// Rotation gauche
AVLNode* rotationGauche(AVLNode* a) {
    AVLNode* pivot = a->right;
    a->right = pivot->left;
    pivot->left = a;

    // Mise à jour des facteurs d'équilibre
    a->balance_factor = a->balance_factor - 1 - (pivot->balance_factor > 0 ? pivot->balance_factor : 0);
    pivot->balance_factor = pivot->balance_factor - 1 + (a->balance_factor < 0 ? a->balance_factor : 0);

    return pivot;
}

// Rotation droite
AVLNode* rotationDroite(AVLNode* a) {
    AVLNode* pivot = a->left;
    a->left = pivot->right;
    pivot->right = a;

    // Mise à jour des facteurs d'équilibre
    a->balance_factor = a->balance_factor + 1 - (pivot->balance_factor < 0 ? pivot->balance_factor : 0);
    pivot->balance_factor = pivot->balance_factor + 1 + (a->balance_factor > 0 ? a->balance_factor : 0);

    return pivot;
}

// Double rotation gauche
AVLNode* doubleRotationGauche(AVLNode* a) {
    a->right = rotationDroite(a->right);
    return rotationGauche(a);
}

// Double rotation droite
AVLNode* doubleRotationDroite(AVLNode* a) {
    a->left = rotationGauche(a->left);
    return rotationDroite(a);
}

// Rééquilibrage d'un AVL
AVLNode* equilibrerAVL(AVLNode* a) {
    if (a->balance_factor >= 2) { // Déséquilibre à droite
        if (a->right->balance_factor >= 0) {
            return rotationGauche(a);
        } else {
            return doubleRotationGauche(a);
        }
    } else if (a->balance_factor <= -2) { // Déséquilibre à gauche
        if (a->left->balance_factor <= 0) {
            return rotationDroite(a);
        } else {
            return doubleRotationDroite(a);
        }
    }
    return a; // Pas de rééquilibrage nécessaire
}

// Insertion dans un AVL
AVLNode* insertionAVL(AVLNode* a, int station_id, long capacity, long consumption, int* h) {
    if (a == NULL) { // Si l'arbre est vide
        *h = 1;
        return creerAVL(station_id, capacity, consumption);
    }

    if (station_id < a->station_id) { // Insertion dans le sous-arbre gauche
        a->left = insertionAVL(a->left, station_id, capacity, consumption, h);
        *h = -*h; // L'impact sur la hauteur est inversé pour la gauche
    } else if (station_id > a->station_id) { // Insertion dans le sous-arbre droit
        a->right = insertionAVL(a->right, station_id, capacity, consumption, h);
    } else { // Mise à jour si la station existe déjà
        a->total_consumption += consumption;
        *h = 0; // Pas de changement de hauteur
        return a;
    }

    if (*h != 0) { // Mise à jour du facteur d'équilibre et rééquilibrage
        a->balance_factor += *h;
        a = equilibrerAVL(a);
        *h = (a->balance_factor == 0) ? 0 : 1;
    }
    return a;
}

// Suppression du nœud minimum
AVLNode* suppMinAVL(AVLNode* a, int* h, int* min_id) {
    if (a->left == NULL) {
        *min_id = a->station_id;
        AVLNode* temp = a->right;
        free(a);
        *h = -1;
        return temp;
    }

    a->left = suppMinAVL(a->left, h, min_id);
    *h = -*h;

    if (*h != 0) {
        a->balance_factor += *h;
        a = equilibrerAVL(a);
        *h = (a->balance_factor == 0) ? -1 : 0;
    }
    return a;
}

// Suppression dans un AVL
AVLNode* suppressionAVL(AVLNode* a, int station_id, int* h) {
    if (a == NULL) {
        *h = 0;
        return NULL;
    }

    if (station_id < a->station_id) {
        a->left = suppressionAVL(a->left, station_id, h);
        *h = -*h;
    } else if (station_id > a->station_id) {
        a->right = suppressionAVL(a->right, station_id, h);
    } else {
        if (a->right == NULL) {
            AVLNode* temp = a->left;
            free(a);
            *h = -1;
            return temp;
        } else if (a->left == NULL) {
            AVLNode* temp = a->right;
            free(a);
            *h = -1;
            return temp;
        } else {
            int min_id;
            a->right = suppMinAVL(a->right, h, &min_id);
            a->station_id = min_id;
        }
    }

    if (*h != 0) {
        a->balance_factor += *h;
        a = equilibrerAVL(a);
        *h = (a->balance_factor == 0) ? -1 : 0;
    }
    return a;
}

// Affichage infixe (ordre croissant)
void afficherInfixe(AVLNode* a) {
    if (a != NULL) {
        afficherInfixe(a->left);
        printf("Station ID: %d, Capacity: %ld, Consumption: %ld, Balance Factor: %d\n",
               a->station_id, a->capacity, a->total_consumption, a->balance_factor);
        afficherInfixe(a->right);
    }
}

void chargerDonnees(char* fichier, AVLNode** root) {
    FILE* fp = fopen(fichier, "r");
    if (!fp) {
        perror("Erreur d'ouverture du fichier");
        exit(EXIT_FAILURE);
    }

    char ligne[1024];
    int station_id;
    long capacity, total_consumption;
    int hauteur = 0;

    // Ignorer la première ligne (en-tête)
    fgets(ligne, sizeof(ligne), fp);

    while (fgets(ligne, sizeof(ligne), fp)) {
        // Lire les données au format "station_id:capacity:consumption"
        sscanf(ligne, "%d:%ld:%ld", &station_id, &capacity, &total_consumption);
        *root = insertionAVL(*root, station_id, capacity, total_consumption, &hauteur);
    }

    fclose(fp);
}

