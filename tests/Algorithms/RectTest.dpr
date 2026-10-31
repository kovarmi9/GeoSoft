program RectTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmRectangularMeasurements;

var
  P101, P1, P102: TGeoRow;
  Frame: TGeoDataFrame;
  Alg: TRectangularMeasurementsAlgorithm;

// Runs the chain 101, 1, 102 and prints stretches, warnings and rows
procedure RunChain(const ATitle: string);
var
  I: Integer;
  Seg: TSegmentInfo;
begin
  Frame.ClearData;
  Frame.AddRow(P101);
  Frame.AddRow(P1);
  Frame.AddRow(P102);
  Alg.Calculate(Frame);

  Writeln(ATitle);
  for I := 0 to High(Alg.Segments) do
  begin
    Seg := Alg.Segments[I];
    Writeln(Format('  Úsek %d: měřená %.3f m, vypočtená %.3f m, ' +
      'uzávěr %.3f m, mezní rozdíl %.3f m',
      [I + 1, Seg.MeasDist, Seg.CalcDist, Seg.Closure, Seg.Limit]));
  end;
  for I := 0 to Alg.Warnings.Count - 1 do
    Writeln('  ', Alg.Warnings[I]);
  Writeln(Frame.Print);
end;

begin
  // 101 - given start of the chain
  ClearGeoRow(P101);
  P101.Uloha := ULOHA_KONSTRUKCNI;
  P101.CB := '101';
  P101.X := 0;
  P101.Y := 0;
  P101.KK := 3;

  // 1 - computed corner, 100 m from 101
  ClearGeoRow(P1);
  P1.Uloha := ULOHA_KONSTRUKCNI;
  P1.CB := '1';
  P1.SH := 100;           // side length, + turns right, - left

  // 102 - given end, 100,01 m from the corner, turning left
  ClearGeoRow(P102);
  P102.Uloha := ULOHA_KONSTRUKCNI;
  P102.CB := '102';
  P102.X := 100;
  P102.Y := 100;
  P102.KK := 3;
  P102.SH := -100.01;

  Frame := TGeoDataFrame.Create([Uloha, CB, X, Y, SH]);
  Alg := TRectangularMeasurementsAlgorithm.Create;
  try
    try
      // 1. Right angle, expected corner 1 in X 0,00, Y 100,00
      RunChain('Pravý úhel (očekáváno bod 1: X 0,00, Y 100,00):');

      // 2. The given end is 0,1 m off, still within ud
      P102.X := 100.1;
      RunChain('Daný bod 102 posunutý o 0,1 m (očekáváno bez varování):');

      // 3. The given end is 0,6 m off, over ud
      P102.X := 100.6;
      RunChain('Daný bod 102 posunutý o 0,6 m (očekáváno varování):');

      // 4. No length to the corner, the stretch stops
      P102.X := 100;
      P1.SH := NaN;
      RunChain('Bod 1 bez délky (očekáváno úsek se nepočítá):');
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    Alg.Free;
    Frame.Free;
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.
