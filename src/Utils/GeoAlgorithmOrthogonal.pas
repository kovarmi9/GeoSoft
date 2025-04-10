unit GeoAlgorithmOrthogonal;

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TOrthogonalMethodAlgorithm = class(TAlgorithm)
  private
    class var FStartPoint, FEndPoint: TPoint;
  public
    class property StartPoint: TPoint read FStartPoint write FStartPoint;
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
  dX := FEndPoint.X - FStartPoint.X;
  dY := FEndPoint.Y - FStartPoint.Y;
  d := Sqrt(Sqr(dX) + Sqr(dY));

  // Jednotkový vektor v (ve smìru mìøické pøímky)
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

    Result[i].X := FStartPoint.X + Scale * (measuredS * ux + measuredK * vx);
    Result[i].Y := FStartPoint.Y + Scale * (measuredS * uy + measuredK * vy);
    Result[i].PointNumber := InputPoints[i].PointNumber;
    Result[i].Z := InputPoints[i].Z;
    Result[i].Quality := InputPoints[i].Quality;
    Result[i].Description := InputPoints[i].Description;
  end;
end;

end.
