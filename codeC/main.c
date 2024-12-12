#include <stdio.h>
#include <stdlib.h>
#include "avl_tree.h"

// Function main to read the data from the standard input and insert it in the AVL tree 

int main(){
    AVLNode *root = NULL;
    int station_id = 0;// initialize the data of the station
    int h = 0;
    long load = 0, capacity = 0;
    while (scanf("%d;%ld;%ld\n", &station_id, &capacity, &load) != EOF) {// Read the data from the standard input
       printf("fdgfig"); 
        root = insertAVL(root, station_id, capacity, load, &h);
    }
    printf("Infix order:\n");
    printf("Station_id:Capacity:Load\n");
    printf("%d : %ld : %ld\n", root->station_id, root->capacity, root->load);
    inorder(root); // Display the AVL tree in infix order
    root = freeAVL(root);
    return 0;
}