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
  Vcl.Controls, Point, GeoRow, GeoFieldsGrid;

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
