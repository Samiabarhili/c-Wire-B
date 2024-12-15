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

// Function declaration
AVLNode* createAVL(int station_id, long capacity, long consumption);
AVLNode* insertionAVL(AVLNode* a, int station_id, long capacity, long consumption, int* h);
AVLNode* deletionAVL(AVLNode* a, int station_id, int* h);
void showInfix(AVLNode* a);

#endif
