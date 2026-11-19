program RectangularAdjustmentProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmRectangularAdjustment,
  ProtocolRectangularAdjustment;

var
  Frame: TGeoDataFrame;
  Alg: TRectangularAdjustmentAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One row, Y and X only for a given point
procedure Add(const APointNumber: string; ALength: Double; AY: Double = NaN; AX: Double = NaN);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := StrToInt64Def(APointNumber, 0);
  Row.Sta := ALength;
  Row.Y := AY;
  Row.X := AX;
  Row.KK := 3;
  Frame.AddRow(Row);
end;

// Computes the frame and prints its protocol line by line
procedure Run(const ATitle: string);
var
  I: Integer;
begin
  Alg.Calculate(Frame);

  // Č. is the grid row, the corner 903 was stored again
  Frame.Rows[2].Stored := gsOverwritten;
  TRectangularAdjustmentProtocol.Write(Prot, Lines, Frame, Alg);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, Sta, Y, X, Xm, Ym, KK]);
  Alg := TRectangularAdjustmentAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. L shape, closure -0,03 along and +0,02 across
    Add('901', NaN, 1000.00, 1000.00);
    Add('902', 20.00, 1000.00, 1020.00);
    Add('903', 5.00);
    Add('904', 10.00);
    Add('905', -5.00);
    Add('906', 10.03);
    Add('901', 9.98, 1000.00, 1000.00);
    Run('1. Tvar L');

    // 2. The shape is not closed, the protocol says why
    Frame.ClearData;
    Add('901', NaN, 1000.00, 1000.00);
    Add('902', 20.00, 1000.00, 1020.00);
    Add('903', 5.00);
    Add('904', 10.00);
    Add('905', -5.00);
    Run('2. Neuzavřený obrazec');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
