program TransformationProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmTransformation,
  ProtocolTransformation;

var
  Frame: TGeoDataFrame;
  Alg: TTransformationFrameAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One row: role, target number and Y X, source number and Y X
procedure Add(ARole: Integer; const ANumber: string; AY, AX: Double;
  const ASourceNumber: string; AYm, AXm: Double);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.Typ := ARole;
  Row.CB := StrToInt64Def(ANumber, 0);
  Row.Y := AY;
  Row.X := AX;
  Row.CBm := StrToInt64Def(ASourceNumber, 0);
  Row.Ym := AYm;
  Row.Xm := AXm;
  Row.KK := 3;
  Frame.AddRow(Row);
end;

// Computes the frame and prints its protocol, the last row is marked
procedure Run(const ATitle: string);
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
  Rows.Notes[Frame.Count - 1] := OverwrittenText;

  TTransformationProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, Y, X, CBm, Ym, Xm, Typ, M1, M2, M4, KK]);
  Alg := TTransformationFrameAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Helmert key on four points, one determined point
    Add(DRUH_IDENTICKY, '735728001390779', 696916.16, 989438.31,
      '-735728001390779', 696916.09, 989437.30);
    Add(DRUH_IDENTICKY, '735728001390688', 696937.79, 989386.32,
      '-735728001390688', 696936.92, 989384.85);
    Add(DRUH_IDENTICKY, '735728001351141', 696935.41, 989403.56,
      '-735728001351141', 696935.41, 989403.56);
    Add(DRUH_IDENTICKY, '735728001351142', 696941.78, 989407.42,
      '-735728001351142', 696941.78, 989407.42);
    Add(DRUH_URCOVANY, '735728001720002', NaN, NaN,
      '-735728001720002', 696933.81, 989387.61);
    Alg.Kind := ttSimilarity;
    Run('1. Helmertova, vzorový protokol');

    // 2. Congruent key with a check point
    Frame.ClearData;
    Add(DRUH_IDENTICKY, '1', 700186.6025, 1000123.2051, '-1', 100, 200);
    Add(DRUH_IDENTICKY, '2', 700384.8076, 1000066.5064, '-2', 300, 250);
    Add(DRUH_IDENTICKY, '3', 700441.5064, 1000264.7114, '-3', 250, 450);
    Add(DRUH_IDENTICKY, '4', 700313.9230, 1000303.7307, '-4', 120, 420);
    Add(DRUH_KONTROLNI, '6', 700404.1397, 999939.9038, '-6', 380, 150);
    Add(DRUH_URCOVANY, '5', NaN, NaN, '-5', 400, 300);
    Alg.Kind := ttCongruent;
    Run('2. Shodnostní s kontrolním bodem');

    // 3. One identical point only, the protocol says why
    Frame.ClearData;
    Add(DRUH_IDENTICKY, '1', 700186.6025, 1000123.2051, '-1', 100, 200);
    Add(DRUH_URCOVANY, '5', NaN, NaN, '-5', 400, 300);
    Run('3. Jen jeden identický bod');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
