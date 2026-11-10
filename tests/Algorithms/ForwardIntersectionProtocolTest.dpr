program ForwardIntersectionProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmForwardIntersection,
  ProtocolForwardIntersection;

var
  Frame: TGeoDataFrame;
  Alg: TForwardIntersectionAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One notebook row: number, direction from A, from B, listed Y and X
procedure Add(const APointNumber: string; ADirection: Double = NaN;
  ADirectionB: Double = NaN; AY: Double = NaN; AX: Double = NaN);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := StrToInt64Def(APointNumber, 0);
  Row.HZ := ADirection;
  Row.ZU := ADirectionB;
  Row.Y := AY;
  Row.X := AX;
  Row.KK := 3;
  Frame.AddRow(Row);
end;

// Computes the frame and prints its protocol line by line
procedure Run(const ATitle: string);
var
  I: Integer;
  Rows: TProtocolRows;
begin
  Alg.Calculate(Frame);

  // Č. is the grid row, the last point with a result stored again
  SetLength(Rows.Numbers, Frame.Count);
  SetLength(Rows.Notes, Frame.Count);
  for I := 0 to Frame.Count - 1 do
  begin
    Rows.Numbers[I] := IntToStr(I + 1);
    Rows.Notes[I] := '';
  end;
  if not IsNan(Frame.Rows[Frame.Count - 1].X) then
    Rows.Notes[Frame.Count - 1] := OverwrittenText;

  TForwardIntersectionProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, HZ, ZU, Y, X, KK]);
  Alg := TForwardIntersectionAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Two orientations on each station, points 111 and 112
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
    Run('1. Dvě orientace na stanovisku');

    // 2. Orientation 13 off by 0,2 gon, a missing direction from B
    Frame.ClearData;
    Add('11', NaN, NaN, 100, 200);
    Add('12', 50.0000, NaN, 140, 200);
    Add('13', 370.6833, NaN, 120, 260);
    Add('');
    Add('12', NaN, NaN, 140, 200);
    Add('11', 366.6667, NaN, 100, 200);
    Add('');
    Add('111', 120.4833);
    Run('2. Odchylka orientace, chybí směr z B');

    // 3. Station B left out
    Frame.ClearData;
    Add('11', NaN, NaN, 100, 200);
    Add('12', 0, NaN, 140, 200);
    Run('3. Chybí stanovisko B');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
