unit uniteOutils;

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses crt, sysutils;

procedure barreProgression(var total : integer; var statut : integer; var nomFichier : string);

implementation

(* 
* Affiche une barre de progression.
* *)
procedure barreProgression(var total : integer; var statut : integer; var nomFichier : string);
var i, pourcentage: integer;
	X: string;
begin
 clrscr;
 X:='';
 pourcentage:=round(statut/total*50);
 for i:=1 to pourcentage do X:=X + 'X';
 for i:=1 to 50-pourcentage do X:=X + ' ';
 writeln('Traitement du fichier ',nomFichier, '.');
 writeln();
 writeln(pourcentage*2, '% [',X ,'] 100%');
end;

end.
