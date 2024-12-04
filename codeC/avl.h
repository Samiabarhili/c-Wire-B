typedef struct AVL {
    int valeur;                  // Valeur stockée dans le nœud
    int eq;                 // Hauteur du nœud
    struct AVL* gauche;          // Sous-arbre gauche
    struct AVL* droite;          // Sous-arbre droit
} AVL;
