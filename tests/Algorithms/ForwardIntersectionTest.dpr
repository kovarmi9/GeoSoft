program ForwardIntersectionTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmForwardIntersection;

var
  Frame: TGeoDataFrame;
  Alg: TForwardIntersectionAlgorithm;

// One notebook row: number, direction (from A), direction from B and the
// coordinates of a listed point
procedure Add(const APointNumber: string; ADirection: Double = NaN;
  ADirectionB: Double = NaN; AY: Double = NaN; AX: Double = NaN);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.Uloha := ULOHA_PROTINANI_SMERY;
  Row.CB := ShortString(APointNumber);
  Row.HZ := ADirection;
  Row.Zuhel := ADirectionB;
  Row.Y := AY;
  Row.X := AX;
  Row.KK := 3;
  Frame.AddRow(Row);
end;

// Prints both stations, the messages and every new point
procedure Run(const ATitle: string);
var
  I: Integer;
  Row: TGeoRow;
begin
  Alg.Calculate(Frame);
  Writeln(ATitle);
  for I := 0 to 1 do
    Writeln(Format('  stanovisko %d: řádek %d, orientací %d, posun %.4f',
      [I + 1, Alg.Stations[I].Row + 1, Alg.Stations[I].OrientCount,
      Alg.Stations[I].Shift]));
  for I := 0 to Alg.Warnings.Count - 1 do
    Writeln('  ', Alg.Warnings[I]);
  for I := 0 to Frame.Count - 1 do
    if Alg.Roles[I] = irPoint then
    begin
      Row := Frame.Rows[I];
      Writeln(Format('  %s: Y %.3f  X %.3f  úhel %.1f  KK %d',
        [string(Row.CB), Row.Y, Row.X, Alg.Angles[I], Row.KK]));
    end;
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([Uloha, CB, HZ, Zuhel, Y, X, KK]);
  Alg := TForwardIntersectionAlgorithm.Create;
  try
    // 1. From angles: on 11 zero to 12, on 12 zero to 11.
    // Expected 111: Y 115,000 X 170,000, 112: Y 130,000 X 160,000
    Add('11', NaN, NaN, 100, 200);
    Add('12', 0, NaN, 140, 200);
    Add('');
    Add('12', NaN, NaN, 140, 200);
    Add('11', 0, NaN, 100, 200);
    Add('');
    Add('111', 70.4833, 344.2284);
    Add('112', 59.0334, 315.5958);
    Run('1. Protínání z úhlů');

    // 2. Two orientations on each station, any zero of the circle.
    // The same points are expected
    Frame.ClearData;
    Add('11', NaN, NaN, 100, 200);
    Add('12', 50.0000, NaN, 140, 200);
    Add('13', 370.4833, NaN, 120, 260);
    Add('');
    Add('12', NaN, NaN, 140, 200);
    Add('11', 366.6667, NaN, 100, 200);
    Add('13', 46.1834, NaN, 120, 260);
    Add('');
    Add('111', 120.4833, 310.8951);
    Add('112', 109.0334, 282.2625);
    Run('2. Dvě orientace na stanovisku');

    // 3. Orientation 13 off by 0,2 gon, a missing direction from B
    Frame.ClearData;
    Add('11', NaN, NaN, 100, 200);
    Add('12', 50.0000, NaN, 140, 200);
    Add('13', 370.6833, NaN, 120, 260);
    Add('');
    Add('12', NaN, NaN, 140, 200);
    Add('11', 366.6667, NaN, 100, 200);
    Add('');
    Add('111', 120.4833);
    Run('3. Odchylka orientace, chybí směr z B (očekáváno)');

    // 4. Station B left out (expected error)
    Frame.ClearData;
    Add('11', NaN, NaN, 100, 200);
    Add('12', 0, NaN, 140, 200);
    Run('4. Chybí stanovisko B (očekávána chyba)');
  finally
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
