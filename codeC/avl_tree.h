#ifndef AVL_TREE_H
#define AVL_TREE_H
#include <stdio.h>
#include <stdlib.h>


// Each node of the AVL represents a station and will therefore contain
// the station identifier as well as its various data such as its
// capacity, or the sum of its consumers which will be updated
// as your program reads the data

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
void exportAVLNodeToFile(FILE *file, AVLNode *node);// Function to traverse the AVL tree and export the results to a file
void saveAVLNodeToFile(const char *filename, AVLNode *root);// Function to save the tree in a file starting by opening the file
#endif //AVL_TREE_H
