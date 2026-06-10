unit GeoAlgorithmOrthogonal;

// Orthogonal (rectangular) survey method.
// Each input point carries a measured stationing s (along the tape) and
// perpendicular offset q (kolmice). The algorithm projects these into
// the global coordinate system defined by StartPoint and EndPoint.
//
// Optional baseline stretching: if the measured stationings of P and K
// (SP, SK) are set, the coordinate distance is scaled to match the
// measured tape length. Perpendicular offsets QP and QK shift the local
// origin so that detail points are computed relative to P on the tape.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TOrthogonalMethodAlgorithm = class(TAlgorithm)
  private
    class var FStartPoint: TPoint; // P — first baseline point (known coords)
    class var FEndPoint:   TPoint; // K — second baseline point (known coords)
    class var FSP: Double;         // s_P — stationing of P on the tape (default 0)
    class var FQP: Double;         // q_P — perpendicular offset of P from tape (default 0)
    class var FSK: Double;         // s_K — stationing of K on the tape (default 0)
    class var FQK: Double;         // q_K — perpendicular offset of K from tape (default 0)
  public
    class property StartPoint: TPoint read FStartPoint write FStartPoint;
    class property EndPoint:   TPoint read FEndPoint   write FEndPoint;

    // Measured stationings and offsets of baseline anchors on the tape.
    // Leave at zero to skip stretching correction.
    class property SP: Double read FSP write FSP;
    class property QP: Double read FQP write FQP;
    class property SK: Double read FSK write FSK;
    class property QK: Double read FQK write FQK;

    // InputPoint.X = s (stationing), InputPoint.Y = q (perpendicular offset)
    class function Calculate(const InputPoints: TPointsArray): TPointsArray; override;
  end;

implementation

class function TOrthogonalMethodAlgorithm.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  dX, dY, dg: Double;  // coordinate vector P->K and its length
  dm: Double;          // measured tape length between P and K
  stretch: Double;     // stretching factor = dg / dm
  ux, uy: Double;      // unit vector along P->K (from coordinates)
  vx, vy: Double;      // unit vector perpendicular to P->K
  s, q: Double;        // detail point offsets relative to P on the tape
  i: Integer;
begin
  // Coordinate vector and length P->K
  dX := FEndPoint.X - FStartPoint.X;
  dY := FEndPoint.Y - FStartPoint.Y;
  dg := Sqrt(Sqr(dX) + Sqr(dY));

  if dg = 0 then
    raise Exception.Create('StartPoint a EndPoint nesmí splývat.');

  // Unit vector along baseline (from coordinates)
  ux := dX / dg;
  uy := dY / dg;

  // Perpendicular unit vector (rotate 90 degrees)
  vx := -uy;
  vy :=  ux;

  // Stretching: ratio of coordinate distance to measured tape length.
  // Applied only when SP and SK are set (measured length > 0).
  dm := FSK - FSP;
  if dm > 0 then
    stretch := dg / dm
  else
    stretch := 1.0;  // no stretching — use coordinates as-is

  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    // Offsets relative to P (subtract P's position on the tape)
    s := InputPoints[i].X - FSP;
    q := InputPoints[i].Y - FQP;

    Result[i].X := FStartPoint.X + Scale * stretch * (s * ux + q * vx);
    Result[i].Y := FStartPoint.Y + Scale * stretch * (s * uy + q * vy);
    Result[i].Z           := InputPoints[i].Z;
    Result[i].PointNumber := InputPoints[i].PointNumber;
    Result[i].Quality     := InputPoints[i].Quality;
    Result[i].Description := InputPoints[i].Description;
  end;
end;

initialization
  TOrthogonalMethodAlgorithm.FSP := 0;
  TOrthogonalMethodAlgorithm.FQP := 0;
  TOrthogonalMethodAlgorithm.FSK := 0;
  TOrthogonalMethodAlgorithm.FQK := 0;

end.
