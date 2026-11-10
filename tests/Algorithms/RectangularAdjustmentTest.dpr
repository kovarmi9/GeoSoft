program RectangularAdjustmentTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmTransformBase,
  GeoAlgorithmRectangularAdjustment;

var
  Frame: TGeoDataFrame;
  Alg: TRectangularAdjustmentAlgorithm;

// One row, Y and X only for a given point
procedure Add(const APointNumber: string; ALength: Double;
  AY: Double = NaN; AX: Double = NaN);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := StrToInt64Def(APointNumber, 0);
  Row.SH := ALength;
  Row.Y := AY;
  Row.X := AX;
  Row.KK := 3;
  Frame.AddRow(Row);
end;

// Prints the closure, the sides, the residuals and the points
procedure Run(const ATitle: string);
var
  I: Integer;
  Row: TGeoRow;
  Residual: TPointResidual;
begin
  Alg.Calculate(Frame);

  Writeln(ATitle);

  for I := 0 to Alg.Errors.Count - 1 do
    Writeln('  ', Alg.Errors[I]);
  for I := 0 to Alg.Warnings.Count - 1 do
    Writeln('  ', Alg.Warnings[I]);
  if not Alg.Valid then
  begin
    Writeln;
    Exit;
  end;

  Writeln('  Uzávěr: podélný ', Alg.ClosureAlong:0:3,
    '  příčný ', Alg.ClosureAcross:0:3);

  Writeln('  Oměrné: měřená, vyrovnaná');
  for I := 1 to Frame.Count - 1 do
    Writeln('    ', IntToStr(Frame.Rows[I].CB), ': ',
      Frame.Rows[I].SH:0:3, '  ', Alg.Adjusted[I]:0:4);

  Writeln('  Opravy daných bodů: vy, vx');
  for Residual in Alg.Residuals do
    Writeln('    ', Residual.PointNumber, ': ',
      Residual.Vy:0:4, '  ', Residual.Vx:0:4);
  Writeln('  Střední chyba: ', Alg.MeanError:0:4);

  Writeln('  Body: Y, X');
  for I := 0 to Frame.Count - 2 do
  begin
    Row := Frame.Rows[I];
    Writeln('    ', IntToStr(Row.CB), ': Y ', Row.Y:0:3, '  X ', Row.X:0:3);
  end;

  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, SH, Y, X, Xm, Ym, KK]);
  Alg := TRectangularAdjustmentAlgorithm.Create;
  try
    // L shape, closure -0,03 along 20 / 10 / 10,03, +0,02 along 5 / 5 / 9,98.
    // Expected 903 Y 1004,995 X 1020,008, 904 Y 1004,995 X 1010,015,
    // 905 Y 1009,990 X 1010,015, 906 Y 1009,990 X 999,993
    Add('901', NaN, 1000.00, 1000.00);
    Add('902', 20.00, 1000.00, 1020.00);
    Add('903', 5.00);
    Add('904', 10.00);
    Add('905', -5.00);
    Add('906', 10.03);
    Add('901', 9.98, 1000.00, 1000.00);
    Run('Tvar L (očekáváno viz komentář)');
  finally
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
