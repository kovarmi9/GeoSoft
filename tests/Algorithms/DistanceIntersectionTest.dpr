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

// One notebook row: number, length, and Y, X of a given point
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

// Points 11 and 12 of the GEUS example, the new point with ACheck
procedure Run(const ATitle, ANumber: string; ACheck: Double;
  AFirst: Double = 33.54; ASecond: Double = 39.05);
var
  I: Integer;
  Row: TGeoRow;
begin
  Frame.ClearData;
  Add('11', AFirst, 100.00, 200.00);
  Add('12', ASecond, 140.00, 200.00);
  Add(ANumber, ACheck);
  Alg.Calculate(Frame);

  Writeln(ATitle);
  if Alg.Valid then
    Writeln(Format('  1-2 %.3f, úhel %.1f gon, vlevo %s, kontrolní %.3f, ' +
      'mez %.3f', [Alg.Base, Alg.Angle, BoolToStr(Alg.Left, True),
      Alg.Measured, Alg.Limit]));
  for I := 0 to Alg.Warnings.Count - 1 do
    Writeln('  ', Alg.Warnings[I]);
  Row := Frame.Rows[GIVEN_POINTS];
  Writeln(Format('  %s: Y %.3f  X %.3f  KK %d',
    [string(Row.CB), Row.Y, Row.X, Row.KK]));
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([Uloha, CB, SH, Y, X, KK]);
  Alg := TDistanceIntersectionAlgorithm.Create;
  try
    // Expected right Y 115,000 X 170,001, left Y 115,000 X 229,999
    Run('1. Kontrolní délka 40,00, vpravo (jako GEUS)', '111', 40.00);
    Run('2. Kontrolní délka -40,00, vlevo', '112', -40.00);
    Run('3. Kontrolní délka -1, vlevo bez kontroly', '113', -1);
    Run('4. Kontrolní délka 40,50, přes mez', '114', 40.50);
    Run('5. Kontrolní délka 0, vpravo bez kontroly', '115', 0);
    Run('6. Délky 10 a 10 se neprotnou (očekávána chyba)', '116', 40.00,
      10.00, 10.00);
  finally
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
