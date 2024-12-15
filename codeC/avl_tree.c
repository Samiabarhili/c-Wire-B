#include "avl_tree.h"


//Function to create a new node with the given data 
AVLNode* newNode(int station_id, long capacity, long load) {
    AVLNode* node = (AVLNode*) malloc(sizeof(AVLNode));
    if (node == NULL) {
        fprintf(stderr, "Memory allocation error\n"); // Display an error message, if allocation failed
        exit(EXIT_FAILURE);
    }

    node->station_id = station_id;
    node->load = load;
    node->capacity = capacity;
    node->left = NULL;
    node->right = NULL;
    node->balance = 0; // The new node is a sheet, so its balance is 0
    return node;
}

// Function to obtain the maximum between two integers
int max(int a, int b) {
    return (a > b) ? a : b; // If a is greater than b, return a, otherwise return b
}

// Function to obtain the minimum between two integers
int min(int a, int b) {
    return (a > b) ? b : a; // If a is greater than b, return b, otherwise return a
}


// Function to rotate the tree to the left
AVLNode *leftRotate(AVLNode *node){
	if(node == NULL){
	exit(3); // Exit the program with an error code
	}
	int eq_a;
	int eq_p;
	AVLNode *pivot =node->right;
	node->right = pivot->left;
	pivot->left = node; 
	eq_a = node->balance;
	eq_p = pivot->balance;
	node->balance = eq_a - max(eq_p, 0) - 1;// Update the balance of the node
	pivot->balance = min(min(eq_a - 2, eq_a + eq_p - 2), eq_p - 1);// Update the balance of the pivot
	node = pivot;
	return node;
}

// Function to rotate the tree to the right
AVLNode *rightRotate(AVLNode *node){
	if(node == NULL){
	exit(4);
	}
	int eq_a;
	int eq_p;
	AVLNode *pivot =node->left;
	node->left = pivot->right;
	pivot->right = node;
	eq_a = node->balance;
	eq_p = pivot->balance;
	node->balance = eq_a - min(eq_p, 0) + 1;// Update the balance of the node
	pivot->balance = max(max(eq_a + 2, eq_a + eq_p + 2), eq_p + 1);// Update the balance of the pivot
	node = pivot;
	return node;
}

// Double left rotation
AVLNode* DoubleRotateLeft(AVLNode *node) {
    node->right = rightRotate(node->right);// Rotate the right child to the right
    return leftRotate(node);// Rotate the node to the left
}

// Double right rotation
AVLNode* DoubleRotateRight(AVLNode *node) {
    node->left = leftRotate(node->left);// Rotate the left child to the left
    return rightRotate(node);// Rotate the node to the right
}

// Function to balance the AVL tree
AVLNode *balanceAVL(AVLNode *node){
	if(node == NULL){
		printf("error\n");// Display an error message if the node is NULL
	}
	if(node->balance >= 2){
		if(node->right->balance >= 0){// if the balance of the right child is greater than or equal to 0, rotate the tree to the left
			return leftRotate(node);
		}
		else{
			return DoubleRotateLeft(node);// Otherwise, perform a double left rotation
		}
	}
	else if(node->balance <= -2){// if the balance of the node is less than or equal to -2, rotate the tree to the right
		if(node->left->balance <=0){
			return rightRotate(node);
		}
		else{
			return DoubleRotateRight(node);// Otherwise, perform a double right rotation
		}
	}
	return node;
}

// Function to insert a new node in the AVL tree and balance it
AVLNode *insertAVL(AVLNode *node, int station_id, long capacity, long load, int *h){
	if(node == NULL){
		*h = 1;
		return newNode(station_id, capacity, load);// if the node is NULL, create a new node and return it
	}
	else if(station_id < node->station_id){
		node->left = insertAVL(node->left, station_id, capacity, load, h);// Insert the new node in the left subtree
		*h = -(*h);// Update the height
	}
	else if(station_id > node->station_id){
		node->right = insertAVL(node->right, station_id, capacity, load, h);// Insert the new node in the right subtree
	}
	else{// if the node already exists in the tree, update its data but no insertion
		node->load += load;     
		if (capacity > 0) { // Ne met à jour la capacité que si elle est positive
        node->capacity = capacity;
        }
		*h = 0;
		return node;
	}
	if( *h != 0){
		node->balance += *h;
		node = balanceAVL(node);// Balance the tree
		if(node->balance == 0){
			*h = 0;
		}
		else{
			*h = 1;
		}
	}
	return node;
}

// Function to display the AVL tree in infix order, recursively
void inorder(AVLNode *node){
	if(node != NULL){
		inorder(node->left);
		printf("%d:%ld:%ld\n", node->station_id, node->capacity, node->load);
		inorder(node->right);
	}
}

// Function to free the memory allocated for the AVL tree
AVLNode *freeAVL(AVLNode *node){
	if (node == NULL) {
		return node;
	}
	node->left = freeAVL(node->left);// Free the left subtree
	node->left = NULL;
	node->right = freeAVL(node->right);// Free the right subtree
	node->right = NULL;
	free(node);
	node = NULL;
	return node;
}

// Recursive function to browse the tree in ascending order and write data to a file
void exportAVLNodeToFile(FILE *file, AVLNode *node) {
    if (node == NULL)return;
    // Browse left subtree
    exportAVLNodeToFile(file, node->left);
    // Write data for current node
    fprintf(file, "%d:%ld:%ld\n", node->station_id, node->capacity, node->load);
    // Browse right sub-tree
    exportAVLNodeToFile(file, node->right);
}

// Function to open a file and start exporting
void saveAVLNodeToFile(const char *filename, AVLNode *node) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        perror("Error opening file for export");
        return;
    }
    // Write file header
    fprintf(file, "Station_ID:Capacity:Load\n");
    // Call recursive function to export data
    exportAVLNodeToFile(file, node);
    // Close file
   	fclose(file);
}
