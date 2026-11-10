program ParcelAreaProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  GeoAlgorithmLHuilier,
  ProtocolParcelArea;

var
  Frame: TGeoDataFrame;
  Alg: TLHuilierAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// One corner of the parcel
procedure Add(APointNumber: Int64; AY, AX: Double);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.CB := APointNumber;
  Row.Y := AY;
  Row.X := AX;
  Frame.AddRow(Row);
end;

// Computes the frame and prints its protocol line by line
procedure Run(const ATitle, AParcel: string);
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

  TParcelAreaProtocol.Write(Prot, Lines, Frame, Alg, Rows, AParcel);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

begin
  Frame := TGeoDataFrame.Create([CB, X, Y]);
  Alg := TLHuilierAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Square 10 x 10 m, 100 m² expected
    Add(1, 0, 0);
    Add(2, 10, 0);
    Add(3, 10, 10);
    Add(4, 0, 10);
    Run('1. Čtverec, parcela 123/4', '123/4');

    // 2. Two points only, the protocol says why
    Frame.ClearData;
    Add(1, 0, 0);
    Add(2, 10, 0);
    Run('2. Jen dva body', '');

    // 3. Three points on a line, the area is zero
    Frame.ClearData;
    Add(1, 0, 0);
    Add(2, 5, 0);
    Add(3, 10, 0);
    Run('3. Body na přímce', '');
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
