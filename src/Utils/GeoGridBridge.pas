unit GeoGridBridge;

interface

uses
  System.SysUtils, GeoRow, GeoDataFrame, GeoFieldsGrid;

// Copies grid rows into frame, and tells which grid row each frame row came from
procedure GridToFrame(AGrid: TGeoFieldsGrid; AFrame: TGeoDataFrame;
  AUloha: Integer; out ARows: TArray<Integer>);

// Writes the listed fields back into the grid.
// A row with ARows[i] < 0 is skipped.
procedure FrameToGrid(AGrid: TGeoFieldsGrid; AFrame: TGeoDataFrame;
  const ARows: TArray<Integer>; const AFields: TGeoFields;
  const AFormat: string = '0.00');

implementation

// One field of a row as the grid shows it
function FieldText(const ARow: TGeoRow; F: TGeoField;
  const AFormat: string): string;
begin
  case F of
    Uloha:    Result := IntToStr(ARow.Uloha);
    CB:       Result := string(ARow.CB);
    X:        Result := FloatCell(ARow.X, AFormat);
    Y:        Result := FloatCell(ARow.Y, AFormat);
    Z:        Result := FloatCell(ARow.Z, AFormat);
    CBm:      Result := string(ARow.CBm);
    Xm:       Result := FloatCell(ARow.Xm, AFormat);
    Ym:       Result := FloatCell(ARow.Ym, AFormat);
    Zm:       Result := FloatCell(ARow.Zm, AFormat);
    TypS:     Result := IntToStr(ARow.TypS);
    SH:       Result := FloatCell(ARow.SH, AFormat);
    SS:       Result := FloatCell(ARow.SS, AFormat);
    VS:       Result := FloatCell(ARow.VS, AFormat);
    VC:       Result := FloatCell(ARow.VC, AFormat);
    HZ:       Result := FloatCell(ARow.HZ, AFormat);
    Zuhel:    Result := FloatCell(ARow.Zuhel, AFormat);
    PolarD:   Result := FloatCell(ARow.PolarD, AFormat);
    PolarK:   Result := FloatCell(ARow.PolarK, AFormat);
    Poznamka: Result := string(ARow.Poznamka);
    KK:       Result := IntToStr(ARow.KK);
  else
    Result := '';
  end;
end;

procedure GridToFrame(AGrid: TGeoFieldsGrid; AFrame: TGeoDataFrame;
  AUloha: Integer; out ARows: TArray<Integer>);
var
  R, N: Integer;
  Row: TGeoRow;
  PointName: string;
begin
  AFrame.ClearData;
  SetLength(ARows, 0);
  N := 0;

  for R := AGrid.FixedRows to AGrid.RowCount - 1 do
  begin
    AGrid.GetGeoRow(R, Row);

    // Skip rows without point number
    PointName := Trim(string(Row.CB));
    if (PointName = '') or (PointName = '0') then
      Continue;

    Row.Uloha := AUloha;   // grid never carries it
    AFrame.AddRow(Row);

    Inc(N);
    SetLength(ARows, N);
    ARows[N - 1] := R;
  end;
end;

procedure FrameToGrid(AGrid: TGeoFieldsGrid; AFrame: TGeoDataFrame;
  const ARows: TArray<Integer>; const AFields: TGeoFields;
  const AFormat: string);
var
  I, C: Integer;
  F: TGeoField;
begin
  for I := 0 to AFrame.Count - 1 do
  begin
    if I > High(ARows) then
      Break;
    if ARows[I] < 0 then
      Continue;                // the caller keeps this row as it is

    for F := Low(TGeoField) to High(TGeoField) do
      if F in AFields then
      begin
        C := AGrid.FieldToCol(F);
        if C >= 0 then
          AGrid.Cells[C, ARows[I]] := FieldText(AFrame.Rows[I], F, AFormat);
      end;
  end;
end;

end.
