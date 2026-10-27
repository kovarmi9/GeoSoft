
program DistanceIntersectionTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmDistanceIntersection;

var
  Frame: TGeoDataFrame;
  Alg: TDistanceIntersectionAlgorithm;

// Pridani bodu
procedure Add(const APointNumber: string; ALength: Double;
  AY: Double = NaN; AX: Double = NaN);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.Uloha := ULOHA_PROTINANI_DELKY;
  Row.CB := ShortString(APointNumber);
  Row.SH := ALength;
  Row.Y := AY;
  Row.X := AX;
  Row.KK := 3;
  Frame.AddRow(Row);
end;

// Vypocet a vypis vysledku
procedure Run(const ATitle: string);
var
  I: Integer;
  Row: TGeoRow;
begin
  Alg.Calculate(Frame);

  Writeln(ATitle);

  if Alg.Valid then
  begin
    Writeln('  Delka zakladny: ', Alg.Base:0:3);
    Writeln('  Uhel protnuti: ', Alg.Omega:0:1, ' gon');
    Writeln('  Vlevo: ', BoolToStr(Alg.Left, True));
    Writeln('  Kontrolni delka: ', Alg.Measured:0:3);
    Writeln('  Mez: ', Alg.Limit:0:3);
  end;

  for I := 0 to Alg.Warnings.Count - 1 do
  begin
    Writeln('  ', Alg.Warnings[I]);
  end;

  Row := Frame.Rows[GIVEN_POINTS];

  Writeln('  ', string(Row.CB), ': Y ', Row.Y:0:3,
    '  X ', Row.X:0:3, '  KK ', Row.KK);

  Writeln;
end;


begin
  Frame := TGeoDataFrame.Create([Uloha, CB, SH, Y, X, KK]);
  Alg := TDistanceIntersectionAlgorithm.Create;

  try
    // Priklad protinani z delek
    // Ocekavany vysledek: Y = 853262.19, X = 1010898.28

    Add('202', 703.84, 853704.65, 1011445.66);
    Add('229', 846.61, 852501.72, 1011270.35);
    Add('226', -1);

    Run('Protinani z delek - bod 226');

  finally
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
end.

