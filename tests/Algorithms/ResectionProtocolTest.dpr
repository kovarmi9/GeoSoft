program ResectionProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmResection,
  ProtocolResection;

var
  Frame: TGeoDataFrame;
  Alg: TResectionAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One given point with its direction
procedure Add(const APointNumber: string; AY, AX, ADirection: Double);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := StrToInt64Def(APointNumber, 0);
  Row.Y := AY;
  Row.X := AX;
  Row.HZ := ADirection;
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

  // Č. is the grid row, the station was stored again
  Rows.Numbers := ['1', '2', '3', '4'];
  Rows.Notes := ['', '', '', OverwrittenText];

  TResectionProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, Y, X, HZ, KK]);
  Alg := TResectionAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Example 9.1, Y 739272,33 X 1045688,67 expected
    Add('103', 739936.78, 1044454.82, 0);
    Add('22', 737998.12, 1045881.67, 141.0182);
    Add('30', 739331.21, 1046906.56, 234.5234);
    Add('104', NaN, NaN, NaN);
    Run('1. Příklad 9.1');

    // 2. A given point without coordinates, the protocol says why
    Frame.ClearData;
    Add('103', 739936.78, 1044454.82, 0);
    Add('22', NaN, NaN, 141.0182);
    Add('30', 739331.21, 1046906.56, 234.5234);
    Add('104', NaN, NaN, NaN);
    Run('2. Daný bod bez souřadnic');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
