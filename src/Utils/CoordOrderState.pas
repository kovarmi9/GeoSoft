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
  Point, GeoFieldsGrid;

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
procedure ApplyCoordOrder(AGrid: TGeoFieldsGrid);

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

procedure ApplyCoordOrder(AGrid: TGeoFieldsGrid);
begin
  if AGrid = nil then
    Exit;
  if GCoordOrder = coYX then
    AGrid.CoordOrder := gcoYX
  else
    AGrid.CoordOrder := gcoXY;
end;

end.
