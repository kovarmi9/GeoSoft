program LineIntersectionProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmLineIntersection,
  ProtocolLineIntersection;

var
  Frame: TGeoDataFrame;
  Alg: TLineIntersectionAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One point, Y and X as in the list
procedure Add(const APointNumber: string; AY, AX: Double; AQuality: Integer = 3);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := StrToInt64Def(APointNumber, 0);
  Row.Y := AY;
  Row.X := AX;
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

  // Č. as the grid shows it, I-1 to II-2 and P
  Rows.Numbers := ['I-1', 'I-2', 'II-1', 'II-2', 'P'];
  Rows.Notes := ['', '', '', '', ''];
  if AUpdated then
    Rows.Notes[LINE_POINTS] := OverwrittenText;

  TLineIntersectionProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, Y, X, Z, KK]);
  Alg := TLineIntersectionAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Groma manual: lines 24 - 30 and 21 - 29, point stored again
    Add('24', 741000.95, 1041007.42);
    Add('30', 741004.48, 1041016.46);
    Add('21', 741015.16, 1041004.12);
    Add('29', 741001.12, 1041014.48, 4);
    Add('50', NaN, NaN);
    Run('1. Příklad z Gromy, bod přepsán v seznamu', True);

    // 2. Parallel lines, the protocol says why
    Frame.ClearData;
    Add('1', 0, 0);
    Add('2', 0, 10);
    Add('3', 5, 0);
    Add('4', 5, 10);
    Add('50', NaN, NaN);
    Run('2. Rovnoběžné přímky', False);
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
