program LineAdjustmentTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmLineAdjustment;

var
  Frame: TGeoDataFrame;
  Alg: TLineAdjustmentAlgorithm;

// One point, Y and X as in the list, NaN when it has none
procedure Add(const APointNumber: string; AY, AX: Double;
  AQuality: Integer = 3; const ANewNumber: string = '');
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.Uloha := ULOHA_PRIMKA;
  Row.CB := ShortString(APointNumber);
  Row.CBm := ShortString(ANewNumber);
  Row.Y := AY;
  Row.X := AX;
  Row.KK := AQuality;
  Frame.AddRow(Row);
end;

// Prints the line, the messages and every adjusted point
procedure Run(const ATitle: string);
var
  I: Integer;
  Row: TGeoRow;
begin
  Alg.Calculate(Frame);
  Writeln(ATitle);
  Writeln(Format('  přímka %.3f m, KK %d, Uxy %.3f m',
    [Alg.LineLength, Alg.Quality, Alg.Limit]));
  for I := 0 to Alg.Warnings.Count - 1 do
    Writeln('  ', Alg.Warnings[I]);
  for I := LINE_ROWS to Frame.Count - 1 do
  begin
    Row := Frame.Rows[I];
    Writeln(Format('  %-4s -> %-4s Y %.3f  X %.3f  kolmice %.3f  KK %d',
      [string(Row.CB), string(Row.CBm), Row.Y, Row.X, Row.PolarK, Row.KK]));
  end;
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([Uloha, CB, CBm, Y, X, PolarK, KK]);
  Alg := TLineAdjustmentAlgorithm.Create;
  try
    // 1. Groma manual: line 1 - 6, point 3.
    // Expected Y 741 009,90  X 1 041 000,47, distance 0,08 (left, minus)
    Add('1', 740995.70, 1040999.73);
    Add('6', 741023.74, 1041001.20);
    Add('3', 741009.90, 1041000.55);
    Run('1. Příklad z Gromy');

    // 2. Line along Y, the point 5 cm right, new number 104, B is worse.
    // Expected Y 4,000  X 0,000, offset +0,050, KK 4
    Frame.ClearData;
    Add('101', 0, 0);
    Add('102', 10, 0, 4);
    Add('4', 4, -0.05, 3, '104');
    Run('2. Bod vpravo, nové číslo');

    // 3. The point 0,5 m away, over Uxy 0,28 of code 3
    Frame.ClearData;
    Add('101', 0, 0);
    Add('102', 10, 0);
    Add('5', 5, 0.50);
    Run('3. Kolmice přes Uxy (očekáváno upozornění)');

    // 4. Point not in the list, then A and B on one place
    Frame.ClearData;
    Add('101', 0, 0);
    Add('102', 10, 0);
    Add('6', NaN, NaN);
    Run('4. Bod bez souřadnic (očekávána chyba)');
    Frame.ClearData;
    Add('101', 0, 0);
    Add('102', 0, 0);
    Add('7', 1, 1);
    Run('5. Body přímky splývají (očekávána chyba)');
  finally
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
