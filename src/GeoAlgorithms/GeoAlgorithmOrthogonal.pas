unit GeoAlgorithmOrthogonal;

// Orthogonal (rectangular) survey method.
// Each input point carries a measured offset along the baseline (X = doměrek)
// and a perpendicular offset (Y = kolmice). The algorithm projects these into
// the global coordinate system defined by StartPoint and EndPoint.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  // Transforms orthogonal field measurements into global coordinates
  TOrthogonalMethodAlgorithm = class(TAlgorithm)
  private
    FStartPoint: TPoint; // first baseline point (origin of the local axis)
    FEndPoint: TPoint;   // second baseline point (defines direction of the local X axis)
  public
    constructor Create; overload;
    constructor Create(const AStartPoint, AEndPoint: TPoint); overload;

    property StartPoint: TPoint read FStartPoint write FStartPoint;
    property EndPoint: TPoint read FEndPoint write FEndPoint;

    // Each InputPoint.X = along-baseline offset, InputPoint.Y = perpendicular offset
    function Calculate(const InputPoints: TPointsArray): TPointsArray; override;
  end;

implementation

constructor TOrthogonalMethodAlgorithm.Create;
begin
  inherited Create;
end;

constructor TOrthogonalMethodAlgorithm.Create(const AStartPoint, AEndPoint: TPoint);
begin
  inherited Create;
  FStartPoint := AStartPoint;
  FEndPoint := AEndPoint;
end;

function TOrthogonalMethodAlgorithm.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  dX, dY, d, ux, uy, vx, vy: Double;
  i: Integer;
  measuredS, measuredK: Double;
begin
  // Compute the unit vector (ux, uy) along the baseline
  dX := FEndPoint.X - FStartPoint.X;
  dY := FEndPoint.Y - FStartPoint.Y;
  d := Sqrt(Sqr(dX) + Sqr(dY));

  if d = 0 then
    raise Exception.Create('StartPoint a EndPoint nesmí splývat.');

  ux := dX / d;
  uy := dY / d;

  // Perpendicular unit vector (vx, vy) = rotate (ux, uy) by 90°
  vx := -uy;
  vy := ux;

  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    measuredS := InputPoints[i].X; // along-baseline offset
    measuredK := InputPoints[i].Y; // perpendicular offset

    Result[i].X := FStartPoint.X + Scale * (measuredS * ux + measuredK * vx);
    Result[i].Y := FStartPoint.Y + Scale * (measuredS * uy + measuredK * vy);
    Result[i].Z := InputPoints[i].Z;
    Result[i].PointNumber := InputPoints[i].PointNumber;
    Result[i].Quality := InputPoints[i].Quality;
    Result[i].Description := InputPoints[i].Description;
  end;
end;

end.
