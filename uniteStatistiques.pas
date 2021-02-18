unit uniteStatistiques;

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses crt, uniteGestionFichiers, uniteTableaux, uniteOutils;

const
    alphabetFrancais : WideString = 'abcdefghijklmnopqrstuvwxyzàâéèêëîïôùûüÿæœç-';

type typeTableauNombreBigrammes=array[1..44,1..44,1..3] of integer;
type typeTableauNombreTrigrammes=array[1..44,1..44,1..44,1..3] of integer;
type typeTableauProbabiliteBigrammes=array[1..44,1..44,1..3] of real;
type typeTableauProbabiliteTrigrammes=array[1..44,1..44,1..44,1..3] of real;

function probabilitesBigrammesDictionnaire(var tableau: typeTableauNombreBigrammes): typeTableauProbabiliteBigrammes;
function probabilitesTrigrammesDictionnaire(var tableau: typeTableauNombreTrigrammes): typeTableauProbabiliteTrigrammes;
function occurrencesBigrammesDictionnaire(var nomFichier: string) : typeTableauNombreBigrammes;
function occurrencesTrigrammesDictionnaire(var nomFichier: string) : typeTableauNombreTrigrammes;
function totalColonneTableauProbabiliteTrigrammes(var tableau: typeTableauProbabiliteTrigrammes; var colonne: integer): real;

implementation

(*
* Renvoie le rang d'un symbole dans l'alphabet.
* *)
function rangSymboleAlphabet(var symbole: WideChar) : integer; 
var rang: integer=0;
begin
 repeat
	inc(rang);
 until (rang=44) or (alphabetFrancais[rang]=symbole);
 rangSymboleAlphabet:=rang;
end;

(*
* Fait le total de toutes les valeurs contenues dans une colonne d'un tableau de type typeTableauNombreBigrammes
* *)
function totalColonneTableauNombreBigrammes(var tableau: typeTableauNombreBigrammes; var colonne: integer): integer;
var i, j, somme: integer;
begin
 somme:=0;
 for i:=1 to 43 do 
	for j:=1 to 43 do
		somme:=somme + tableau[i, j, colonne];
 totalColonneTableauNombreBigrammes:=somme;
end;

(*
* Fait le total de toutes les valeurs contenues dans une colonne d'un tableau de type typeTableauNombreTrigrammes
* *)
function totalColonneTableauNombreTrigrammes(var tableau: typeTableauNombreTrigrammes; var colonne: integer): integer;
var i, j, k, somme: integer;
begin
 somme:=0;
 for i:=1 to 43 do 
	for j:=1 to 43 do
		for k:=1 to 43 do
			somme:=somme + tableau[i, j, k, colonne];
 totalColonneTableauNombreTrigrammes:=somme;
end;

(*
* Fait le total de toutes les valeurs contenues dans une colonne d'un tableau de type typeTableauProbabiliteBigrammes
* *)
function totalColonneTableauProbabiliteBigrammes(var tableau: typeTableauProbabiliteBigrammes; var colonne: integer): real;
var i, j: integer;
	somme: real;
begin
 somme:=0;
 for i:=1 to 43 do 
	for j:=1 to 43 do
		somme:=somme + tableau[i, j, colonne];
 totalColonneTableauProbabiliteBigrammes:=somme;
end;

(*
* Établit si un tableau de type typeTableauProbabiliteBigrammes a été correctement rempli 
* *)
function verificationTableauProbabiliteBigrammes(var tableau: typeTableauProbabiliteBigrammes): boolean;
var i, j, k: integer;
	somme: real;
begin
 i:=1; j:=1; k:=1;
 somme:=totalColonneTableauProbabiliteBigrammes(tableau, i) + totalColonneTableauProbabiliteBigrammes(tableau, j) + totalColonneTableauProbabiliteBigrammes(tableau, k);
 verificationTableauProbabiliteBigrammes:=((somme-3)<=0.0001);
end;

(*
* Établit si un tableau de type typeTableauProbabiliteTrigrammes a été correctement rempli 
* *)
function verificationTableauProbabiliteTrigrammes(var tableau: typeTableauProbabiliteTrigrammes): boolean;
var i, j, k: integer;
	somme: real;
begin
 i:=1; j:=1; k:=1;
 somme:=totalColonneTableauProbabiliteTrigrammes(tableau, i) + totalColonneTableauProbabiliteTrigrammes(tableau, j) + totalColonneTableauProbabiliteTrigrammes(tableau, k);
 verificationTableauProbabiliteTrigrammes:=((somme-3)<=0.0001);
end;

(*
* Fait le total de toutes les valeurs contenues dans une colonne d'un tableau de type typeTableauProbabiliteTrigrammes
* *)
function totalColonneTableauProbabiliteTrigrammes(var tableau: typeTableauProbabiliteTrigrammes; var colonne: integer): real;
var i, j, k: integer;
	somme:real;
begin
 somme:=0;
 for i:=1 to 43 do 
	for j:=1 to 43 do
		for k:=1 to 43 do
			somme:=somme + tableau[i, j, k, colonne];
 totalColonneTableauProbabiliteTrigrammes:=somme;
end;

(*
* Calcule la probabilité d'apparition des bigrammes contenus dans un fichier dictionnaire,
* à partir d'un tableau contenant le nombre d'occurrences de chacun de ces bigrammes.
* *)
function probabilitesBigrammesDictionnaire(var tableau: typeTableauNombreBigrammes): typeTableauProbabiliteBigrammes;
var i, j, k, l, total: integer;
	tableauProbabiliteBigrammes : typeTableauProbabiliteBigrammes;
begin
 tableauProbabiliteBigrammes:=initialiserTableauProbabiliteBigrammes(tableauProbabiliteBigrammes);
 for i:=1 to 3 do
	begin
		l:=i;
		total:=totalColonneTableauNombreBigrammes(tableau,l);
		if total<>0 then
			for j:=1 to 43 do
				for k:=1 to 43 do
					tableauProbabiliteBigrammes[j, k, i]:=tableau[j, k , i]/total;
	end;
 if not(verificationTableauProbabiliteBigrammes(tableauProbabiliteBigrammes)) then 
	writeln('Attention, le tableau des probabilités semble incohérent...');
 probabilitesBigrammesDictionnaire:=tableauProbabiliteBigrammes;
end;

(*
* Calcule la probabilité d'apparition des trigrammes contenus dans un fichier dictionnaire,
* à partir d'un tableau contenant le nombre d'occurrences de chacun de ces trigrammes.
* *)
function probabilitesTrigrammesDictionnaire(var tableau: typeTableauNombreTrigrammes): typeTableauProbabiliteTrigrammes;
var i, j, k, l, m, total: integer;
	tableauProbabiliteTrigrammes : typeTableauProbabiliteTrigrammes;
begin
 tableauProbabiliteTrigrammes:=initialiserTableauProbabiliteTrigrammes(tableauProbabiliteTrigrammes);
 for i:=1 to 3 do
	begin
		m:=i;
		total:=totalColonneTableauNombreTrigrammes(tableau,m);
		if total<>0 then 
			for j:=1 to 43 do
				for k:=1 to 43 do
					for l:=1 to 43 do
						tableauProbabiliteTrigrammes[j, k, l, i]:=tableau[j, k , l, i]/total;
	end;
 if not(verificationTableauProbabiliteTrigrammes(tableauProbabiliteTrigrammes)) then 
	writeln('Attention, le tableau des probabilités semble incohérent...');
 probabilitesTrigrammesDictionnaire:=tableauProbabiliteTrigrammes;
end;

(*
* Compte les occurences simples, initiales, terminales, des bigrammes dans un fichier
* *)
function occurrencesBigrammesDictionnaire(var nomFichier: string) : typeTableauNombreBigrammes;
var tableau: typeTableauNombreBigrammes;
	compteur, rangPremiereLettre, rangSecondeLettre: integer;
//	temporisateur: integer;
	nombreLignes: integer;
	ligne: WideString;
	fichier: textfile;
begin
// temporisateur:=nombreLignesFichier(nomFichier);
 tableau:=initialiserTableauNombreBigrammes(tableau);
 nombreLignes:=0;
 ouvrirDictionnaire(nomFichier,fichier);
 while not eof(fichier) do
	begin
		inc(nombreLignes);
		readln(fichier, ligne);
		if (length(ligne)>1) then
			for compteur:=1 to length(ligne)-1 do
				begin
					rangPremiereLettre:=rangSymboleAlphabet(ligne[compteur]);
					rangSecondeLettre:=rangSymboleAlphabet(ligne[compteur+1]);
					inc(tableau[rangPremiereLettre, rangSecondeLettre,1]);
					if (compteur=1 ) then inc(tableau[rangPremiereLettre, rangSecondeLettre,2]);
					if (compteur= (length(ligne)-1) ) then inc(tableau[rangPremiereLettre,rangSecondeLettre,3]);
				end;
//		barreProgression(temporisateur, nombreLignes, nomFichier);
	end;
 fermerDictionnaire(nomFichier,fichier);
 occurrencesBigrammesDictionnaire:=tableau;
end;

(*
* Compte les occurences simples, initiales, terminales, des trigrammes dans un fichier
* *)
function occurrencesTrigrammesDictionnaire(var nomFichier: string) : typeTableauNombreTrigrammes;
var tableau: typeTableauNombreTrigrammes;
	compteur, rangPremiereLettre, rangDeuxiemeLettre, rangTroisiemeLettre: integer;
//	temporisateur: integer;
	nombreLignes: integer;
	ligne: WideString;
	fichier: textfile;
begin
// temporisateur:=nombreLignesFichier(nomFichier);
 tableau:=initialiserTableauNombreTrigrammes(tableau);
 nombreLignes:=0;
 ouvrirDictionnaire(nomFichier,fichier);
 while not eof(fichier) do
	begin
		inc(nombreLignes);
		readln(fichier, ligne);
		if (length(ligne)>2) then
			for compteur:=1 to length(ligne)-2 do
				begin
					rangPremiereLettre:=rangSymboleAlphabet(ligne[compteur]);
					rangDeuxiemeLettre:=rangSymboleAlphabet(ligne[compteur+1]);
					rangTroisiemeLettre:=rangSymboleAlphabet(ligne[compteur+2]);
					inc(tableau[rangPremiereLettre, rangDeuxiemeLettre, rangTroisiemeLettre, 1]);
					if ( compteur=1 ) then inc(tableau[rangPremiereLettre, rangDeuxiemeLettre, rangTroisiemeLettre, 2]);
					if ( compteur=(length(ligne)-2) ) then inc(tableau[rangPremiereLettre,rangDeuxiemeLettre, rangTroisiemeLettre, 3]);
				end;
//		barreProgression(temporisateur, nombreLignes, nomFichier);
	end;
 fermerDictionnaire(nomFichier,fichier);
 occurrencesTrigrammesDictionnaire:=tableau;
end;

end.

