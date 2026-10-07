unit CoordOrderState;

// Order of Y and X on screen and in text files. Default Y, X, kept only for this run.
// It never changes the fields: TPoint.X is always X.

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Grids, Point, GeoRow,
  GeoPointsGrid, GeoFieldsGrid, ProtocolTable;

type
  /// <summary>Order of the coordinate pair: Y, X or X, Y.</summary>
  TCoordOrder = (coYX, coXY);

var
  /// <summary>Current order.</summary>
  GCoordOrder: TCoordOrder = coYX;

/// <summary>Coordinate pair in the current order.</summary>
procedure CoordRead(const P: Point.TPoint; out AFirst, ASecond: Double);
/// <summary>Coordinate pair in the current order.</summary>
procedure CoordWrite(var P: Point.TPoint; const AFirst, ASecond: Double);

/// <summary>Captions Y and X in the current order.</summary>
function CoordNames(AWidth: Integer = ColWCoord): string;

/// <summary>Both coordinates as text.</summary>
function CoordPair(const P: Point.TPoint; AWidth: Integer = ColWCoord;
  ADecimals: Integer = 2): string;

/// <summary>Column of Y; the pair starts at AFirstCol.</summary>
function CoordColY(AFirstCol: Integer): Integer;
/// <summary>Column of X, see CoordColY.</summary>
function CoordColX(AFirstCol: Integer): Integer;

/// <summary>Swaps two neighbour columns with all they have.</summary>
procedure SwapGridColumns(AGrid: TStringGrid; ACol1, ACol2: Integer);

/// <summary>Moves the Y and X boxes.</summary>
procedure ApplyCoordOrder(AYCtrl, AXCtrl: TWinControl);

/// <summary>Column order from the designer; keeps the content.</summary>
procedure ApplyColumns(AGrid: TGeoFieldsGrid; const AHidden: TGeoFields);

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

function CoordNames(AWidth: Integer): string;
begin
  if GCoordOrder = coYX then
    Result := Pad('Y', AWidth) + ColGap + Pad('X', AWidth)
  else
    Result := Pad('X', AWidth) + ColGap + Pad('Y', AWidth);
end;

function CoordPair(const P: Point.TPoint; AWidth: Integer;
  ADecimals: Integer): string;
var
  First, Second: Double;
begin
  CoordRead(P, First, Second);
  Result := Pad(Num(First, ADecimals), AWidth) + ColGap +
            Pad(Num(Second, ADecimals), AWidth);
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

  // Points grid: also captions and filters
  if AGrid is TGeoPointsGrid then
  begin
    Pts := TGeoPointsGrid(AGrid);

    if (ACol1 < Pts.ColumnHeaders.Count) and (ACol2 < Pts.ColumnHeaders.Count) then
    begin
      S := Pts.ColumnHeaders[ACol1];
      Pts.ColumnHeaders[ACol1] := Pts.ColumnHeaders[ACol2];
      Pts.ColumnHeaders[ACol2] := S;
    end;

    // Neighbours: one move is a swap
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

// Cell texts by field
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

// Texts back by field
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

// Current order of the data columns
function CurrentOrder(AGrid: TGeoFieldsGrid): TArray<TGeoField>;
var
  I: Integer;
begin
  SetLength(Result, AGrid.DataFieldCount);
  for I := 0 to High(Result) do
    Result[I] := AGrid.ColToField(AGrid.FixedCols + I);
end;

procedure ApplyColumns(AGrid: TGeoFieldsGrid; const AHidden: TGeoFields);
var
  Order, Cur: TArray<TGeoField>;
  Fields: TGeoFields;
  Texts: TGridTexts;
  I, N, P: Integer;
  F: TGeoField;
  S: string;
  Same: Boolean;

  function IndexOf(AField: TGeoField): Integer;
  var
    J: Integer;
  begin
    Result := -1;
    for J := 0 to High(Order) do
      if Order[J] = AField then
        Exit(J);
  end;

  // Puts the pair in the switch order
  procedure Swap(AY, AX: TGeoField);
  var
    IY, IX: Integer;
  begin
    IY := IndexOf(AY);
    IX := IndexOf(AX);
    if (IY < 0) or (IX < 0) then
      Exit;

    if ((GCoordOrder = coYX) and (IY > IX)) or
       ((GCoordOrder = coXY) and (IY < IX)) then
    begin
      Order[IY] := AX;
      Order[IX] := AY;
    end;
  end;

begin
  if (AGrid = nil) or (AGrid.ColumnFields.Count = 0) then
    Exit;

  // The designer order, without the hidden fields
  SetLength(Order, AGrid.ColumnFields.Count);
  Fields := [];
  N := 0;
  for I := 0 to AGrid.ColumnFields.Count - 1 do
  begin
    S := AGrid.ColumnFields[I];
    P := Pos('=', S);
    if P > 0 then
      S := Copy(S, 1, P - 1);
    if not FindGeoField(Trim(S), F) or (F in AHidden) or (F in Fields) then
      Continue;

    Order[N] := F;
    Include(Fields, F);
    Inc(N);
  end;
  SetLength(Order, N);

  Swap(Y, X);
  Swap(Ym, Xm);

  // Unchanged, nothing to do
  if AGrid.GeoFields = Fields then
  begin
    Cur := CurrentOrder(AGrid);
    Same := Length(Cur) = N;
    for I := 0 to N - 1 do
      if Same and (Cur[I] <> Order[I]) then
        Same := False;
    if Same then
      Exit;
  end;

  ReadGridTexts(AGrid, Texts);       // content is the application's
  AGrid.GeoFields := Fields;         // layout is the component's
  AGrid.SetFieldOrder(Order);
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
