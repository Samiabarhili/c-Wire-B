#ifndef AVL_H
#define AVL_H

typedef struct AVLNode {
    int station_id;
    long capacity;
    long total_consumption;
    int balance_factor;
    struct AVLNode* left;
    struct AVLNode* right;
} AVLNode;

// Déclaration des fonctions
AVLNode* creerAVL(int station_id, long capacity, long consumption);
AVLNode* insertionAVL(AVLNode* a, int station_id, long capacity, long consumption, int* h);
AVLNode* suppressionAVL(AVLNode* a, int station_id, int* h);
void afficherInfixe(AVLNode* a);

#endif
