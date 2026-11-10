program LevellingProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmLevelling,
  ProtocolLevelling;

var
  Frame: TGeoDataFrame;
  Alg: TLevellingAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One reading: B back, F fore, S side, a given height at the known ends
procedure Add(const APointNumber: string; AKind: Char;
  AReading, ALength: Double; AHeight: Double = NaN);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := StrToInt64Def(APointNumber, 0);
  case AKind of
    'B': Row.Xm := AReading;
    'F': Row.Ym := AReading;
    'S': Row.Zm := AReading;
  end;
  Row.SH := ALength;
  Row.Z := AHeight;
  Frame.AddRow(Row);
end;

// Computes the frame and prints its protocol, the row AStored is marked
procedure Run(const ATitle: string; AStored: Integer = -1);
var
  I: Integer;
  Rows: TProtocolRows;
begin
  Alg.Calculate(Frame);

  SetLength(Rows.Numbers, Frame.Count);
  SetLength(Rows.Notes, Frame.Count);
  for I := 0 to Frame.Count - 1 do
  begin
    Rows.Numbers[I] := IntToStr(I + 1);
    Rows.Notes[I] := '';
  end;
  if AStored >= 0 then
    Rows.Notes[AStored] := OverwrittenText;

  TLevellingProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, Z, Xm, Ym, Zm, SH, M3, M1, VC]);
  Alg := TLevellingAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Line 101 - 102 with the side reading 5001, stored again
    Add('101', 'B', 1.523, 30, 250.000);
    Add('', 'F', 0.987, 30);
    Add('', 'B', 1.845, 30);
    Add('5001', 'S', 1.200, 15);
    Add('', 'F', 1.102, 30);
    Add('', 'B', 1.410, 30);
    Add('102', 'F', 1.432, 30, 251.254);
    Run('1. Připojený pořad 101 - 102', 3);

    // 2. Closed loop on 101
    Frame.ClearData;
    Add('101', 'B', 1.000, 40, 250.000);
    Add('', 'F', 0.500, 40);
    Add('', 'B', 0.800, 40);
    Add('101', 'F', 1.304, 40, 250.000);
    Run('2. Uzavřený pořad 101 - 101');

    // 3. End 102 without a given height
    Frame.ClearData;
    Add('101', 'B', 1.523, 30, 250.000);
    Add('', 'F', 0.987, 30);
    Add('', 'B', 1.845, 30);
    Add('', 'F', 1.102, 30);
    Add('', 'B', 1.410, 30);
    Add('102', 'F', 1.432, 30);
    Run('3. Konec bez dané výšky');

    // 4. Two readings on a row, a missing length
    Frame.ClearData;
    Add('101', 'B', 1.523, 30, 250.000);
    Add('', 'F', 0.987, NaN);
    Frame.Rows[1].Xm := 1.0;
    Add('102', 'F', 1.432, 30);
    Run('4. Chyby v zápisníku');

    // 5. There 101 - 102 and back
    Frame.ClearData;
    Alg.BothWays := True;
    Add('101', 'B', 1.523, 30, 250.000);
    Add('', 'F', 0.987, 30);
    Add('', 'B', 1.845, 30);
    Add('', 'F', 1.102, 30);
    Add('', 'B', 1.410, 30);
    Add('102', 'F', 1.432, 30);
    Add('102', 'B', 1.200, 30);
    Add('', 'F', 1.500, 30);
    Add('', 'B', 0.900, 30);
    Add('101', 'F', 1.855, 30, 250.000);
    Run('5. Tam a zpět 101 - 102 - 101');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
