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
          AGrid.Cells[C, ARows[I]] :=
            GeoFieldToText(AFrame.Rows[I], F, AFormat, FormatSettings);
      end;
  end;
end;

end.
