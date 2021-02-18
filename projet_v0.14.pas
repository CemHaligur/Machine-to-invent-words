PROGRAM Projet;

{$mode objfpc}{$H+}
{$codepage UTF8}
{$I-}

USES cwstring, crt,uniteStatistiques, uniteGestionFichiers;

CONST
    alphabet : WideString = 'abcdefghijklmnopqrstuvwxyzàâéèêëîïôùûüÿæœç-';
    
    TAILLE_TAB_PROBA : integer = 44;
    
    APOSTROPHE : WideString = WideChar($0027);
    
    PROTECTION_BOUCLES : integer = 500;

    TAILLE_MOT_INIT : integer = 0;
    NB_MOTS_INIT : integer = 1;
    NB_MOTS_DEFAUT : integer = 100;
    
    TAILLE_MIN_MOT : integer = 3;
    TAILLE_MAX_MOT : integer = 10;
    FRACTION_PROBA_MOT : real = 0.4;
    
    TAILLE_MIN_ARTICLE : integer = 2;
    TAILLE_MAX_ARTICLE : integer = 3;
    FRACTION_PROBA_ARTICLE : real = 1.0;

    TAILLE_MIN_NOM : integer = 3;
    TAILLE_MAX_NOM : integer = 15;
    FRACTION_PROBA_NOM : real = 0.4;

    TAILLE_MIN_VERBE : integer = 3;
    TAILLE_MAX_VERBE : integer = 12;
    FRACTION_PROBA_VERBE : real = 0.4;

    TAILLE_MIN_ADJECTIF : integer = 3;
    TAILLE_MAX_ADJECTIF : integer = 12;
    FRACTION_PROBA_ADJECTIF : real = 0.4;

    TAILLE_MIN_ADVERBE : integer = 5;
    TAILLE_MAX_ADVERBE : integer = 12;
    FRACTION_PROBA_ADVERBE : real = 0.4;

TYPE
    typeTableauProbabilites=array[1..44] of real;
    typeLongueListeEntier = array[1..1936] of integer;
    typeLongueListe2Entier = array[1..1936,1..2] of integer;
    typeLongueListeReel = array[1..1936] of real;
    typeRangBigramme = array[1..2] of integer;
    typeRangTrigramme = array[1..3] of integer;
    
VAR
    action : integer = 1;
    nbElements, tailleMot : integer;
    nomFichier : string = '';

PROCEDURE razTabEntier(var tableau : typeLongueListeEntier);
VAR
   i : integer;
BEGIN
   FOR i := 1 TO 1936 DO tableau[i] := 0;
END;

PROCEDURE razTabEntier2(var tableau : typeLongueListe2Entier);
VAR
   i,j : integer;
BEGIN
   FOR i := 1 TO 1936 DO FOR j := 1 TO 2 DO tableau[i,j] := 0;
END;

PROCEDURE razTabReel(var tableau : typeLongueListeReel);
VAR
   i : integer;
BEGIN
   FOR i := 1 TO 1936 DO tableau[i] := 0;
END;



(* =============================================================================================================================================== *)
(* ============================================================= AIDE EN LIGNE  ================================================================== *)
(* =============================================================================================================================================== *)

(*************************************************************************************************************************
* Cette procédure affiche à l'écran le manuel d'utilisation de l'application
**************************************************************************************************************************
*)
PROCEDURE AfficheManuel;
BEGIN
    writeln();
    writeln('NAME');
    writeln('       projet - la machine à inventer des mots');writeln();
    writeln('SYNOPSIS');
    writeln('       projet [OPTION]... FILE');writeln();
    writeln('DESCRIPTION');
    writeln('       Génère des mots ou des phrases à partir du dictionnaire FILE.');writeln();
    writeln('       -a     Utilise la méthode aléatoire pour générer les mots.');writeln();
    writeln('       -d     Utilise la méthode des digrammes pour générer les mots.');writeln();
    writeln('       -t     Utilise la méthode des trigrammes pour générer les mots.');writeln();
    writeln('       -p     Génère une phrase (en utilisant la méthode des trigrammes).');writeln();
    writeln('       -n NB  Génère NB mots (par défaut génère 100 mots.');writeln();
    writeln('       -s NB  Affiche uniquement des mots de NB caractères.');writeln();
    writeln('       -h     Affiche cette aide et quitte.');writeln();
    writeln('AUTHORS');
    writeln('       Écrit par Cem Haligur');
END;

(* =============================================================================================================================================== *)
(* ==================================================== ARGUMENTS DU PROGRAMME  ================================================================== *)
(* =============================================================================================================================================== *)


(*************************************************************************************************************************
* Cette fonction récupère la valeur numérique d'un argument de la ligne de commande et s'assure de sa validité.
**************************************************************************************************************************
*)
FUNCTION recupereArgNum(var iarg : integer; longueurListe : integer; optTxt : String) : integer;
VAR     valeur, iCode : integer;
BEGIN
    valeur := 0;
    IF (longueurListe > iarg) THEN
    BEGIN
      Val(ParamStr(iarg+1),valeur, iCode);
      IF ( iCode <> 0 ) THEN
        BEGIN
           Writeln('### Erreur de lecture de la valeur de l''option ',optTxt,'). Valeur obtenue : ',ParamStr(iarg+1)[iCode]);
           AfficheManuel;
           halt;
        END
      ELSE
        IF ( valeur <= 0 ) THEN
          BEGIN Writeln('=== Attention : valeur incorrecte pour l''option ',optTxt,' (',ParamStr(iarg+1),')'); writeln('=== La valeur par défaut sera utilisée.') END
        ELSE
          iarg := iarg +1;
    END
    ELSE
      BEGIN writeln('=== Attention : aucune valeur définie pour l''option ',optTxt); writeln('### La valeur par défaut sera utilisée.'); END;
    recupereArgNum := valeur;
END;

(*************************************************************************************************************************
* Cette procédure vérifie si un fichier est bien présent pour les options (cas di/trigramme).
**************************************************************************************************************************
*)
PROCEDURE verifieCoherence(nomFichier : string; action : integer);
BEGIN
    CASE action OF
      2, 3 : IF (  nomFichier = '' ) THEN
             BEGIN
               writeln('### ERREUR : Aucun fichier n''a été indiqué indiqué pour l''option choisie ("-d" ou "-t").');
               halt;
             END;
    END
END;

(*************************************************************************************************************************
* Cette procédure parcours la liste des paramètres et :
* A) Définit le type de calcul qui sera utilisé :
*    1 : génération de mots selon une méthode aléatoire ;
*    2 : génération de mots selon une méthode de digrammes ;
*    3 : génération de mots selon une méthode de trigrammes ;
*    4 : génération de phrase selon une méthode de trigrammes ;
*  
* B) Récupère également les valeurs possibles de la taille des mots (tailleMots)
*  et du nombre de mots (nbMots).
*
* C) Affiche éventuellement l'aide sur 'utilisation du programme
**************************************************************************************************************************
*)
PROCEDURE definirAction(var action : integer; var nomFichier : string; var nbMots, tailleMot : integer; longueurListe : integer);
VAR
    iarg : integer = 0;
    phrase : boolean = false;
BEGIN
    action := 0;
	WHILE iarg < longueurListe DO
	BEGIN
	  iarg := iarg +1 ;
(*    Lecture des arguments optionnels : *)
      CASE ParamStr(iarg) OF
		'-a' : action := 1;
		'-d' : action := 2;
		'-t' : action := 3;
		'-p' : phrase := true;
		'-n' : nbMots := recupereArgNum(iarg,longueurListe,'-n');
		'-s' : tailleMot := recupereArgNum(iarg,longueurListe,'-s');
		'-h' : action := 0;
(*    Lecture du nom de fichier *)
	  ELSE
		nomFichier := ParamStr(iarg);
	  END;
	END;
	
	IF (nbMots <= 0 ) THEN nbMots := NB_MOTS_DEFAUT;
	IF (tailleMot <= 0 ) THEN tailleMot := TAILLE_MOT_INIT;
	verifieCoherence(nomFichier, action);
	
	IF (phrase) THEN action := 4;
END;

(* =============================================================================================================================================== *)
(* ========================================== OUTILS POUR LES DI/TRIGRAMMES ====================================================================== *)
(* =============================================================================================================================================== *)



(*************************************************************************************************************************
* Procédure de tri simple de deux liste conjointe. Le critére de tri est donnée par la première liste 
* La deuxième liste est une liste simple
**************************************************************************************************************************
*)
PROCEDURE trierListesProba(cntProba :integer; var listeProbabilites  : typeLongueListeReel; var listeRangs  : typeLongueListeEntier);
VAR
    i,j,rang : integer;
    probabilite : real;
BEGIN
    FOR j:= 2 TO cntProba DO
    BEGIN
       probabilite := listeProbabilites[j];
       rang := listeRangs[j];
       i := j-1;
       WHILE ( (listeProbabilites[i] > probabilite) AND ( i > 0) ) DO
       BEGIN
          listeProbabilites[i+1] := listeProbabilites[i];
          listeRangs[i+1] := listeRangs[i];
          i := i - 1;
       END;
       listeProbabilites[i+1] := probabilite;
       listeRangs[i+1] := rang;
    END;
END;

(*************************************************************************************************************************
*  Procédure de tri simple de deux liste conjointe. Le critére de tri est donnée par la première liste 
* La deuxième liste est une liste double
**************************************************************************************************************************
*)
PROCEDURE trierListesProba2(cntProba :integer; var listeProbabilites  : typeLongueListeReel; var listeRangs  : typeLongueListe2Entier);
VAR
    i,j,rang1,rang2 : integer;
    probabilite : real;
BEGIN
    FOR j:= 2 TO cntProba DO
    BEGIN
       probabilite := listeProbabilites[j];
       rang1 := listeRangs[j,1];
       rang2 := listeRangs[j,2];
       i := j-1;
       WHILE ( (listeProbabilites[i] > probabilite) AND ( i > 0) ) DO
       BEGIN
          listeProbabilites[i+1] := listeProbabilites[i];
          listeRangs[i+1,1] := listeRangs[i,1];
          listeRangs[i+1,2] := listeRangs[i,2];
          i := i - 1;
       END;
       listeProbabilites[i+1] := probabilite;
       listeRangs[i+1,1] := rang1;
       listeRangs[i+1,2] := rang2;
    END;
END;

(*************************************************************************************************************************
* Cette fonction renvoi un rang choisi parmi tailleRang selon une fonction de probabilité (à définir ici selon les besoins
**************************************************************************************************************************
*)
FUNCTION niemeProba(intervalle : integer; fraction : real) : integer;
BEGIN
(* Ici on tire un rang dans une portion de l'intervalle le plus élevé donnée par "fraction" : *)
     niemeProba := intervalle - random(round(intervalle * fraction));
END;


(* =============================================================================================================================================== *)
(* =========================================================== CAS DES BIGRAMMES   =============================================================== *)
(* =============================================================================================================================================== *)

(* Note : Versions dérivées directement de celles utilisisée pour la méthode des trigrammes. Il faudrait reprendre les fonctions pour les optimiser en écriture. *)

(*************************************************************************************************************************
* Cette fonction choisit une première lettre selon une probabilité vraisemblable (méthode des digrammes).
* Elle choisit au hasard une probabilité pour le rang selon la fraction supérieure de l'intervalle des rangs ordonnées en probabilités croissante (fraction définie apr une constante).
* rangLettre : rang de la lettre dont on examine les probabilités.
* Renvoie 0 si aucun cas possible n'a été trouvé.
**************************************************************************************************************************
*)
FUNCTION choisirPremiereLettreBgm(tableauProbabilites : typeTableauProbabiliteBigrammes; fractionProba : real) : integer;
VAR
	listeProbabilites  : typeLongueListeReel;
	listeRangs  : typeLongueListeEntier;
	i, i0, j, niemeProba, cntProba, indexProba : integer;
	
BEGIN
   
    choisirPremiereLettreBgm := 0;

(* Comptage des probabilités non nulles pour toutes les possibilités de l'alphabet : *)
    razTabEntier(listeRangs);
    razTabReel(listeProbabilites);
    cntProba := 0;
    i0 := 0;
    FOR i := 1 TO TAILLE_TAB_PROBA DO
      FOR j := 1 TO TAILLE_TAB_PROBA DO
           IF ( tableauProbabilites[i,j,2] <> 0.0 ) THEN
              BEGIN
                IF ( i0 <> i ) THEN inc(cntProba);
                listeProbabilites[cntProba] := listeProbabilites[i] + tableauProbabilites[i,j,2];
                listeRangs[cntProba] := i;
                i0 := i;
              END;
    IF (cntProba = 0) THEN BEGIN writeln('### ERREUR : Pas de probabilité trouvée pour choisir la lettre initiale !'); halt; END;
    trierListesProba(cntProba,listeProbabilites,listeRangs);

(* Choix du n-ième niveau de probabilité requis sur les probabilités trouvées. On se limite aux FRACTION_PROBA de probabilités les plus élevées pour le moment *)
    niemeProba := cntProba - random(round(cntProba * fractionProba));
    
    indexProba := niemeProba;
    
    choisirPremiereLettreBgm := listeRangs[indexProba];

END;

(*************************************************************************************************************************
* Cette fonction renvoie un rang selon une certaine probabilité parmi ceux existants (méthode des digrammes).
* Cas Initial.
* Elle choisit au hasard une probabilité pour le rang selon la fraction supérieure de l'intervalle des rangs ordonnées en probabilités croissante (fraction définie apr une constante).
* rangLettre : rang de la lettre dont on examine les probabilités.
* Renvoie 0 si aucun cas possible n'a été trouvé.
**************************************************************************************************************************
*)
FUNCTION choisirDansRangInitialBgm(rangLettre : integer; tableauProbabilites : typeTableauProbabiliteBigrammes; fractionProba : real) : typeRangBigramme;
VAR
	listeProbabilites  : typeLongueListeReel;
	listeIndexSuivant  : typeLongueListe2Entier;
	i, i0, cntProba, indexProba : integer;
	
BEGIN
    choisirDansRangInitialBgm[1] := TAILLE_TAB_PROBA;
    choisirDansRangInitialBgm[2] := TAILLE_TAB_PROBA;
(* Comptage des probabilités non nulles : *)
    razTabEntier2(listeIndexSuivant);
    razTabReel(listeProbabilites);
    cntProba := 0;
    i0 := 0;
    FOR i := 1 TO TAILLE_TAB_PROBA DO
    BEGIN
      IF ( tableauProbabilites[rangLettre,i,2] <> 0.0 ) THEN
              BEGIN
                IF ( i0 <> i ) THEN inc(cntProba);
                listeProbabilites[cntProba] := listeProbabilites[cntProba] + tableauProbabilites[rangLettre,i,2];
                listeIndexSuivant[cntProba,1] := i;
                i0 := i;
              END;
    END;
    IF (cntProba = 0) THEN exit;
    trierListesProba2(cntProba,listeProbabilites,listeIndexSuivant);
    
(* Choix du n-ième niveau de probabilité requis sur les probabilités trouvées. On se limite aux FRACTION_PROBA de probabilités les plus élevées pour le moment *)
    indexProba := niemeProba(cntProba,fractionProba);
        
    choisirDansRangInitialBgm[1] := rangLettre;
    choisirDansRangInitialBgm[2] := listeIndexSuivant[indexProba,1];
    
END;

(*************************************************************************************************************************
* Cette fonction renvoie un rang selon une certaine probabilité parmi ceux existants (méthode des digrammes).
* Cas intermediaire.
* Elle choisit au hasard une probabilité pour le rang selon la fraction supérieure de l'intervalle des rangs ordonnées en probabilités croissante (fraction définie apr une constante).
* rangLettre : rang de la lettre dont on examine les probabilités.
* Renvoie 0 si aucun cas possible n'a été trouvé.
**************************************************************************************************************************
*)
FUNCTION choisirDansRangIntermediaireBgm(rangLettre : typeRangBigramme; tableauProbabilites : typeTableauProbabiliteBigrammes; fractionProba : real) : typeRangBigramme;
VAR
	listeProbabilites  : typeLongueListeReel;
	listeIndexSuivant  : typeLongueListeEntier;
	i, i0, cntProba, indexProba : integer;
	
BEGIN
    choisirDansRangIntermediaireBgm[1] := TAILLE_TAB_PROBA;
    choisirDansRangIntermediaireBgm[2] := TAILLE_TAB_PROBA;
    
(* Comptage des probabilités non nulles : *)
    razTabEntier(listeIndexSuivant);
    razTabReel(listeProbabilites);
    cntProba := 0;
    i0 := 0;
    FOR i := 1 TO TAILLE_TAB_PROBA DO
    BEGIN
           IF ( tableauProbabilites[rangLettre[2],i,1] <> 0.0 ) THEN
              BEGIN
                 IF ( i0 <> i ) THEN inc(cntProba);
                listeProbabilites[cntProba] := listeProbabilites[cntProba] + tableauProbabilites[rangLettre[2],i,1];
                listeIndexSuivant[cntProba] := i;
                i0 := i;
              END;
    END;
    IF (cntProba = 0) THEN exit;

    trierListesProba(cntProba,listeProbabilites,listeIndexSuivant);

(* Choix du n-ième niveau de probabilité requis sur les probabilités trouvées. On se limite aux FRACTION_PROBA de probabilités les plus élevées pour le moment *)
    indexProba := niemeProba(cntProba,fractionProba);
    
    choisirDansRangIntermediaireBgm[1] := rangLettre[2];
    choisirDansRangIntermediaireBgm[2] := listeIndexSuivant[indexProba];
    
END;


(*************************************************************************************************************************
* Cette fonction renvoie un rang selon une certaine probabilité parmi ceux existants (méthode des digrammes).
* Cas final.
* Elle choisit au hasard une probabilité pour le rang selon la fraction supérieure de l'intervalle des rangs ordonnées en probabilités croissante (fraction définie apr une constante).
* rangLettre : rang de la lettre dont on examine les probabilités.
* Renvoie 0 si aucun cas possible n'a été trouvé.
**************************************************************************************************************************
*)
FUNCTION choisirDansRangFinalBgm(rangLettre : typeRangBigramme; tableauProbabilites : typeTableauProbabiliteBigrammes; fractionProba : real) : typeRangBigramme;
VAR
	listeProbabilites  : typeLongueListeReel;
	listeIndexSuivant  : typeLongueListeEntier;
	i, i0, cntProba, indexProba : integer;
	
BEGIN
    choisirDansRangFinalBgm[1] := TAILLE_TAB_PROBA;
    choisirDansRangFinalBgm[2] := TAILLE_TAB_PROBA;

(* Comptage des probabilités non nulles : *)
    razTabEntier(listeIndexSuivant);
    razTabReel(listeProbabilites);
    cntProba := 0;
    i0 := 0;
    FOR i := 1 TO TAILLE_TAB_PROBA DO
           IF ( tableauProbabilites[rangLettre[2],i,3] <> 0.0 ) THEN
              BEGIN
                IF ( i0 <> i ) THEN inc(cntProba);
                listeProbabilites[cntProba] := listeProbabilites[i] + tableauProbabilites[rangLettre[2],i,3];
                listeIndexSuivant[cntProba] := i;
                i0 := i;
             END;
    IF (cntProba = 0) THEN exit;

    trierListesProba(cntProba,listeProbabilites,listeIndexSuivant);

(* Choix du n-ième niveau de probabilité requis sur les probabilités trouvées. On se limite aux FRACTION_PROBA de probabilités les plus élevées pour le moment *)
    indexProba := niemeProba(cntProba,fractionProba);
    
    choisirDansRangFinalBgm[1] := rangLettre[2];
    choisirDansRangFinalBgm[2] := listeIndexSuivant[indexProba];
    
END;


(*************************************************************************************************************************
* Fonction d'entrée générique pour l'appel de la véritable fonction ou routine qui crée des mots selon la méthode des trigrammes
**************************************************************************************************************************
*)
FUNCTION creerUnMotBigramme(tailleMot : integer; tableauProbabiliteBigrammes: typeTableauProbabiliteBigrammes; fractionProba : real) : WideString;
VAR
	rangDebut : integer;
	rangCourant,rangSuivant : typeRangBigramme;
//	cntProtection : integer;
    
BEGIN
  
  rangDebut := 1;
  creerUnMotBigramme := '';
  
  rangDebut := choisirPremiereLettreBgm(tableauProbabiliteBigrammes, fractionProba);
  
  rangSuivant := choisirDansRangInitialBgm(rangDebut,tableauProbabiliteBigrammes, fractionProba);
  creerUnMotBigramme := creerUnMotBigramme + alphabet[rangSuivant[1]] + alphabet[rangSuivant[2]];
//  writeln('Mot initial : "', creerUnMotBigramme,'"');

(* Intermédiaire :
*)  
  WHILE ( (rangSuivant[2] > 0 ) AND (rangSuivant[2] < TAILLE_TAB_PROBA ) AND ( Length(creerUnMotBigramme) < tailleMot -1 ) ) DO
  BEGIN
//    REPEAT
      rangCourant := rangSuivant;
      rangSuivant := choisirDansRangIntermediaireBgm(rangCourant,tableauProbabiliteBigrammes, fractionProba);
//    UNTIL ( ( rangSuivant[1] <> rangCourant[1] ) AND ( rangSuivant[2] <> rangCourant[2] ));
    IF ( (rangSuivant[2] < TAILLE_TAB_PROBA ) AND  (rangSuivant[2] > 0 ) ) THEN creerUnMotBigramme := creerUnMotBigramme + alphabet[rangSuivant[2]];
//    writeln('Mot intermédiaire : "', creerUnMotBigramme,'"');
  END;
  
  IF ( (rangSuivant[2] <= 0 ) OR (rangSuivant[2] >= TAILLE_TAB_PROBA ) ) THEN rangSuivant := rangCourant;

(* Terminaison :
*)
//  cntProtection := 0;
//  REPEAT 
//    inc(cntProtection);
    rangCourant := rangSuivant;
    rangSuivant := choisirDansRangFinalBgm(rangCourant,tableauProbabiliteBigrammes, fractionProba);
//  UNTIL ( (rangSuivant[2] <= 0 ) OR (rangSuivant[2] >= TAILLE_TAB_PROBA ) OR (rangSuivant[2] <> rangCourant[2]) OR (cntProtection > PROTECTION_BOUCLES) );
  
  IF ( (rangSuivant[2] < TAILLE_TAB_PROBA ) AND  (rangSuivant[2] > 0 ) AND ( Length(creerUnMotBigramme) < tailleMot ) ) THEN creerUnMotBigramme := creerUnMotBigramme + alphabet[rangSuivant[2]];
  
//  writeln('Mot final : "', creerUnMotBigramme,'"');
  
END;




(* =============================================================================================================================================== *)
(* =========================================================== CAS DES TRIGRAMMES   ============================================================== *)
(* =============================================================================================================================================== *)


(*************************************************************************************************************************
* Cette fonction choisit une première lettre selon une probabilité vraisemblable (méthode des trigrammes).
* Elle choisit au hasard une probabilité pour le rang selon la fraction supérieure de l'intervalle des rangs ordonnées en probabilités croissante (fraction définie apr une constante).
* rangLettre : rang de la lettre dont on examine les probabilités.
* Renvoie 0 si aucun cas possible n'a été trouvé.
**************************************************************************************************************************
*)
FUNCTION choisirPremiereLettreTrg(tableauProbabilites : typeTableauProbabiliteTrigrammes; fractionProba : real) : integer;
VAR
	listeProbabilites  : typeLongueListeReel;
	listeRangs  : typeLongueListeEntier;
	i, i0, j, k, niemeProba, cntProba, indexProba : integer;
	
BEGIN
   
    choisirPremiereLettreTrg := 0;

(* Comptage des probabilités non nulles pour toutes les possibilités de l'alphabet : *)
    razTabEntier(listeRangs);
    razTabReel(listeProbabilites);
    cntProba := 0;
    i0 := 0;
    FOR i := 1 TO TAILLE_TAB_PROBA DO
      FOR j := 1 TO TAILLE_TAB_PROBA DO
        FOR k := 1 TO TAILLE_TAB_PROBA DO
           IF ( tableauProbabilites[i,j,k,2] <> 0.0 ) THEN
              BEGIN
                IF ( i0 <> i ) THEN inc(cntProba);
                listeProbabilites[cntProba] := listeProbabilites[i] + tableauProbabilites[i,j,k,2];
                listeRangs[cntProba] := i;
                i0 := i;
              END;
    IF (cntProba = 0) THEN BEGIN writeln('### ERREUR : Pas de probabilité trouvée pour choisir la lettre initiale !'); halt; END;
    trierListesProba(cntProba,listeProbabilites,listeRangs);
    
(* Choix du n-ième niveau de probabilité requis sur les probabilités trouvées. On se limite aux FRACTION_PROBA de probabilités les plus élevées pour le moment *)
    niemeProba := cntProba - random(round(cntProba * fractionProba));
    
    indexProba := niemeProba;
    
    choisirPremiereLettreTrg := listeRangs[indexProba];
    
END;

(*************************************************************************************************************************
* Cette fonction renvoie un rang selon une certaine probabilité parmi ceux existants (méthode des trigrammes).
* Cas Initial.
* Elle choisit au hasard une probabilité pour le rang selon la fraction supérieure de l'intervalle des rangs ordonnées en probabilités croissante (fraction définie apr une constante).
* rangLettre : rang de la lettre dont on examine les probabilités.
* Renvoie 0 si aucun cas possible n'a été trouvé.
**************************************************************************************************************************
*)
FUNCTION choisirDansRangInitialTrg(rangLettre : integer; tableauProbabilites : typeTableauProbabiliteTrigrammes; fractionProba : real) : typeRangBigramme;
VAR
	listeProbabilites  : typeLongueListeReel;
	listeIndexSuivant  : typeLongueListe2Entier;
	i, i0, j, cntProba, indexProba : integer;
	
BEGIN
    choisirDansRangInitialTrg[1] := TAILLE_TAB_PROBA;
    choisirDansRangInitialTrg[2] := TAILLE_TAB_PROBA;

(* Comptage des probabilités non nulles : *)
    razTabEntier2(listeIndexSuivant);
    razTabReel(listeProbabilites);
    cntProba := 0;
    i0 := 0;
    FOR i := 1 TO TAILLE_TAB_PROBA DO
    BEGIN
      FOR j := 1 TO TAILLE_TAB_PROBA DO
         IF ( tableauProbabilites[rangLettre,i,j,2] <> 0.0 ) THEN
              BEGIN
                IF ( i0 <> i ) THEN inc(cntProba);
                listeProbabilites[cntProba] := listeProbabilites[cntProba] + tableauProbabilites[rangLettre,i,j,2];
                listeIndexSuivant[cntProba,1] := i;
                listeIndexSuivant[cntProba,2] := j;
                i0 := i;
              END;
    END;
    
    IF (cntProba = 0) THEN exit;
    
    trierListesProba2(cntProba,listeProbabilites,listeIndexSuivant);
    
(* Choix du n-ième niveau de probabilité requis sur les probabilités trouvées. On se limite aux FRACTION_PROBA de probabilités les plus élevées pour le moment *)
    indexProba := niemeProba(cntProba,fractionProba);
        
    choisirDansRangInitialTrg[1] := rangLettre;
    choisirDansRangInitialTrg[2] := listeIndexSuivant[indexProba,1];
    
END;

(*************************************************************************************************************************
* Cette fonction renvoie un rang selon une certaine probabilité parmi ceux existants (méthode des trigrammes).
* Cas intermediaire.
* Elle choisit au hasard une probabilité pour le rang selon la fraction supérieure de l'intervalle des rangs ordonnées en probabilités croissante (fraction définie apr une constante).
* rangLettre : rang de la lettre dont on examine les probabilités.
* Renvoie 0 si aucun cas possible n'a été trouvé.
**************************************************************************************************************************
*)
FUNCTION choisirDansRangIntermediaireTrg(rangLettre : typeRangBigramme; tableauProbabilites : typeTableauProbabiliteTrigrammes; fractionProba : real) : typeRangBigramme;
VAR
	listeProbabilites  : typeLongueListeReel;
	listeIndexSuivant  : typeLongueListeEntier;
	i, i0, cntProba, indexProba : integer;
	
BEGIN
    choisirDansRangIntermediaireTrg[1] := TAILLE_TAB_PROBA;
    choisirDansRangIntermediaireTrg[2] := TAILLE_TAB_PROBA;

(* Comptage des probabilités non nulles : *)
    razTabEntier(listeIndexSuivant);
    razTabReel(listeProbabilites);
    cntProba := 0;
    i0 := 0;
    FOR i := 1 TO TAILLE_TAB_PROBA DO
    BEGIN
//      IF (( tableauProbabilites[rangLettre[1],rangLettre[2],i,1] <> 0.0 ) AND ( tableauProbabilites[rangLettre[1],rangLettre[2],i,2] = 0.0 ) AND ( tableauProbabilites[rangLettre[1],rangLettre[2],i,3] = 0.0 ) ) THEN
      IF ( ( tableauProbabilites[rangLettre[1],rangLettre[2],i,1] <> 0.0 ) ) THEN
         BEGIN
            IF ( i0 <> i ) THEN inc(cntProba);
            listeProbabilites[cntProba] := listeProbabilites[cntProba] + tableauProbabilites[rangLettre[1],rangLettre[2],i,1];
            listeIndexSuivant[cntProba] := i;
            i0 := i;
         END;
    END;
    IF (cntProba = 0) THEN exit;

    trierListesProba(cntProba,listeProbabilites,listeIndexSuivant);
    
//    FOR i := 1 TO cntProba DO
//       writeln('[',alphabet[rangLettre[1]],alphabet[rangLettre[2]],']  "',alphabet[listeIndexSuivant[i]],'"  Probabilité :', 100.0*listeProbabilites[i]:4:3);  
    
(* Choix du n-ième niveau de probabilité requis sur les probabilités trouvées. On se limite aux FRACTION_PROBA de probabilités les plus élevées pour le moment *)
    indexProba := niemeProba(cntProba,fractionProba);
    
    choisirDansRangIntermediaireTrg[1] := rangLettre[2];
    choisirDansRangIntermediaireTrg[2] := listeIndexSuivant[indexProba];
//    writeln('Choix : "',alphabet[choisirDansRangIntermediaireTrg[2]],'"');
    
END;

(*************************************************************************************************************************
* Cette fonction renvoie un rang selon une certaine probabilité parmi ceux existants (méthode des trigrammes).
* Cas final.
* Elle choisit au hasard une probabilité pour le rang selon la fraction supérieure de l'intervalle des rangs ordonnées en probabilités croissante (fraction définie apr une constante).
* rangLettre : rang de la lettre dont on examine les probabilités.
* Renvoie 0 si aucun cas possible n'a été trouvé.
**************************************************************************************************************************
*)
FUNCTION choisirDansRangFinalTrg(rangLettre : typeRangBigramme; tableauProbabilites : typeTableauProbabiliteTrigrammes; fractionProba : real) : typeRangBigramme;
VAR
	listeProbabilites  : typeLongueListeReel;
	listeIndexSuivant  : typeLongueListeEntier;
	i, i0, cntProba, indexProba : integer;
	
BEGIN
    choisirDansRangFinalTrg[1] := TAILLE_TAB_PROBA;
    choisirDansRangFinalTrg[2] := TAILLE_TAB_PROBA;

(* Comptage des probabilités non nulles : *)
    razTabEntier(listeIndexSuivant);
    razTabReel(listeProbabilites);
    cntProba := 0;
    i0 := 0;
    
    FOR i := 1 TO TAILLE_TAB_PROBA DO
       IF ( tableauProbabilites[rangLettre[1],rangLettre[2],i,3] <> 0.0 ) THEN
       BEGIN
          IF ( i0 <> i ) THEN inc(cntProba);
          listeProbabilites[cntProba] := listeProbabilites[i] + tableauProbabilites[rangLettre[1],rangLettre[2],i,3];
          listeIndexSuivant[cntProba] := i;
          i0 := i;
       END;

    IF (cntProba = 0) THEN exit;

    trierListesProba(cntProba,listeProbabilites,listeIndexSuivant);

(* Choix du n-ième niveau de probabilité requis sur les probabilités trouvées. On se limite aux FRACTION_PROBA de probabilités les plus élevées pour le moment *)
    indexProba := niemeProba(cntProba,fractionProba);
    
    choisirDansRangFinalTrg[1] := rangLettre[2];
    choisirDansRangFinalTrg[2] := listeIndexSuivant[indexProba];
    
END;


(*************************************************************************************************************************
* Fonction d'entrée générique pour l'appel de la véritable fonction ou routine qui crée des mots selon la méthode des trigrammes
**************************************************************************************************************************
*)
FUNCTION creerUnMotTrigramme(tailleMot : integer; tableauProbabiliteTrigrammes: typeTableauProbabiliteTrigrammes; fractionProba : real) : WideString;
VAR
	rangDebut : integer;
	rangCourant,rangSuivant : typeRangBigramme;
//	cntProtection : integer;
    
BEGIN  
  rangDebut := 1;
  creerUnMotTrigramme := '';

  rangDebut := choisirPremiereLettreTrg(tableauProbabiliteTrigrammes, fractionProba);

  rangSuivant := choisirDansRangInitialTrg(rangDebut,tableauProbabiliteTrigrammes, fractionProba);
  
  creerUnMotTrigramme := creerUnMotTrigramme + alphabet[rangSuivant[1]] + alphabet[rangSuivant[2]];
//  writeln('Mot initial : "', creerUnMotTrigramme,'"');
  
(* Intermédiaire :
*)  
  WHILE ( (rangSuivant[2] > 0 ) AND (rangSuivant[2] < TAILLE_TAB_PROBA ) AND ( Length(creerUnMotTrigramme) < tailleMot - 1 ) ) DO
  BEGIN
    REPEAT
      rangCourant := rangSuivant;
      rangSuivant := choisirDansRangIntermediaireTrg(rangCourant,tableauProbabiliteTrigrammes, fractionProba);
    UNTIL ( ( rangSuivant[1] <> rangCourant[1] ) AND ( rangSuivant[2] <> rangCourant[2] ));
    IF ( (rangSuivant[2] < TAILLE_TAB_PROBA ) AND  (rangSuivant[2] > 0 ) ) THEN creerUnMotTrigramme := creerUnMotTrigramme + alphabet[rangSuivant[2]];
//    writeln('Mot intermédiaire : "', creerUnMotTrigramme,'"');
  END;
  
  IF ( (rangSuivant[2] <= 0 ) OR (rangSuivant[2] >= TAILLE_TAB_PROBA ) ) THEN rangSuivant := rangCourant;


(* Terminaison :
*)
//  cntProtection := 0;
//  REPEAT 
//    inc(cntProtection);
    rangCourant := rangSuivant;
    rangSuivant := choisirDansRangFinalTrg(rangCourant,tableauProbabiliteTrigrammes, fractionProba);
//  UNTIL ( (rangSuivant[2] <= 0 ) OR (rangSuivant[2] >= TAILLE_TAB_PROBA ) OR (rangSuivant[2] <> rangCourant[2]) OR (cntProtection > PROTECTION_BOUCLES) );
  
  IF ( (rangSuivant[2] < TAILLE_TAB_PROBA ) AND  (rangSuivant[2] > 0 ) AND ( Length(creerUnMotTrigramme) < tailleMot ) ) THEN creerUnMotTrigramme := creerUnMotTrigramme + alphabet[rangSuivant[2]];
//   writeln('Mot final : "', creerUnMotTrigramme,'"');

END;


(* =============================================================================================================================================== *)
(* ======================================================== CONSTRUCTION DE MOTS   =============================================================== *)
(* =============================================================================================================================================== *)



(*************************************************************************************************************************
* Cette fonction crée un simple mot aléatoire.
**************************************************************************************************************************
*)
FUNCTION creeMotAleatoire(tailleMot : Integer) : WideString;
VAR i:Integer;
	motAleatoire:WideString; 
BEGIN
   i:=0;
   motAleatoire:='';
   REPEAT
       i:=i+1;
	   motAleatoire:=motAleatoire + alphabet[random(43)];
    UNTIL ( i = tailleMot );
    creeMotAleatoire:=motAleatoire;
END;

(*************************************************************************************************************************
* Procédure qui affiche simplement une liste de "nombreMots" mots aléatoires de longueur "taille".
**************************************************************************************************************************
*)
PROCEDURE motsAleatoires(nbMots, tailleMotRef : integer);
VAR
	i, tailleDuMot : integer;
	motAleatoire : WideString;
BEGIN
   writeln('Création de ',nbMots,' mot(s) selon la méthode aléatoire... ');

   IF ( nbMots >= NB_MOTS_INIT ) THEN
   BEGIN
     writeln('Mot(s) créé(s) : ');
     FOR i := 1 TO nbMots DO
     BEGIN
        IF ( tailleMotRef <= 0 ) THEN
            tailleDuMot := random(TAILLE_MAX_MOT) + TAILLE_MIN_MOT
        ELSE
            tailleDuMot := tailleMotRef;
        motAleatoire := creeMotAleatoire(tailleDuMot);
        Writeln('[',i,'] : ',motAleatoire);
     END;
   END
   ELSE
     writeln('*** Aucun mot n''a pu être créé. Le nombre de mots demandé valant : ',nbMots);

END;



(*************************************************************************************************************************
* Cette procédure crée et affiche un ou plusieurs mot avec la méthode des digrammes.
**************************************************************************************************************************
*)
PROCEDURE creerMotsParBigramme(nomFichier : string; nbMots, tailleMotRef : integer);
VAR
   leMot : WideString;
   tailleDuMot, i, cntProtection : integer;
   tableauNombreBigrammes : typeTableauNombreBigrammes;
   tableauProbabiliteBigrammes : typeTableauProbabiliteBigrammes;
   
BEGIN
   
   writeln('Création de ',nbMots,' mot(s) selon la méthode des digrammes... ');

   writeln('Analyse du fichier de mots "',nomFichier,'"...');
   tableauNombreBigrammes:=occurrencesBigrammesDictionnaire(nomFichier);
   tableauProbabiliteBigrammes:=probabilitesBigrammesDictionnaire(tableauNombreBigrammes);

   IF ( nbMots >= NB_MOTS_INIT ) THEN
   BEGIN
     writeln('Mot(s) créé(s) : ');
     FOR i := 1 TO nbMots DO
     BEGIN
        cntProtection := 0;

        IF ( tailleMotRef <= 0 ) THEN
            tailleDuMot := random(TAILLE_MAX_MOT) + TAILLE_MIN_MOT
        ELSE
            tailleDuMot := tailleMotRef;
        REPEAT
           leMot := creerUnMotBigramme(tailleDuMot,tableauProbabiliteBigrammes,FRACTION_PROBA_MOT);
           Inc(cntProtection); 
        UNTIL ( ( Length(leMot) >= tailleDuMot ) OR (cntProtection > PROTECTION_BOUCLES) );
        IF  ( cntProtection > PROTECTION_BOUCLES ) THEN
          writeln('[',i,'] : ',leMot,' {limite maximale de tentatives atteinte (',PROTECTION_BOUCLES,') pour une longueur de ',tailleDuMot,' }')
        ELSE
          writeln('[',i,'] : ',leMot);
     END;
   END
   ELSE
     writeln('*** Aucun mot n''a pu être créé. Le nombre de mots demandé valant : ',nbMots);
END;



(*************************************************************************************************************************
* Cette procédure crée et affiche un ou plusieurs mot avec la méthode des trigrammes.
**************************************************************************************************************************
*)
PROCEDURE creerMotsParTrigramme(nomFichier : string; nbMots, tailleMotRef : integer);
VAR
   leMot : WideString;
   tailleDuMot, i, cntProtection : integer;
   tableauNombreTrigrammes : typeTableauNombreTrigrammes;
   tableauProbabiliteTrigrammes : typeTableauProbabiliteTrigrammes;
   
BEGIN
   
   writeln('Création de ',nbMots,' mot(s) selon la méthode des trigrammes... ');

   writeln('Analyse du fichier de mots "',nomFichier,'"...');
   tableauNombreTrigrammes:=occurrencesTrigrammesDictionnaire(nomFichier);
   tableauProbabiliteTrigrammes:=probabilitesTrigrammesDictionnaire(tableauNombreTrigrammes);

   IF ( nbMots >= NB_MOTS_INIT ) THEN
   BEGIN
     writeln('Mot(s) créé(s) : ');
     FOR i := 1 TO nbMots DO
     BEGIN
        cntProtection := 0;

        IF ( tailleMotRef <= 0 ) THEN
            tailleDuMot := random(TAILLE_MAX_MOT) + TAILLE_MIN_MOT
        ELSE
            tailleDuMot := tailleMotRef;
        REPEAT
           leMot := creerUnMotTrigramme(tailleDuMot,tableauProbabiliteTrigrammes,FRACTION_PROBA_MOT);
           Inc(cntProtection); 
        UNTIL ( ( Length(leMot) >= tailleDuMot ) OR (cntProtection > PROTECTION_BOUCLES) );
        IF  ( cntProtection > PROTECTION_BOUCLES ) THEN
          writeln('[',i,'] : ',leMot,' {limite maximale de tentatives atteinte (',PROTECTION_BOUCLES,') pour une longueur de ',tailleDuMot,' }')
        ELSE
          writeln('[',i,'] : ',leMot);
     END;
   END
   ELSE
     writeln('*** Aucun mot n''a pu être créé. Le nombre de mots demandé valant : ',nbMots);
END;


(* =============================================================================================================================================== *)
(* ======================================================== CONSTRUCTION DE PHRASES   ============================================================ *)
(* =============================================================================================================================================== *)


(* Cette procédure vérifie les élisions possibles de l'article
* NOTE IMPORTANTE : C'est juste une ébauche non utilisée pour un développement futur des améliorations possibles de la construction de la phrase.
*)
PROCEDURE verifierElision(var article : WideString; sujet : WideString);
VAR 
    terme : WideString;
    art1 : WideString = '';
    i : integer;
BEGIN
   terme := article + ' ';
   
   IF ( article[Length(article)] <> APOSTROPHE ) THEN
     CASE article[Length(article)] OF
         'a', 'e', 'i', 'o', 'u', 'y' : CASE sujet[1] OF
                                      'a', 'e', 'i', 'o', 'u', 'y', 'à', 'â', 'è', 'ê', 'ë', 'î', 'ï', 'ô', 'ù', 'û', 'ü' :
                                      BEGIN
                                         FOR i := 1 TO (Length(article) - 1) DO art1 := art1 + article[i];
                                         terme := art1 + APOSTROPHE;
                                      END;
                                   END;
     END
   ELSE
     terme := article;

   article := terme;
   
END;

(*************************************************************************************************************************
* Les fonctions suivantes utilisent un nom de fichier pour l'analyse lexicographique utilisée pour chaque type de mot.
* Elles peuvent éventuellement utiliser le nombre grammatical pour créer des pluriels (nom et adjectifs) ou des
* conjugaisons adaptées (verbes).
**************************************************************************************************************************
*)

(* Cette fonction crée un article :
*)
FUNCTION creerArticle(nomFichier : string) : WideString;
VAR
   article : WideString;
   tailleArticle, cntProtection : integer;
   tableauNombreTrigrammes : typeTableauNombreTrigrammes;
   tableauProbabiliteTrigrammes : typeTableauProbabiliteTrigrammes;
   
BEGIN
   tailleArticle := random(TAILLE_MAX_ARTICLE) + TAILLE_MIN_ARTICLE;
   IF (tailleArticle >= TAILLE_MAX_ARTICLE ) THEN tailleArticle := TAILLE_MAX_ARTICLE;

//   write('Création de l''article... ');
       
   tableauNombreTrigrammes:=occurrencesTrigrammesDictionnaire(nomFichier);
   tableauProbabiliteTrigrammes:=probabilitesTrigrammesDictionnaire(tableauNombreTrigrammes);
       
   article := creerUnMotTrigramme(tailleArticle,tableauProbabiliteTrigrammes,FRACTION_PROBA_ARTICLE);

   cntProtection := 0;
   REPEAT
       article := creerUnMotTrigramme(tailleArticle,tableauProbabiliteTrigrammes,FRACTION_PROBA_ARTICLE);
       Inc(cntProtection); 
   UNTIL ( ( Length(article) >= tailleArticle ) OR (cntProtection > PROTECTION_BOUCLES) );

//   writeln(article);

   creerArticle := article;
END;


(* Cette fonction crée un nom.
*)
FUNCTION creerNom(nomFichier : string) : WideString;
VAR
   nom : WideString;
   tailleNom, cntProtection: integer;
   tableauNombreTrigrammes : typeTableauNombreTrigrammes;
   tableauProbabiliteTrigrammes : typeTableauProbabiliteTrigrammes;
BEGIN
   tailleNom := random(TAILLE_MAX_NOM) + TAILLE_MIN_NOM;
   IF (tailleNom >= TAILLE_MAX_NOM ) THEN tailleNom := TAILLE_MAX_NOM;

//   write('Création du nom... ');

   tableauNombreTrigrammes:=occurrencesTrigrammesDictionnaire(nomFichier);
   tableauProbabiliteTrigrammes:=probabilitesTrigrammesDictionnaire(tableauNombreTrigrammes);
      
   cntProtection := 0;
   REPEAT
       nom := creerUnMotTrigramme(tailleNom,tableauProbabiliteTrigrammes,FRACTION_PROBA_NOM);
       Inc(cntProtection); 
   UNTIL ( ( Length(nom) >= tailleNom ) OR (cntProtection > PROTECTION_BOUCLES) );

//   writeln(nom);
      
   creerNom := nom;
END;

(* Cette fonction crée un sujet et détermine par là même le nombre (grammatical) de la phrase.
*)
FUNCTION creerSujet(var pluriel : boolean) : WideString;
VAR
   article, nom, groupeNominal : WideString;
   choixArticle : integer; 
   
BEGIN
   pluriel := false;
   article := '';
   
   choixArticle := random(10);
   choixArticle := 10;
   
   IF ( choixArticle > 2 ) THEN article := creerArticle('./DICOS/article.txt');

   IF ( article <> '' ) THEN
   BEGIN
      nom := creerNom('./DICOS/nomCommun.txt');
      IF ( (article[Length(article)] = 's') OR ( article[Length(article)] = 'x' ) ) THEN
      BEGIN
         IF ( ( nom[Length(nom)] <> 's' ) AND ( nom[Length(nom)] <> 'x' ) ) THEN nom := nom + 's';
         pluriel := true;
      END;
   END
   ELSE
      nom := creerNom('./DICOS/nomPropre.txt');

(* Amélioration future désactivée pour le moment :
    IF  (article <> '' ) THEN verifierElision(article, nom);
*)
   article := article + ' ';
   groupeNominal := article + nom;
   groupeNominal[1] := upCase(groupeNominal[1]);
   
   creerSujet := groupeNominal;

END;

(* Cette fonction crée un verbe et le conjuge suivant le nombre du sujet.
*)
FUNCTION creerVerbe(nomFichier : string; var pluriel : boolean) : WideString;
VAR 
   verbe, racine : WideString;
   tailleVerbe, i, cntProtection : integer;
   tableauNombreTrigrammes : typeTableauNombreTrigrammes;
   tableauProbabiliteTrigrammes : typeTableauProbabiliteTrigrammes;
     
BEGIN
   tailleVerbe := random(TAILLE_MAX_VERBE) + TAILLE_MIN_VERBE;
   IF (tailleVerbe >= TAILLE_MAX_VERBE ) THEN tailleVerbe := TAILLE_MAX_VERBE;
   
//   writeln('Création du verbe... ' );
   
   tableauNombreTrigrammes:=occurrencesTrigrammesDictionnaire(nomFichier);
   tableauProbabiliteTrigrammes:=probabilitesTrigrammesDictionnaire(tableauNombreTrigrammes);

   cntProtection := 0;
   REPEAT
       verbe := creerUnMotTrigramme(tailleVerbe,tableauProbabiliteTrigrammes,FRACTION_PROBA_VERBE);
       Inc(cntProtection); 
   UNTIL ( ( Length(verbe) >= tailleVerbe ) OR (cntProtection > PROTECTION_BOUCLES) );

   racine := '';
   FOR i := 1 TO (Length(verbe) - 2) DO racine := racine + verbe[i];
   CASE verbe[Length(verbe) - 1] OF
       'e' : IF (pluriel) THEN verbe := racine +    'ent' ELSE verbe := racine + 'e';
       'i' : IF (pluriel) THEN verbe := racine + 'issent' ELSE verbe := racine + 'it';
       'ï' : IF (pluriel) THEN verbe := racine + 'ïssent' ELSE verbe := racine + 'it';
   END;
   
   creerVerbe := verbe;

//   writeln(verbe);
   
END;

(* Cette fonction crée un adjectif et l'accorde en nombre au sujet.
*)
FUNCTION creerAdjectif(nomFichier : string; var pluriel : boolean) : WideString;
VAR 
   adjectif : WideString;
   tailleAdjectif, cntProtection : integer;
   tableauNombreTrigrammes : typeTableauNombreTrigrammes;
   tableauProbabiliteTrigrammes : typeTableauProbabiliteTrigrammes;
   
BEGIN
   tailleAdjectif := random(TAILLE_MAX_ADJECTIF) + TAILLE_MIN_ADJECTIF;
   IF (tailleAdjectif >= TAILLE_MAX_ADJECTIF ) THEN tailleAdjectif := TAILLE_MAX_ADJECTIF;
   
//   write('Création de l''adjectif... ');

   tableauNombreTrigrammes:=occurrencesTrigrammesDictionnaire(nomFichier);
   tableauProbabiliteTrigrammes:=probabilitesTrigrammesDictionnaire(tableauNombreTrigrammes);

   cntProtection := 0;
   REPEAT
       adjectif := creerUnMotTrigramme(tailleAdjectif,tableauProbabiliteTrigrammes,FRACTION_PROBA_ADJECTIF);
       Inc(cntProtection); 
   UNTIL ( ( Length(adjectif) >= tailleAdjectif ) OR (cntProtection > PROTECTION_BOUCLES) );
   
   IF ( pluriel ) THEN adjectif := adjectif +'s';
   
   creerAdjectif := adjectif;
//   writeln(adjectif);
END;

(* Cette fonction crée un adverbe.
*)
FUNCTION creerAdverbe(nomFichier : string) : WideString;
VAR
   adverbe : WideString;
   tailleAdverbe, cntProtection : integer;
   tableauNombreTrigrammes : typeTableauNombreTrigrammes;
   tableauProbabiliteTrigrammes : typeTableauProbabiliteTrigrammes;
   
BEGIN
   tailleAdverbe := random(TAILLE_MAX_ADVERBE) + TAILLE_MIN_ADVERBE;
   IF (tailleAdverbe >= TAILLE_MAX_ADVERBE ) THEN tailleAdverbe := TAILLE_MAX_ADVERBE;
   
//   write('Création de l''adverbe... ');
   
   tableauNombreTrigrammes:=occurrencesTrigrammesDictionnaire(nomFichier);
   tableauProbabiliteTrigrammes:=probabilitesTrigrammesDictionnaire(tableauNombreTrigrammes);

   cntProtection := 0;
   REPEAT
       adverbe := creerUnMotTrigramme(tailleAdverbe,tableauProbabiliteTrigrammes,FRACTION_PROBA_ADVERBE);
       Inc(cntProtection); 
   UNTIL ( ( Length(adverbe) >= tailleAdverbe ) OR (cntProtection > PROTECTION_BOUCLES) );
   
   creerAdverbe := adverbe;
//   writeln(adverbe);
END;


(*************************************************************************************************************************
* Cette procedure crée une phrase selon la forme retenue :
* catDePhrase = 0 : sujet + verbe
* catDePhrase = 1 : sujet + verbe + adjectif
* catDePhrase = 2 : sujet + verbe + adverbe + adjectif
**************************************************************************************************************************
*)
PROCEDURE creerPhraseType(catDePhrase : integer);
VAR
  sujet, verbe, adjectif, adverbe, laPhrase : WideString;
  pluriel : boolean;
  
BEGIN
   laPhrase := '';
   sujet := '';
   verbe := '';
   adjectif := '';
   adverbe := '';
   pluriel := false;
   
   sujet := creerSujet(pluriel);
   verbe := creerVerbe('./DICOS/verbePremierEtDeuxiemeGroupe.txt',pluriel);
  
   laPhrase := sujet + ' ' + verbe;
   CASE catDePhrase OF
      1 : BEGIN
                adjectif := creerAdjectif('./DICOS/adjectif.txt',pluriel);
                laPhrase := laPhrase + ' ' + adjectif;
          END;
      2 : BEGIN
                adjectif := creerAdjectif('./DICOS/adjectif.txt',pluriel);
                adverbe := creerAdverbe('./DICOS/adverbe.txt');
                laPhrase := laPhrase + ' ' + adverbe + ' ' + adjectif;
          END;
   END;
   
   writeln(laPhrase);
   
END;

(*************************************************************************************************************************
* Cette procédure crée une phrase selon une structure choisie au hasard parmi celles possibles 
**************************************************************************************************************************
*)
PROCEDURE creerUnePhrase();
VAR
    catPhrase : integer;
BEGIN
(* Choix du type de phrase au hasard *)
   catPhrase := random(3);
   creerPhraseType(catPhrase);   
END;


(*************************************************************************************************************************
* Cette procédure crée le nombre de phrases demandées.
**************************************************************************************************************************
*)
PROCEDURE creerPhrase(nbPhrases : integer);
VAR
   i : integer;
BEGIN
   IF ( nbPhrases > 0 ) THEN
   BEGIN
      writeln('Phrase(s) créée(s) : ');
      FOR i := 1 TO nbPhrases DO
      BEGIN
         write('[',i,'] : ');
         creerUnephrase;
      END;
   END;
END;

(* =============================================================================================================================================== *)
(* ======================================================== NOYAU DE L'APPLICATION  ============================================================== *)
(* =============================================================================================================================================== *)
BEGIN
  nbElements := NB_MOTS_DEFAUT;
  tailleMot := TAILLE_MOT_INIT;
  action := 0;
   
  randomize;
   
  WriteLn('Programme: ', ParamStr(0));
  IF ( ParamCount = 0 ) THEN
     AfficheManuel
  ELSE
  BEGIN
    definirAction(action, nomFichier, nbElements, tailleMot, ParamCount);
	CASE action OF
	    0: AfficheManuel;
		1: motsAleatoires(nbElements,tailleMot);
		2: creerMotsParBigramme(nomFichier, nbElements, tailleMot);
		3: creerMotsParTrigramme(nomFichier, nbElements, tailleMot);
		4: creerPhrase(nbElements);
	ELSE
	    AfficheManuel;
	END;
  END;
END.
