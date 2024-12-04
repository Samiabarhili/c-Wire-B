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

AVLNode* rotationGauche(AVLNode* a) {
    AVLNode* pivot = a->right; // Le fils droit devient le pivot
    a->right = pivot->left;    // Le sous-arbre gauche du pivot devient le fils droit de `a`
    pivot->left = a;           // `a` devient le fils gauche du pivot

    // Mise à jour des facteurs d'équilibre
    a->balance_factor = a->balance_factor - 1 - (pivot->balance_factor > 0 ? pivot->balance_factor : 0);
    pivot->balance_factor = pivot->balance_factor - 1 + (a->balance_factor < 0 ? a->balance_factor : 0);

    return pivot; // Le pivot devient la nouvelle racine
}
AVLNode* rotationDroite(AVLNode* a) {
    AVLNode* pivot = a->left;  // Le fils gauche devient le pivot
    a->left = pivot->right;    // Le sous-arbre droit du pivot devient le fils gauche de `a`
    pivot->right = a;          // `a` devient le fils droit du pivot

    // Mise à jour des facteurs d'équilibre
    a->balance_factor = a->balance_factor + 1 - (pivot->balance_factor < 0 ? pivot->balance_factor : 0);
    pivot->balance_factor = pivot->balance_factor + 1 + (a->balance_factor > 0 ? a->balance_factor : 0);

    return pivot; // Le pivot devient la nouvelle racine
}
AVLNode* doubleRotationGauche(AVLNode* a) {
    a->right = rotationDroite(a->right); // Rotation droite sur le fils droit
    return rotationGauche(a);           // Puis rotation gauche sur la racine
}
AVLNode* doubleRotationDroite(AVLNode* a) {
    a->left = rotationGauche(a->left); // Rotation gauche sur le fils gauche
    return rotationDroite(a);         // Puis rotation droite sur la racine
}
AVLNode* equilibrerAVL(AVLNode* a) {
    if (a->balance_factor >= 2) { // Déséquilibre à droite
        if (a->right->balance_factor >= 0) {
            return rotationGauche(a); // Rotation simple gauche
        } else {
            return doubleRotationGauche(a); // Double rotation gauche
        }
    } else if (a->balance_factor <= -2) { // Déséquilibre à gauche
        if (a->left->balance_factor <= 0) {
            return rotationDroite(a); // Rotation simple droite
        } else {
            return doubleRotationDroite(a); // Double rotation droite
        }
    }
    return a; // Pas de rééquilibrage nécessaire
}
AVLNode* insertionAVL(AVLNode* a, int station_id, long capacity, long consumption, int* h) {
    if (a == NULL) { // Si l'arbre est vide, crée un nouveau nœud
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
AVLNode* suppMinAVL(AVLNode* a, int* h, int* min_id) {
    if (a->left == NULL) { // Trouvé le plus petit élément
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
AVLNode* suppressionAVL(AVLNode* a, int station_id, int* h) {
    if (a == NULL) { // Élément introuvable
        *h = 0;
        return NULL;
    }

    if (station_id < a->station_id) { // Recherche dans le sous-arbre gauche
        a->left = suppressionAVL(a->left, station_id, h);
        *h = -*h;
    } else if (station_id > a->station_id) { // Recherche dans le sous-arbre droit
        a->right = suppressionAVL(a->right, station_id, h);
    } else { // Élément trouvé
        if (a->right == NULL) { // Pas de fils droit
            AVLNode* temp = a->left;
            free(a);
            *h = -1;
            return temp;
        } else if (a->left == NULL) { // Pas de fils gauche
            AVLNode* temp = a->right;
            free(a);
            *h = -1;
            return temp;
        } else { // Deux fils
            int min_id;
            a->right = suppMinAVL(a->right, h, &min_id);
            a->station_id = min_id;
        }
    }

    if (*h != 0) { // Mise à jour et rééquilibrage
        a->balance_factor += *h;
        a = equilibrerAVL(a);
        *h = (a->balance_factor == 0) ? -1 : 0;
    }
    return a;
}
// Afficher un AVL en ordre croissant
void afficherInfixe(AVLNode* a) {
    if (a != NULL) {
        // Parcourir le sous-arbre gauche
        afficherInfixe(a->left);

        // Afficher les données du nœud courant
        printf("Station ID: %d, Capacity: %ld, Consumption: %ld, Balance Factor: %d\n",
               a->station_id, a->capacity, a->total_consumption, a->balance_factor);

        // Parcourir le sous-arbre droit
        afficherInfixe(a->right);
    }
}


