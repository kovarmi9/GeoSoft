program OrthogonalProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmOrthogonal,
  ProtocolOrthogonal;

var
  Frame: TGeoDataFrame;
  Alg: TOrthogonalMethodAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One row, Y and X only for P and K
procedure Add(APointNumber: Int64; AStationing, AOffset: Double;
  AY: Double = NaN; AX: Double = NaN);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := APointNumber;
  Row.Sta := AStationing;
  Row.Kol := AOffset;
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

  // Č. is P, K and the detail grid row, the last point stored again
  SetLength(Rows.Numbers, Frame.Count);
  SetLength(Rows.Notes, Frame.Count);
  for I := 0 to Frame.Count - 1 do
  begin
    Rows.Numbers[I] := IntToStr(I - 1);
    Rows.Notes[I] := '';
  end;
  Rows.Numbers[0] := 'P';
  Rows.Numbers[1] := 'K';
  Rows.Notes[Frame.Count - 1] := OverwrittenText;

  TOrthogonalProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, X, Y, Sta, Kol, KK]);
  Alg := TOrthogonalMethodAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Line P 5210 to K 5200, 8,485 m, two detail points
    Add(5210, 0, 0, 0, 0);
    Add(5200, 8.485281374, 0, 6, 6);
    Add(1, 4.242640687, 0);
    Add(2, 4.242640687, 4.242640687);
    Run('1. Přímka a dva podrobné body');

    // 2. K without coordinates, the protocol says why
    Frame.ClearData;
    Add(5210, 0, 0, 0, 0);
    Add(5200, 8.485281374, 0);
    Add(1, 4.242640687, 0);
    Run('2. Koncový bod bez souřadnic');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
