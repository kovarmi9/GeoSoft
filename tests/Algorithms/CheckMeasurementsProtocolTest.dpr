program CheckMeasurementsProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  Point,
  PointDictionary,
  ProtocolTable,
  GeoAlgorithmCheckMeasurements,
  ProtocolCheckMeasurements;

var
  Frame: TGeoDataFrame;
  Alg: TCheckMeasurementsAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// A point of the list, the table of used points reads it
procedure AddPoint(APointNumber: Int64; AY, AX: Double);
begin
  TPointDictionary.GetInstance.AddOrUpdatePoint(
    Point.TPoint.Create(APointNumber, AX, AY, 0, 3, ''));
end;

// One measurement, the coordinates as the form takes them from the list
procedure Add(AFrom, ATo: Int64; ALength: Double; const ANote: string = '');
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := AFrom;
  Row.CBm := ATo;
  Row.SH := ALength;
  Row.KK := 3;
  Row.Popis := ShortString(ANote);
  if TPointDictionary.GetInstance.PointExists(AFrom) then
  begin
    Row.X := TPointDictionary.GetInstance.GetPoint(AFrom).X;
    Row.Y := TPointDictionary.GetInstance.GetPoint(AFrom).Y;
  end;
  if TPointDictionary.GetInstance.PointExists(ATo) then
  begin
    Row.Xm := TPointDictionary.GetInstance.GetPoint(ATo).X;
    Row.Ym := TPointDictionary.GetInstance.GetPoint(ATo).Y;
  end;
  Frame.AddRow(Row);
end;

// Computes the frame and prints its protocol line by line
procedure Run(const ATitle: string);
var
  I: Integer;
  Rows: TProtocolRows;
begin
  Alg.Calculate(Frame);

  // Č. is the grid row, nothing is stored
  SetLength(Rows.Numbers, Frame.Count);
  SetLength(Rows.Notes, Frame.Count);
  for I := 0 to Frame.Count - 1 do
  begin
    Rows.Numbers[I] := IntToStr(I + 1);
    Rows.Notes[I] := '';
  end;

  TCheckMeasurementsProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, X, Y, CBm, Xm, Ym, SH, M1, KK, Popis]);
  Alg := TCheckMeasurementsAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    AddPoint(1, 0, 0);
    AddPoint(2, 10, 0);
    AddPoint(3, 10, 10);

    // 1. Small difference, too much, not measured, a point not in the list
    Add(1, 2, 10.02);
    Add(2, 3, 10.30, 'plot');
    Add(1, 3, NaN);
    Add(1, 9, 5);
    Run('1. Čtyři oměrné');

    // 2. Both ends on one point, the protocol says why
    Frame.ClearData;
    Add(1, 1, 5);
    Run('2. Stejný bod na obou koncích');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
