#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int hauteur(AVL* noeud) {
    if (noeud == NULL) {
        return -1;   
}
    int HG = hauteur(noeud->gauche);
    int HD = hauteur(noeud->droite);
    return 1 + fmax(HG,HD);
}

int calculerFE(AVL* noeud) {
    if (noeud == NULL)
        return 0;
    return hauteur(noeud->droite) - hauteur(noeud->gauche);
}

void mettreAJourHauteur(AVL* noeud) {
    if (noeud != NULL) {
        int hauteurGauche = hauteur(noeud->gauche);
        int hauteurDroite = hauteur(noeud->droite);
        noeud->hauteur = 1 + fmax(hauteurGauche, hauteurDroite);
    }
}

AVL* rotationGauche(AVL* noeud) {
    AVL* nouveauParent = noeud->droite;
    noeud->droite = nouveauParent->gauche;
    nouveauParent->gauche = noeud;

    // Mettre à jour les hauteurs
    mettreAJourHauteur(noeud);
    mettreAJourHauteur(nouveauParent);

    return nouveauParent;
}

AVL* rotationDroite(AVL* noeud) {
    AVL* nouveauParent = noeud->gauche;
    noeud->gauche = nouveauParent->droite;
    nouveauParent->droite = noeud;

    // Mettre à jour les hauteurs
    mettreAJourHauteur(noeud);
    mettreAJourHauteur(nouveauParent);

    return nouveauParent;
}


AVL* equilibrer(AVL* noeud) {
    mettreAJourHauteur(noeud);

    int fe = calculerFE(noeud);

    // Cas déséquilibre gauche
    if (fe < -1) {
        if (calculerFE(noeud->gauche) > 0) {
            // Rotation gauche-droite
            noeud->gauche = rotationGauche(noeud->gauche);
        }
        return rotationDroite(noeud);
    }

    // Cas déséquilibre droite
    if (fe > 1) {
        if (calculerFE(noeud->droite) < 0) {
            // Rotation droite-gauche
            noeud->droite = rotationDroite(noeud->droite);
        }
        return rotationGauche(noeud);
    }

    return noeud;  // L'arbre est déjà équilibré
}

AVL* inserer(AVL* noeud, int valeur) {
    if (noeud == NULL) {
        AVL* nouveau = (AVL*)malloc(sizeof(AVL));
        nouveau->valeur = valeur;
        nouveau->hauteur = 0;  // Hauteur d'une feuille = 1
        nouveau->gauche = nouveau->droite = NULL;
        return nouveau;
    }

    if (valeur < noeud->valeur) {
        noeud->gauche = inserer(noeud->gauche, valeur);
    } else if (valeur > noeud->valeur) {
        noeud->droite = inserer(noeud->droite, valeur);
    } else {
        // Les doublons ne sont pas autorisés
        return noeud;
    }

    // Rééquilibrer le nœud si nécessaire
    return equilibrer(noeud);
}

void parcoursInfixeAvecEquilibres(AVL* noeud) {
    if (noeud != NULL) {
        parcoursInfixeAvecEquilibres(noeud->gauche);
        int fe = calculerFE(noeud);
        printf("Valeur: %d, h : %d, FE: %d\n", noeud->valeur, noeud->hauteur, fe);
        parcoursInfixeAvecEquilibres(noeud->droite);
    }
}


int main() {
    AVL* racine = NULL;

    // Insertion de valeurs
    racine = inserer(racine, 10);
    racine = inserer(racine, 20);
    racine = inserer(racine, 30);
    racine = inserer(racine, 5);
    racine = inserer(racine, 25);

    // Affichage des valeurs triées
    printf("Parcours infixe : ");
    parcoursInfixeAvecEquilibres(racine);
    printf("\n");

    return 0;
}
