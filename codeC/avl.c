#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "avl.h"

AVLNode* createAVL(int station_id, long capacity, long consumption) {
    AVLNode* new = (AVLNode*)malloc(sizeof(AVLNode));
    if (new == NULL) {
        perror(“Memory allocation error”);
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

// Rotate left
AVLNode* rotationLeft(AVLNode* a) {
    AVLNode* pivot = a->right;
    a->right = pivot->left;
    pivot->left = a;

    // Update balance factors
    a->balance_factor = a->balance_factor - 1 - (pivot->balance_factor > 0 ? pivot->balance_factor : 0);
    pivot->balance_factor = pivot->balance_factor - 1 + (a->balance_factor < 0 ? a->balance_factor : 0);

    return pivot;
}

// Rotate right
AVLNode* rotationRight(AVLNode* a) {
    AVLNode* pivot = a->left;
    a->left = pivot->right;
    pivot->right = a;

    // Update balance factors
    a->balance_factor = a->balance_factor + 1 - (pivot->balance_factor < 0 ? pivot->balance_factor : 0);
    pivot->balance_factor = pivot->balance_factor + 1 + (a->balance_factor > 0 ? a->balance_factor : 0);

    return pivot;
}

// Double left rotation
AVLNode* doubleRotateLeft(AVLNode* a) {
    a->right = rotationRight(a->right);
    return rotationLeft(a);
}

// Double right rotation
AVLNode* doubleRotateRight(AVLNode* a) {
    a->left = rotationLeft(a->left);
    return rotationRight(a);
}

// Rebalancing an AVL
AVLNode* balanceAVL(AVLNode* a) {
    if (a->balance_factor >= 2) { // Imbalance on the right
        if (a->right->balance_factor >= 0) {
            return rotationLeft(a);
        } else {
            return doubleRotateLeft(a);
        }
    } else if (a->balance_factor <= -2) { // Unbalance on the left
        if (a->left->balance_factor <= 0) {
            return rotationRight(a);
        } else {
            return doubleRotateRight(a);
        }
    }
    return a; // No rebalancing necessary
}

// Insertion into an AVL
AVLNode* insertionAVL(AVLNode* a, int station_id, long capacity, long consumption, int* h) {
    if (a == NULL) { // If the tree is empty
        *h = 1;
        return createAVL(station_id, capacity, consumption);
    }

    if (station_id < a->station_id) { // Insert into left subtree
        a->left = insertionAVL(a->left, station_id, capacity, consumption, h);
        *h = -*h; // The impact on height is reversed for the left
    } else if (station_id > a->station_id) { // Insert into right subtree
        a->right = insertionAVL(a->right, station_id, capacity, consumption, h);
    } else { // Update if the station already exists
        a->total_consumption += consumption;
        *h = 0; // No change in height
        return a;
    }

    if (*h != 0) { // Balance factor update and rebalancing
        a->balance_factor += *h;
        a = balanceAVL(a);
        *h = (a->balance_factor == 0) ? 0 : 1;
    }
    return a;
}

// Removing the minimum node
AVLNode* deletMinAVL(AVLNode* a, int* h, int* min_id) {
    if (a->left == NULL) {
        *min_id = a->station_id;
        AVLNode* temp = a->right;
        free(a);
        *h = -1;
        return temp;
    }

    a->left = deletMinAVL(a->left, h, min_id);
    *h = -*h;

    if (*h != 0) {
        a->balance_factor += *h;
        a = balanceAVL(a);
        *h = (a->balance_factor == 0) ? -1 : 0;
    }
    return a;
}

// Deletion in an AVL
AVLNode* deletionAVL(AVLNode* a, int station_id, int* h) {
    if (a == NULL) {
        *h = 0;
        return NULL;
    }

    if (station_id < a->station_id) {
        a->left = deletionAVL(a->left, station_id, h);
        *h = -*h;
    } else if (station_id > a->station_id) {
        a->right = deletionAVL(a->right, station_id, h);
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
            a->right = deletMinAVL(a->right, h, &min_id);
            a->station_id = min_id;
        }
    }

    if (*h != 0) {
        a->balance_factor += *h;
        a = balanceAVL(a);
        *h = (a->balance_factor == 0) ? -1 : 0;
    }
    return a;
}

// Fixed display (ascending order)
void showInfix(AVLNode* a) {
    if (a != NULL) {
        showInfix(a->left);
        printf("Station ID: %d, Capacity: %ld, Consumption: %ld, Balance Factor: %d\n",
               a->station_id, a->capacity, a->total_consumption, a->balance_factor);
        showInfix(a->right);
    }
}

void loadData(char* file, AVLNode** root) {
    FILE* fp = fopen(file, "r");
    if (!fp) {
        perror(“Error opening file”);
        exit(EXIT_FAILURE);
    }

    char line[1024];
    int station_id;
    long capacity, total_consumption;
    int height = 0;

    // Ignore the first line (header)
    fgets(line, sizeof(line), fp);

    while (fgets(line, sizeof(line), fp)) {
        // Read data in "station_id:capacity:consumption" format
        sscanf(line, "%d:%ld:%ld", &station_id, &capacity, &total_consumption);
        *root = insertionAVL(*root, station_id, capacity, total_consumption, &height);
    }

    fclose(fp);
}

