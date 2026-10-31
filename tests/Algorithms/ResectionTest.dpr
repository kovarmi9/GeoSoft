program ResectionTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmResection;

var
  Frame: TGeoDataFrame;
  Alg: TResectionAlgorithm;

// One point, Y and X as in the list
procedure Add(const APointNumber: string; AY, AX, ADirection: Double);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.Uloha := ULOHA_PROTINANI_ZPET;
  Row.CB := ShortString(APointNumber);
  Row.Y := AY;
  Row.X := AX;
  Row.HZ := ADirection;
  Row.KK := 3;
  Frame.AddRow(Row);
end;

// Prints the angles, the messages and the result
procedure Run(const ATitle: string);
var
  I: Integer;
  Row: TGeoRow;
begin
  Alg.Calculate(Frame);

  Writeln(ATitle);

  if Alg.Valid then
  begin
    Writeln('  alpha ', Alg.alpha:0:4, ' gon, beta ', Alg.beta:0:4, ' gon');
    Writeln('  Délka TU: ', Alg.sTU:0:3);
  end;

  for I := 0 to Alg.Warnings.Count - 1 do
  begin
    Writeln('  ', Alg.Warnings[I]);
  end;

  Row := Frame.Rows[RESECTION_POINTS];

  Writeln('  ', string(Row.CB), ': Y ', Row.Y:0:3, '  X ', Row.X:0:3,
    '  KK ', Row.KK);

  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([Uloha, CB, Y, X, HZ, KK]);
  Alg := TResectionAlgorithm.Create;
  try
    // Textbook example 9.1, directions 0, alpha, alpha + beta.
    // Expected Y 739 272,33  X 1 045 688,67
    Add('103', 739936.78, 1044454.82, 0);
    Add('22', 737998.12, 1045881.67, 141.0182);
    Add('30', 739331.21, 1046906.56, 234.5234);
    Add('104', NaN, NaN, NaN);
    Run('Příklad 9.1 (očekáváno Y 739272,33  X 1045688,67)');
  finally
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
