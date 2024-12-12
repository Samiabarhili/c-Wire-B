#ifndef AVL_TREE_H
#define AVL_TREE_H
#include <stdio.h>
#include <stdlib.h>


// Chaque   nœud   de   l’AVL   représente   une   station   et   va   donc   contenir
// l’identifiant de la station ainsi que ses différentes données comme sa
// capacité, ou bien la somme de ses consommateurs qui sera mise à jour
// au fur et à mesure de la lecture des données par votre programme

typedef struct AVLNode {
    int station_id;
    long capacity;
    long load;
    struct AVLNode *left;
    struct AVLNode *right;
    int balance;
} AVLNode;

AVLNode * newNode(int station_id, long capacity, long load); 
int max(int a, int b);
int min(int a, int b);
void inorder(AVLNode *node);
AVLNode *rightRotate(AVLNode *node);
AVLNode *leftRotate(AVLNode *node);
AVLNode *DoubleRotateLeft(AVLNode *node);
AVLNode *DoubleRotateRight(AVLNode *node);
AVLNode *insertAVL(AVLNode *node, int station_id, long capacity, long load, int *h);
AVLNode *balanceAVL(AVLNode *node);
AVLNode *freeAVL(AVLNode *node);
void exportAVLNodeToFile(FILE *file, AVLNode *node);// Fonction pour parcourir l'arbre AVL et exporter les résultats dans un fichier
void saveAVLNodeToFile(const char *filename, AVLNode *root);// Fonction pour sauvegarder l'arbre dans un fichier en commençant par ouvrir le fichier
#endif //AVL_TREE_H