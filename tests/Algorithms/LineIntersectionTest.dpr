program LineIntersectionTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmLineIntersection;

var
  Frame: TGeoDataFrame;
  Alg: TLineIntersectionAlgorithm;

// One point, Y and X as in the list
procedure Add(const APointNumber: string; AY, AX, AZ: Double; AQuality: Integer = 3);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.Uloha := ULOHA_PRUSECIK;
  Row.CB := ShortString(APointNumber);
  Row.Y := AY;
  Row.X := AX;
  Row.KK := AQuality;
  Frame.AddRow(Row);
end;

// Prints the angle, the place, the messages and the result
procedure Run(const ATitle: string);
var
  I: Integer;
  Row: TGeoRow;
begin
  // Vypocet pruseciku
  Alg.Calculate(Frame);

  Writeln(ATitle);

  // Vypis uhlu a polohy pruseciku
  if Alg.Valid then
  begin
    Writeln('  Uhel protnuti: ', Alg.Omega:0:1, ' gon');
    Writeln('  ', TLineIntersectionAlgorithm.PlaceText(Alg.Place));
  end;

  // Vypis upozorneni a chyb
  for I := 0 to Alg.Warnings.Count - 1 do
  begin
    Writeln('  ', Alg.Warnings[I]);
  end;

  // Vypis souradnic vysledneho bodu
  Row := Frame.Rows[LINE_POINTS];

  Writeln('  ', string(Row.CB), ': Y ', Row.Y:0:3,
    '  X ', Row.X:0:3, '  KK ', Row.KK);

  Writeln;
end;


begin
  Frame := TGeoDataFrame.Create([Uloha, CB, Y, X, Z, KK]);
  Alg := TLineIntersectionAlgorithm.Create;
  try
    // 1. Groma manual: lines 24 - 30 and 21 - 29.
    // Expected Y 741 003,13  X 1 041 013,00 on both segments
    Add('24', 741000.95, 1041007.42, 103.41);
    Add('30', 741004.48, 1041016.46, 100.26);
    Add('21', 741015.16, 1041004.12, NaN);
    Add('29', 741001.12, 1041014.48, NaN, 4);
    Add('50', NaN, NaN, NaN);
    Run('1. Příklad z Gromy');
  finally
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
