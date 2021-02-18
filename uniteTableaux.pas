unit uniteTableaux;

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses crt, uniteGestionFichiers;

const
    alphabetFrancais : WideString = 'abcdefghijklmnopqrstuvwxyzàâéèêëîïôùûüÿæœç-';

type typeTableauNombreBigrammes=array[1..44,1..44,1..3] of integer;
type typeTableauNombreTrigrammes=array[1..44,1..44,1..44,1..3] of integer;
type typeTableauProbabiliteBigrammes=array[1..44,1..44,1..3] of real;
type typeTableauProbabiliteTrigrammes=array[1..44,1..44,1..44,1..3] of real;

function initialiserTableauProbabiliteBigrammes(var tableau: typeTableauProbabiliteBigrammes): typeTableauProbabiliteBigrammes;
function initialiserTableauProbabiliteTrigrammes(var tableau: typeTableauProbabiliteTrigrammes): typeTableauProbabiliteTrigrammes;
function initialiserTableauNombreBigrammes(var tableau: typeTableauNombreBigrammes): typeTableauNombreBigrammes;
function initialiserTableauNombreTrigrammes(var tableau: typeTableauNombreTrigrammes): typeTableauNombreTrigrammes;

implementation



(* 
* Initialise une variable de type typeTableauProbabiliteBigrammes.
* *)
function initialiserTableauProbabiliteBigrammes(var tableau: typeTableauProbabiliteBigrammes): typeTableauProbabiliteBigrammes;
var i, j, k : integer;
begin
 for k:=1 to 3 do
	for i:=1 to 44 do
		for j:=1 to 44 do
			tableau[i, j, k]:=0;
 initialiserTableauProbabiliteBigrammes:=tableau;
end;

(* 
* Initialise une variable de type typeTableauNombreBigrammes.
* *)
function initialiserTableauNombreBigrammes(var tableau: typeTableauNombreBigrammes): typeTableauNombreBigrammes;
var i, j, k : integer;
begin
 for k:=1 to 3 do
	for i:=1 to 44 do
		for j:=1 to 44 do
			tableau[i, j, k]:=0;
 initialiserTableauNombreBigrammes:=tableau;
end;

(* 
* Initialise une variable de type typeTableauProbabiliteTrigrammes.
* *)
function initialiserTableauProbabiliteTrigrammes(var tableau: typeTableauProbabiliteTrigrammes): typeTableauProbabiliteTrigrammes;
var i, j, k, l : integer;
begin
 for l:=1 to 3 do
	for i:=1 to 44 do
		for j:=1 to 44 do
			for k:=1 to 44 do
			tableau[i, j, k, l]:=0;
 initialiserTableauProbabiliteTrigrammes:=tableau;
end;

(* 
* Initialise une variable de type typeTableauNombreTrigrammes.
* *)
function initialiserTableauNombreTrigrammes(var tableau: typeTableauNombreTrigrammes): typeTableauNombreTrigrammes;
var i, j, k, l : integer;
begin
 for l:=1 to 3 do
	for i:=1 to 44 do
		for j:=1 to 44 do
			for k:=1 to 44 do
			tableau[i, j, k, l]:=0;
 initialiserTableauNombreTrigrammes:=tableau;
end;

(* 
* Affiche une variable de type typeTableauNombreBigrammes.
* *)
Procedure afficherTableauNombreBigrammes(var tableau: typeTableauNombreBigrammes);
var i, j : integer;
begin
 writeln('Affichage du tableau statistique (Bigrammes):');
 writeln('Bigrammes  ','Total  ','Initial  ', 'Terminal  ');
 writeln();
 for i:=1 to 43 do
	for j:=1 to 43 do
		writeln(alphabetFrancais[i], alphabetFrancais[j], '  ',tableau[i, j, 1],'  ', tableau[i, j, 2],'  ', tableau[i, j, 3]);
end;

(* 
* Affiche une variable de type typeTableauNombreTrigrammes.
* *)
Procedure afficherTableauNombreTrigrammes(var tableau: typeTableauNombreTrigrammes);
var i, j, k : integer;
begin
 writeln('Affichage du tableau statistique (Trigrammes):');
 writeln('Trigrammes  ','Total  ','Initial  ', 'Terminal  ');
 writeln();
 for i:=1 to 43 do
	for j:=1 to 43 do
		for k:=1 to 43 do
		if tableau[i, j, k, 1]>1 then 
			writeln(alphabetFrancais[i], alphabetFrancais[j], alphabetFrancais[k], '  ',tableau[i, j, k, 1],'  ', tableau[i, j, k, 2],'  ', tableau[i, j, k, 3]); 		(* Trop de résultats, donc filtrage des résultats nuls *)
end;

end.
