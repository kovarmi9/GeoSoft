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
procedure Add(const APointNumber: string; AY, AX: Double; AQuality: Integer = 3);
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
  Frame := TGeoDataFrame.Create([Uloha, CB, Y, X, KK]);
  Alg := TLineIntersectionAlgorithm.Create;
  try
    // 1. Groma manual: lines 24 - 30 and 21 - 29.
    // Expected Y 741 003,13  X 1 041 013,00 on both segments
    Add('24', 741000.95, 1041007.42);
    Add('30', 741004.48, 1041016.46);
    Add('21', 741015.16, 1041004.12);
    Add('29', 741001.12, 1041014.48, 4);
    Add('50', NaN, NaN);
    Run('1. Příklad z Gromy');

    // 2. Crossing beyond the end of line II, 100 gon.
    // Expected Y 5,000  X 0,000, KK 3
    Frame.ClearData;
    Add('1', 0, 0);
    Add('2', 10, 0);
    Add('3', 5, 5);
    Add('4', 5, 2);
    Add('5', NaN, NaN);
    Run('2. Na úsečce I, mimo úsečku II');

    // 3. A sharp angle of about 6 gon (expected warning)
    Frame.ClearData;
    Add('1', 0, 0);
    Add('2', 100, 0);
    Add('3', 0, 5);
    Add('4', 100, -5);
    Add('5', NaN, NaN);
    Run('3. Ostrý úhel (očekáváno upozornění)');

    // 4. Parallel lines (expected error)
    Frame.ClearData;
    Add('1', 0, 0);
    Add('2', 10, 0);
    Add('3', 0, 5);
    Add('4', 10, 5);
    Add('5', NaN, NaN);
    Run('4. Rovnoběžky (očekávána chyba)');
  finally
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
