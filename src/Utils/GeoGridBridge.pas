unit GeoGridBridge;

interface

uses
  System.SysUtils, GeoRow, GeoDataFrame, GeoFieldsGrid;

// Copies grid rows into frame
procedure GridToFrame(AGrid: TGeoFieldsGrid; AFrame: TGeoDataFrame;
  AUloha: Integer);

implementation

procedure GridToFrame(AGrid: TGeoFieldsGrid; AFrame: TGeoDataFrame;
  AUloha: Integer);
var
  R: Integer;
  Row: TGeoRow;
  PointName: string;
begin
  AFrame.ClearData;

  for R := AGrid.FixedRows to AGrid.RowCount - 1 do
  begin
    AGrid.GetGeoRow(R, Row);

    // Skip rows without point number
    PointName := Trim(string(Row.CB));
    if (PointName = '') or (PointName = '0') then
      Continue;

    Row.Uloha := AUloha;   // grid never carries it
    AFrame.AddRow(Row);
  end;
end;

end.
