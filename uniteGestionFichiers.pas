unit uniteGestionFichiers;

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses crt, sysutils;

procedure ouvrirDictionnaire(var a: string; var d: textFile);
procedure fermerDictionnaire(var a: string; var d: textFile);
function nombreLignesFichier(var s: string): integer;

implementation

(* 
* Signale une erreur de gestion de fichier.
* *)
procedure erreurFichier(a : string);
var erreur:integer;
begin
 erreur:=ioresult;
 if erreur<>0 then 
	begin
	    writeln();
		writeln('### Erreur E/S : ',erreur);
		writeln('Fichier "',a,'" inexistant !');
        halt;
	end;
end;

(* 
* Ouvre un dictionnaire.
* *)
procedure ouvrirDictionnaire(var a: string; var d: textFile);
{$I-}
begin
 assignFile(d,a);
 reset(d);
 erreurFichier(a);
end;
{$I+}

(* 
* Ferme un dictionnaire.
* *)
procedure fermerDictionnaire(var a: string; var d: textFile);
{$I-}
begin
 closeFile(d);
 erreurFichier(a);
{$I+}
end;

(*
* Renvoie le nombre de lignes d'un fichier dictionnaire.
* *)
function nombreLignesFichier(var s: string): integer;
var i: integer;
	l: string;
	f: textfile;
begin
 i:=0;
 ouvrirDictionnaire(s,f);
 while not eof(f) do
	begin
		i:=i +1;
		readln(f,l);
	end;
 fermerDictionnaire(s,f);
 nombreLignesFichier:=i;	 
end;

(*
* Renvoie le nombre de caractères présents dans un fichier dictionnaire.
* *)
function nombreCaracteresFichier(var s: string): integer;
var compteur: integer;
	l: string;
	f: textfile;
begin
 ouvrirDictionnaire(s,f);
 compteur:=0;
 while not eof(f) do
	begin
		readln(f,l);
		compteur:=compteur + length(l);
	end;
 fermerDictionnaire(s,f);
 nombreCaracteresFichier:=compteur;	 
end;

end.



