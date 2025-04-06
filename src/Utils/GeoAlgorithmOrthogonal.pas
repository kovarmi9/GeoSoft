unit GeoAlgorithmOrthogonal;

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TOrthogonalMethodAlgorithm = class(TAlgorithm)
  private
    class var FBasePoint, FEndPoint: TPoint;
  public
    class property BasePoint: TPoint read FBasePoint write FBasePoint;
    class property EndPoint: TPoint read FEndPoint write FEndPoint;
    class function Calculate(const InputPoints: TPointsArray): TPointsArray; override;
  end;

implementation

class function TOrthogonalMethodAlgorithm.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  dX, dY, d, ux, uy, vx, vy: Double;
  i: Integer;
  measuredS, measuredK: Double;
begin
  // Vektor od BasePoint k EndPoint
  dX := FEndPoint.X - FBasePoint.X;
  dY := FEndPoint.Y - FBasePoint.Y;
  d := Sqrt(Sqr(dX) + Sqr(dY));
  if d = 0 then
    raise Exception.Create('BasePoint and EndPoint are identical.');

  // Jednotkový vektor ve smìru mìøické pøímky
  ux := dX / d;
  uy := dY / d;
  // Kolmý vektor
  vx := -uy;
  vy := ux;

  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    // X = stanièení a Y = kolmice
    measuredS := InputPoints[i].X;
    measuredK := InputPoints[i].Y;

    Result[i].X := FBasePoint.X + Scale * (measuredS * ux + measuredK * vx);
    Result[i].Y := FBasePoint.Y + Scale * (measuredS * uy + measuredK * vy);
    Result[i].PointNumber := InputPoints[i].PointNumber;
    Result[i].Z := InputPoints[i].Z;
    Result[i].Quality := InputPoints[i].Quality;
    Result[i].Description := InputPoints[i].Description;
  end;
end;

end.
