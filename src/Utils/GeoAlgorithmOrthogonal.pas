unit GeoAlgorithmOrthogonal;

// Static (class-based) orthogonal survey method.
// Each input point: X = along-baseline offset (doměrek), Y = perpendicular offset (kolmice).
// The baseline is defined by the class-level StartPoint and EndPoint.

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
  // Direction vector from StartPoint to EndPoint
  dX := FEndPoint.X - FStartPoint.X;
  dY := FEndPoint.Y - FStartPoint.Y;
  d := Sqrt(Sqr(dX) + Sqr(dY));

  // Unit vector along the baseline (ux, uy)
  ux := dX / d;
  uy := dY / d;
  // Perpendicular unit vector (vx, vy) = rotate 90°
  vx := -uy;
  vy := ux;

  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    // X = along-baseline offset, Y = perpendicular offset
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
