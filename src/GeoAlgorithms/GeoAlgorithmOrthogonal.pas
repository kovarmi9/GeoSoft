unit GeoAlgorithmOrthogonal;

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TOrthogonalMethodAlgorithm = class(TAlgorithm)
  private
    FStartPoint: TPoint; // P first baseline point
    FEndPoint:   TPoint; // K second baseline point
    FSP: Double;         // s_P stationing of P on the baseline
    FQP: Double;         // q_P perpendicular offset of P from baseline
    FSK: Double;         // s_K stationing of K on the baseline
    FQK: Double;         // q_K perpendicular offset of K from baseline
  public
    constructor Create; overload;
    constructor Create(const AStartPoint, AEndPoint: TPoint); overload;

    property StartPoint: TPoint read FStartPoint write FStartPoint;
    property EndPoint:   TPoint read FEndPoint   write FEndPoint;

    // Measured stationings and offsets of the baseline
    property SP: Double read FSP write FSP;
    property QP: Double read FQP write FQP;
    property SK: Double read FSK write FSK;
    property QK: Double read FQK write FQK;

    // InputPoint.X = s (stationing), InputPoint.Y = q (perpendicular offset)
    function Calculate(const InputPoints: TPointsArray): TPointsArray; override;
  end;

implementation

constructor TOrthogonalMethodAlgorithm.Create;
begin
  inherited Create;
  FSP := 0;  FQP := 0;
  FSK := 0;  FQK := 0;
end;

constructor TOrthogonalMethodAlgorithm.Create(const AStartPoint, AEndPoint: TPoint);
begin
  inherited Create;
  FStartPoint := AStartPoint;
  FEndPoint   := AEndPoint;
  FSP := 0;  FQP := 0;
  FSK := 0;  FQK := 0;
end;

function TOrthogonalMethodAlgorithm.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  dx, dy: Double;       // S-JTSK vector P→K
  dS, dQ: Double;       // tape vector P→K scaled to S-JTSK
  sP, qP: Double;       // start connection point in S-JTSK
  sK, qK: Double;       // end connection point in S-JTSK
  j: Double;            // dS^2 + dQ^2
  A, B: Double;         // Helmert coefficients
  si, qi: Double;       // detail point in S-JTSK
  offS, offQ: Double;   // offsets from P
  L: Double;            // SJTSK length of measuring line
  i: Integer;
begin
  ClearWarnings;

  if Sqrt(Sqr(FEndPoint.X - FStartPoint.X) + Sqr(FEndPoint.Y - FStartPoint.Y)) = 0 then
    raise Exception.Create('StartPoint a EndPoint nesmí splývat.');

  // 1: convert connection point tape measurements to S-JTSK
  sP := FSP * Scale;
  qP := FQP * Scale;
  sK := FSK * Scale;
  qK := FQK * Scale;

  dS := sK - sP;
  dQ := qK - qP;

  j := Sqr(dS) + Sqr(dQ);
  if j = 0 then
    raise Exception.Create('Připojovací body nesmí splývat na pásce.');

  L := Sqrt(j);

  // 2: Helmert similarity transform coefficients
  dx := FEndPoint.X - FStartPoint.X;
  dy := FEndPoint.Y - FStartPoint.Y;

  A := (dx * dS + dy * dQ) / j;
  B := (dy * dS - dx * dQ) / j;

  // 3: compute detail point coordinates
  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    si := InputPoints[i].X * Scale;
    qi := InputPoints[i].Y * Scale;

    offS := si - sP;
    offQ := qi - qP;

    // 4: Check <-L/3 ; 4L/3>
    if offS < -L / 3 then
      AddWarning(Format('Bod %d: prekroceno prodlouzeni za P o %.3f m (max. L/3 = %.3f m)',
        [InputPoints[i].PointNumber, Abs(offS) - L / 3, L / 3]))
    else if offS > 4 * L / 3 then
      AddWarning(Format('Bod %d: prekroceno prodlouzeni za K o %.3f m (max. L/3 = %.3f m)',
        [InputPoints[i].PointNumber, offS - 4 * L / 3, L / 3]));

    Result[i].X := FStartPoint.X + A * offS - B * offQ;
    Result[i].Y := FStartPoint.Y + B * offS + A * offQ;
    Result[i].Z           := InputPoints[i].Z;
    Result[i].PointNumber := InputPoints[i].PointNumber;
    Result[i].Quality     := InputPoints[i].Quality;
    Result[i].Description := InputPoints[i].Description;
  end;
end;

end.
