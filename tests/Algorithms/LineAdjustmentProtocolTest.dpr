program LineAdjustmentProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmLineAdjustment,
  ProtocolLineAdjustment;

var
  Frame: TGeoDataFrame;
  Alg: TLineAdjustmentAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One point, Xm and Ym keep it before the move
procedure Add(const APointNumber: string; AY, AX: Double;
  AQuality: Integer = 3; const ANewNumber: string = '');
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := StrToInt64Def(APointNumber, 0);
  Row.CBm := StrToInt64Def(ANewNumber, 0);
  Row.Y := AY;
  Row.X := AX;
  Row.Ym := AY;
  Row.Xm := AX;
  Row.KK := AQuality;
  Frame.AddRow(Row);
end;

// Computes the frame and prints its protocol line by line
procedure Run(const ATitle: string; AUpdated: Boolean);
var
  I: Integer;
  Rows: TProtocolRows;
begin
  Alg.Calculate(Frame);

  // Č. is A, B and the point grid row
  Rows.Numbers := ['A', 'B', '1'];
  Rows.Notes := ['', '', ''];
  if AUpdated then
    Rows.Notes[LINE_ROWS] := OverwrittenText;

  TLineAdjustmentProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, CBm, Y, X, Ym, Xm, Kol, KK]);
  Alg := TLineAdjustmentAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Groma manual: line 1 - 6, point 3, stored again
    Add('1', 740995.70, 1040999.73);
    Add('6', 741023.74, 1041001.20);
    Add('3', 741009.90, 1041000.55);
    Run('1. Příklad z Gromy', True);

    // 2. The point 0,5 m away with a new number, over Uxy
    Frame.ClearData;
    Add('101', 0, 0);
    Add('102', 10, 0);
    Add('5', 5, 0.50, 3, '105');
    Run('2. Kolmice přes Uxy, nové číslo', False);

    // 3. A point without coordinates
    Frame.ClearData;
    Add('101', 0, 0);
    Add('102', 10, 0);
    Add('6', NaN, NaN);
    Run('3. Bod bez souřadnic', False);
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
