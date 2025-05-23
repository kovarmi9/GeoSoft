unit GeoAlgorithmOrthogonal;

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TOrthogonalMethodAlgorithm = class(TAlgorithm)
  private
    FStartPoint: TPoint;
    FEndPoint: TPoint;
  public
    constructor Create; overload;
    constructor Create(const AStartPoint, AEndPoint: TPoint); overload;

    property StartPoint: TPoint read FStartPoint write FStartPoint;
    property EndPoint: TPoint read FEndPoint write FEndPoint;

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
  dX := FEndPoint.X - FStartPoint.X;
  dY := FEndPoint.Y - FStartPoint.Y;
  d := Sqrt(Sqr(dX) + Sqr(dY));

  if d = 0 then
    raise Exception.Create('StartPoint a EndPoint nesmí splývat.');

  ux := dX / d;
  uy := dY / d;
  vx := -uy;
  vy := ux;

  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    measuredS := InputPoints[i].X;
    measuredK := InputPoints[i].Y;

    Result[i].X := FStartPoint.X + Scale * (measuredS * ux + measuredK * vx);
    Result[i].Y := FStartPoint.Y + Scale * (measuredS * uy + measuredK * vy);
    Result[i].Z := InputPoints[i].Z;
    Result[i].PointNumber := InputPoints[i].PointNumber;
    Result[i].Quality := InputPoints[i].Quality;
    Result[i].Description := InputPoints[i].Description;
  end;
end;

end.

