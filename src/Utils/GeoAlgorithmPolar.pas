unit GeoAlgorithmPolar;

// Static (class-based) polar survey method.
// The orientation correction (delta) is computed from one or more orientation points
// and then applied to each measured direction to get global coordinates.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  // One orientation reference: a known point B and the measured direction to it [gon]
  TOrientation = record
    B: TPoint;       // orientation reference point with known coordinates
    psi_B: Double;   // measured direction to point B [gon]
  end;

  TOrientations = array of TOrientation;

  TPolarMethodAlgorithm = class(TAlgorithm)
  private
    class var
      FA: TPoint;          // instrument station A with known coordinates
      FB: TOrientations;   // orientation references used to compute delta
  public
    class property A: TPoint read FA write FA;
    class property B: TOrientations read FB write FB;

    // Each input point: X = measured direction [gon], Y = measured distance [m]
    class function Calculate(const Body: TPointsArray): TPointsArray; override;
  end;

implementation

class function TPolarMethodAlgorithm.Calculate(const Body: TPointsArray): TPointsArray;
var
  i, j: Integer;
  d, psi, sigma_AP, sigma_AB, delta, psi_B_rad, sum_delta: Double;
  X, Y: Double;
  n: Integer;
begin
  // Compute average orientation correction delta
  n := Length(FB);
  if n = 0 then
    raise Exception.Create('Nejsou zadány orientační body.');

  sum_delta := 0;
  for i := 0 to n - 1 do
  begin
    // True azimuth sigma_AB from station A to orientation point Bi
    sigma_AB := arctan2(FB[i].B.Y - FA.Y,
                        FB[i].B.X - FA.X);
    // Convert measured direction from gon to rad
    psi_B_rad := FB[i].psi_B * Pi / 200;

    // Orientation correction for this reference point
    sum_delta := sum_delta + (sigma_AB - psi_B_rad);
  end;

  delta := sum_delta / n; // mean orientation correction

  // Compute detail-point coordinates using delta
  SetLength(Result, Length(Body));
  for j := 0 to High(Body) do
  begin
    d   := Body[j].Y;               // measured distance [m]
    psi := Body[j].X * Pi / 200;    // measured direction gon -> rad
    sigma_AP := delta + psi;        // true azimuth to the detail point

    X := FA.X + d * cos(sigma_AP);
    Y := FA.Y + d * sin(sigma_AP);

    Result[j].X := X;
    Result[j].Y := Y;
    Result[j].Z := Body[j].Z;
    Result[j].PointNumber := Body[j].PointNumber;
    Result[j].Quality := Body[j].Quality;
    Result[j].Description := Body[j].Description;
  end;
end;

end.
