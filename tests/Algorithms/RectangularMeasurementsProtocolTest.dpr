program RectangularMeasurementsProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmRectangularMeasurements,
  ProtocolRectangularMeasurements;

var
  Frame: TGeoDataFrame;
  Alg: TRectangularMeasurementsAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One point of the chain, Y and X only for a given one
procedure Add(APointNumber: Int64; ALength: Double;
  AY: Double = NaN; AX: Double = NaN);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := APointNumber;
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

  // Č. is the grid row, the corner 1 was stored again
  SetLength(Rows.Numbers, Frame.Count);
  SetLength(Rows.Notes, Frame.Count);
  for I := 0 to Frame.Count - 1 do
  begin
    Rows.Numbers[I] := IntToStr(I + 1);
    Rows.Notes[I] := '';
  end;
  Rows.Notes[1] := OverwrittenText;

  TRectangularMeasurementsProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, X, Y, SH, KK]);
  Alg := TRectangularMeasurementsAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Right angle, the corner 1 in X 0,00, Y 100,00
    Add(101, NaN, 0, 0);
    Add(1, 100);
    Add(102, -100.01, 100, 100);
    Run('1. Pravý úhel');

    // 2. The given end 0,6 m off, over ud
    Frame.ClearData;
    Add(101, NaN, 0, 0);
    Add(1, 100);
    Add(102, -100.01, 100, 100.6);
    Run('2. Daný bod posunutý o 0,6 m');

    // 3. No length to the corner, the stretch stops
    Frame.ClearData;
    Add(101, NaN, 0, 0);
    Add(1, NaN);
    Add(102, -100.01, 100, 100);
    Run('3. Bod bez délky');

    // 4. A point after the last given one is not computed
    Frame.ClearData;
    Add(101, NaN, 0, 0);
    Add(1, 100);
    Add(102, -100.01, 100, 100);
    Add(2, 50);
    Run('4. Bod za posledním daným bodem');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
