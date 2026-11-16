unit CoordOrderState;

// Order of Y and X on screen and in files, TPoint.X is X

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Grids, Point, GeoRow,
  GeoPointsGrid, GeoFieldsGrid;

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

/// <summary>Column of Y, the pair starts at AFirstCol.</summary>
function CoordColY(AFirstCol: Integer): Integer;
/// <summary>Column of X, see CoordColY.</summary>
function CoordColX(AFirstCol: Integer): Integer;

/// <summary>Swaps two neighbour columns with all they have.</summary>
procedure SwapGridColumns(AGrid: TStringGrid; ACol1, ACol2: Integer);

/// <summary>Moves the Y and X boxes.</summary>
procedure ApplyCoordOrder(AYCtrl, AXCtrl: TWinControl);

/// <summary>Column order from the designer, AY and AX one more pair like Y and X.</summary>
procedure ApplyColumns(AGrid: TGeoFieldsGrid; const AHidden: TGeoFields; AY: TGeoField = Y; AX: TGeoField = X);

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

    if (ACol1 < Pts.ColumnHeaders.Count) and
      (ACol2 < Pts.ColumnHeaders.Count) then
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

procedure ApplyColumns(AGrid: TGeoFieldsGrid; const AHidden: TGeoFields;
  AY, AX: TGeoField);
var
  Order: TArray<TGeoField>;
  I, N: Integer;

  function IndexOf(AField: TGeoField): Integer;
  var
    J: Integer;
  begin
    Result := -1;
    for J := 0 to High(Order) do
      if Order[J] = AField then
        Exit(J);
  end;

  // Puts the pair in the set order
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
  if (AGrid = nil) or (Length(AGrid.DesignFields) = 0) then
    Exit;

  // The designer order, without the hidden fields
  Order := Copy(AGrid.DesignFields);
  N := 0;
  for I := 0 to High(Order) do
    if not (Order[I] in AHidden) then
    begin
      Order[N] := Order[I];
      Inc(N);
    end;
  SetLength(Order, N);
  Swap(Y, X);
  Swap(Ym, Xm);
  Swap(AY, AX);         // only the task knows its pair

  AGrid.SetColumns(Order);
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
