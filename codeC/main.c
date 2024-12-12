//partie principale
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include "avl.h"

#include <stdio.h>
#include <stdlib.h>
#include "avl.h"

// Function main to read the data from standard input and insert it in the AVL tree
int main() {
    AVLNode *root = NULL;
    int station_id = 0;
    int h = 0;
    long load = 0, capacity = 0;

    // Read the data from standard input
    while (scanf("%d;%ld;%ld\n", &station_id, &capacity, &load) != EOF) {
        root = insertionAVL(root, station_id, capacity, load, &h);
    }

    afficherInfixe(root); // Display the AVL tree in infix order
    //root = freeAVL(root);
    
    return 0;
}
