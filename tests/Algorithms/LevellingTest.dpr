program LevellingTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmLevelling;

var
  Frame: TGeoDataFrame;
  Alg: TLevellingAlgorithm;

// One reading: B back, F fore, S side. Given height only at the known ends.
procedure Add(const APointNumber: string; AKind: Char;
  AReading, ALength: Double; AHeight: Double = NaN);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.Uloha := ULOHA_NIVELACE;
  Row.CB := ShortString(APointNumber);
  case AKind of
    'B': Row.Xm := AReading;
    'F': Row.Ym := AReading;
    'S': Row.Zm := AReading;
  end;
  Row.SH := ALength;
  Row.Z := AHeight;
  Frame.AddRow(Row);
end;

// Prints the summary, the messages and every row
procedure Run(const ATitle: string);
var
  I: Integer;
  Row: TGeoRow;
begin
  Alg.Calculate(Frame);
  Writeln(ATitle);
  if Alg.Info.Valid then
    Writeln(Format('  sestav %d, délka %.0f m, suma %.4f, má být %.4f, ' +
      'odchylka %.4f, mez %.4f', [Alg.Info.SetupCount,
      Alg.Info.TotalLength, Alg.Info.SumHeight, Alg.Info.Given,
      Alg.Info.Misclosure, Alg.Info.Limit]));
  for I := 0 to Alg.Warnings.Count - 1 do
    Writeln('  ', Alg.Warnings[I]);
  for I := 0 to Frame.Count - 1 do
  begin
    Row := Frame.Rows[I];
    Writeln(Format('  %-5s převýšení %8.4f  oprava %8.4f  výška %9.4f',
      [string(Row.CB), Row.Vz, Row.Vy, Row.VC]));
  end;
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([Uloha, CB, Z, Xm, Ym, Zm, SH, Vz, Vy, VC]);
  Alg := TLevellingAlgorithm.Create;
  try
    // 1. Line 101 - 102, side reading 5001, misclosure +3 mm.
    // Expected: 250,535  5001 251,180  251,277  102 251,254
    Add('101', 'B', 1.523, 30, 250.000);
    Add('', 'F', 0.987, 30);
    Add('', 'B', 1.845, 30);
    Add('5001', 'S', 1.200, 15);
    Add('', 'F', 1.102, 30);
    Add('', 'B', 1.410, 30);
    Add('102', 'F', 1.432, 30, 251.254);
    Run('1. Připojený pořad 101 - 102');

    // 2. Closed loop on 101, misclosure -4 mm.
    // Expected: 250,502 and 101 again 250,000
    Frame.ClearData;
    Add('101', 'B', 1.000, 40, 250.000);
    Add('', 'F', 0.500, 40);
    Add('', 'B', 0.800, 40);
    Add('101', 'F', 1.304, 40, 250.000);
    Run('2. Uzavřený pořad 101 - 101');

    // 3. End 102 shifted by 2 cm, over the limit of 8 mm
    Frame.ClearData;
    Add('101', 'B', 1.523, 30, 250.000);
    Add('', 'F', 0.987, 30);
    Add('', 'B', 1.845, 30);
    Add('', 'F', 1.102, 30);
    Add('', 'B', 1.410, 30);
    Add('102', 'F', 1.432, 30, 251.274);
    Run('3. Odchylka přes mez (očekáváno upozornění)');

    // 4. Two readings on a row, a missing length
    Frame.ClearData;
    Add('101', 'B', 1.523, 30, 250.000);
    Add('', 'F', 0.987, NaN);
    Frame.Rows[1].Xm := 1.0;
    Add('102', 'F', 1.432, 30);
    Run('4. Chyby v zápisníku (očekávány chyby)');

    // 5. End 102 without a given height, no correction.
    // Expected: 250,536  251,279  102 251,257
    Frame.ClearData;
    Add('101', 'B', 1.523, 30, 250.000);
    Add('', 'F', 0.987, 30);
    Add('', 'B', 1.845, 30);
    Add('', 'F', 1.102, 30);
    Add('', 'B', 1.410, 30);
    Add('102', 'F', 1.432, 30);
    Run('5. Konec bez dané výšky (očekáváno upozornění)');
  finally
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
