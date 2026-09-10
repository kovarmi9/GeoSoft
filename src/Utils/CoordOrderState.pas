unit CoordOrderState;

// Order in which the program shows and stores the coordinate pair.
// Y, X is the cadastre order and the default. The setting lives only for the
// current run, like GPointPrefix.
//
// It never changes what the fields mean: TPoint.X is always JTSK X and
// TPoint.Y is always JTSK Y. Only the order of grid columns, of protocol
// columns and of columns in saved files follows this setting.

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Grids, Point, GeoRow,
  GeoGrid, GeoPointsGrid, GeoFieldsGrid, ProtocolTable;

type
  TCoordOrder = (coYX, coXY);

var
  GCoordOrder: TCoordOrder = coYX;

// Coordinate pair in the current order
procedure CoordRead(const P: Point.TPoint; out AFirst, ASecond: Double);
procedure CoordWrite(var P: Point.TPoint; const AFirst, ASecond: Double);

// Exchanges X and Y in place. Used for the binary format, which stores the
// record itself, so the first slot has to carry the first coordinate.
procedure SwapXY(var P: Point.TPoint);

// Column captions in the current order
function FirstCoordName: string;
function SecondCoordName: string;

// Both coordinate captions, in the current order. Use ColWPair as the
// width of that protocol column.
function CoordNames(AWidth: Integer = ColWCoord): string;

// The two coordinates in the same order and the same width.
function CoordPair(const P: Point.TPoint; AWidth: Integer = ColWCoord;
  ADecimals: Integer = 2): string;

// A plain grid does not know which column carries which field, so the form
// has to ask. The pair sits in AFirstCol and the column right after it.
function CoordColY(AFirstCol: Integer): Integer;
function CoordColX(AFirstCol: Integer): Integer;

// Swaps two whole columns of a grid: caption, width, every cell and, when
// the grid has them, the validation filter. It knows nothing about
// coordinates - the form says which two columns to swap.
// The two columns have to be neighbours.
procedure SwapGridColumns(AGrid: TStringGrid; ACol1, ACol2: Integer);

// Column order of a field grid
procedure ApplyCoordOrder(AGrid: TGeoFieldsGrid); overload;

// Order of a pair of coordinate controls. It only moves them; the value
// stays in its own control.
procedure ApplyCoordOrder(AYCtrl, AXCtrl: TWinControl); overload;

implementation

procedure CoordRead(const P: Point.TPoint; out AFirst, ASecond: Double);
begin
  if GCoordOrder = coYX then
  begin
    AFirst  := P.Y;
    ASecond := P.X;
  end
  else
  begin
    AFirst  := P.X;
    ASecond := P.Y;
  end;
end;

procedure CoordWrite(var P: Point.TPoint; const AFirst, ASecond: Double);
begin
  if GCoordOrder = coYX then
  begin
    P.Y := AFirst;
    P.X := ASecond;
  end
  else
  begin
    P.X := AFirst;
    P.Y := ASecond;
  end;
end;

procedure SwapXY(var P: Point.TPoint);
var
  T: Double;
begin
  T   := P.X;
  P.X := P.Y;
  P.Y := T;
end;

function FirstCoordName: string;
begin
  if GCoordOrder = coYX then
    Result := 'Y'
  else
    Result := 'X';
end;

function SecondCoordName: string;
begin
  if GCoordOrder = coYX then
    Result := 'X'
  else
    Result := 'Y';
end;

function CoordNames(AWidth: Integer): string;
begin
  Result := Pad(FirstCoordName, AWidth) + ColGap + Pad(SecondCoordName, AWidth);
end;

function CoordPair(const P: Point.TPoint; AWidth: Integer;
  ADecimals: Integer): string;
begin
  if GCoordOrder = coYX then
    Result := Pad(Num(P.Y, ADecimals), AWidth) + ColGap +
              Pad(Num(P.X, ADecimals), AWidth)
  else
    Result := Pad(Num(P.X, ADecimals), AWidth) + ColGap +
              Pad(Num(P.Y, ADecimals), AWidth);
end;

function CoordColY(AFirstCol: Integer): Integer;
begin
  if GCoordOrder = coYX then
    Result := AFirstCol
  else
    Result := AFirstCol + 1;
end;

function CoordColX(AFirstCol: Integer): Integer;
begin
  if GCoordOrder = coYX then
    Result := AFirstCol + 1
  else
    Result := AFirstCol;
end;

procedure SwapGridColumns(AGrid: TStringGrid; ACol1, ACol2: Integer);
var
  R, W, F1, F2: Integer;
  S: string;
  Geo: TGeoGrid;
  Pts: TGeoPointsGrid;
begin
  W := AGrid.ColWidths[ACol1];
  AGrid.ColWidths[ACol1] := AGrid.ColWidths[ACol2];
  AGrid.ColWidths[ACol2] := W;

  for R := 0 to AGrid.RowCount - 1 do      // row 0 carries the caption
  begin
    S := AGrid.Cells[ACol1, R];
    AGrid.Cells[ACol1, R] := AGrid.Cells[ACol2, R];
    AGrid.Cells[ACol2, R] := S;
  end;

  // TGeoGrid keeps the captions in a list and writes them into row 0
  if AGrid is TGeoGrid then
  begin
    Geo := TGeoGrid(AGrid);
    if (ACol1 < Geo.ColumnHeaders.Count) and (ACol2 < Geo.ColumnHeaders.Count) then
    begin
      S := Geo.ColumnHeaders[ACol1];
      Geo.ColumnHeaders[ACol1] := Geo.ColumnHeaders[ACol2];
      Geo.ColumnHeaders[ACol2] := S;
    end;
  end;

  // The columns are neighbours, so moving one filter is already a swap
  if AGrid is TGeoPointsGrid then
  begin
    Pts := TGeoPointsGrid(AGrid);
    F1  := ACol1 - Pts.FixedCols;
    F2  := ACol2 - Pts.FixedCols;
    if (F1 >= 0) and (F2 >= 0) and
       (F1 < Pts.ColumnFilters.Count) and (F2 < Pts.ColumnFilters.Count) then
      Pts.ColumnFilters.Items[F1].Index := F2;
  end;
end;

type
  TFieldTexts = array[TGeoField] of string;
  TGridTexts = array of TFieldTexts;

// Reads every data cell keyed by field, so it survives a column reorder.
procedure ReadGridTexts(AGrid: TGeoFieldsGrid; out ATexts: TGridTexts);
var
  Col: array[TGeoField] of Integer;
  F: TGeoField;
  R: Integer;
begin
  for F := Low(TGeoField) to High(TGeoField) do
    Col[F] := AGrid.FieldToCol(F);

  SetLength(ATexts, AGrid.RowCount);
  for R := AGrid.FixedRows to AGrid.RowCount - 1 do
    for F := Low(TGeoField) to High(TGeoField) do
      if Col[F] >= 0 then
        ATexts[R][F] := AGrid.Cells[Col[F], R];
end;

// Writes them back, each value into the column its field uses now.
procedure WriteGridTexts(AGrid: TGeoFieldsGrid; const ATexts: TGridTexts);
var
  Col: array[TGeoField] of Integer;
  F: TGeoField;
  R: Integer;
begin
  for F := Low(TGeoField) to High(TGeoField) do
    Col[F] := AGrid.FieldToCol(F);

  for R := AGrid.FixedRows to AGrid.RowCount - 1 do
  begin
    if R > High(ATexts) then
      Break;
    for F := Low(TGeoField) to High(TGeoField) do
      if Col[F] >= 0 then
        AGrid.Cells[Col[F], R] := ATexts[R][F];
  end;
end;

procedure ApplyCoordOrder(AGrid: TGeoFieldsGrid);
var
  Texts: TGridTexts;
  ColX, ColY: Integer;
begin
  if AGrid = nil then
    Exit;

  ColX := AGrid.FieldToCol(X);
  ColY := AGrid.FieldToCol(Y);
  if (ColX < 0) or (ColY < 0) then
    Exit;                            // one of the two is not shown
  if (GCoordOrder = coYX) = (ColY < ColX) then
    Exit;                            // already in the wanted order

  ReadGridTexts(AGrid, Texts);       // content is the application's
  if GCoordOrder = coYX then
    AGrid.SetFieldOrder([Y, X])      // order is the component's
  else
    AGrid.SetFieldOrder([]);         // back to the TGeoField order
  WriteGridTexts(AGrid, Texts);
end;

procedure ApplyCoordOrder(AYCtrl, AXCtrl: TWinControl);
var
  L, TY, TX: Integer;
begin
  if (AYCtrl = nil) or (AXCtrl = nil) then
    Exit;
  if (GCoordOrder = coYX) = (AYCtrl.Left < AXCtrl.Left) then
    Exit;                      // already in the wanted order

  L := AYCtrl.Left;
  AYCtrl.Left := AXCtrl.Left;
  AXCtrl.Left := L;

  TY := AYCtrl.TabOrder;       // keeps tabbing left to right
  TX := AXCtrl.TabOrder;
  AYCtrl.TabOrder := TX;
  AXCtrl.TabOrder := TY;
end;

end.
