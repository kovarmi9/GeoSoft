program DistanceIntersectionProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmDistanceIntersection,
  ProtocolDistanceIntersection;

var
  Frame: TGeoDataFrame;
  Alg: TDistanceIntersectionAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One point with its length, Y and X as in the list
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

// Computes the frame and prints its protocol line by line
procedure Run(const ATitle: string);
var
  I: Integer;
  Rows: TProtocolRows;
begin
  Alg.Calculate(Frame);

  // Č. is the grid row, the new point was stored again
  Rows.Numbers := ['1', '2', '3'];
  Rows.Notes := ['', '', OverwrittenText];

  TDistanceIntersectionProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, SH, Y, X, KK]);
  Alg := TDistanceIntersectionAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Point 226, no check length, right of 229-202
    Add('229', 846.61, 852501.72, 1011270.35);
    Add('202', 703.84, 853704.65, 1011445.66);
    Add('226', 0);
    Run('1. Bod 226 bez kontrolní délky');

    // 2. The same with a check length 1-2
    Frame.ClearData;
    Add('229', 846.61, 852501.72, 1011270.35);
    Add('202', 703.84, 853704.65, 1011445.66);
    Add('226', 1215.65);
    Run('2. Bod 226 s kontrolní délkou');

    // 3. A given point without coordinates
    Frame.ClearData;
    Add('229', 846.61, 852501.72, 1011270.35);
    Add('202', 703.84);
    Add('226', 0);
    Run('3. Daný bod bez souřadnic');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
