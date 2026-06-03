unit GeoAlgorithmPolar;

// Polar survey method (single station).
// The orientation correction (delta) is derived from one or more known orientation
// points and then applied to each measured direction to compute global coordinates.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  // One orientation reference: a known point B and the measured direction to it [gon]
  TOrientation = record
    B: TPoint;
    psi_B: Double; // measured direction to point B [gon]
  end;

  TOrientations = array of TOrientation;

  // Computes global coordinates from polar measurements (distance + direction)
  TPolarMethodAlgorithm = class(TAlgorithm)
  private
    FStation: TPoint;          // instrument station with known coordinates
    FOrientations: TOrientations; // orientation references used to compute delta
  public
    constructor Create; overload;
    constructor Create(const AStation: TPoint; const AOrientations: TOrientations); overload;

    property Station: TPoint read FStation write FStation;
    property Orientations: TOrientations read FOrientations write FOrientations;

    // Each input point: X = measured direction [gon], Y = measured distance [m]
    function Calculate(const Body: GeoAlgorithmBase.TPointsArray): GeoAlgorithmBase.TPointsArray; override;
  end;

implementation

constructor TPolarMethodAlgorithm.Create;
begin
  inherited Create;
end;

constructor TPolarMethodAlgorithm.Create(const AStation: TPoint; const AOrientations: TOrientations);
begin
  inherited Create;
  FStation := AStation;
  FOrientations := AOrientations;
end;

function TPolarMethodAlgorithm.Calculate(const Body: GeoAlgorithmBase.TPointsArray): GeoAlgorithmBase.TPointsArray;
var
  i, j: Integer;
  d, psi, sigma_AP, sigma_AB, delta, psi_B_rad, sum_delta: Double;
  X, Y: Double;
  n: Integer;
begin
  n := Length(FOrientations);
  if n = 0 then
    raise Exception.Create('Nebyly zadány žádné orientační body.');

  // Compute average orientation correction delta [rad] from all orientation points
  sum_delta := 0;
  for i := 0 to n - 1 do
  begin
    sigma_AB := arctan2(FOrientations[i].B.Y - FStation.Y,
                        FOrientations[i].B.X - FStation.X);
    psi_B_rad := FOrientations[i].psi_B * Pi / 200; // gon -> rad
    sum_delta := sum_delta + (sigma_AB - psi_B_rad);
  end;

  delta := sum_delta / n;

  // Apply orientation correction to each measured point
  SetLength(Result, Length(Body));
  for j := 0 to High(Body) do
  begin
    d := Body[j].Y;           // measured distance [m]
    psi := Body[j].X * Pi / 200; // measured direction gon -> rad
    sigma_AP := delta + psi;  // true azimuth [rad]

    X := FStation.X + d * cos(sigma_AP);
    Y := FStation.Y + d * sin(sigma_AP);

    Result[j] := Body[j];
    Result[j].X := X;
    Result[j].Y := Y;
  end;
end;

end.
