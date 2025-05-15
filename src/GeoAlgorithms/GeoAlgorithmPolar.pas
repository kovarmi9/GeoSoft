unit GeoAlgorithmPolar;

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TOrientation = record
    B: TPoint;
    psi_B: Double; // mìøený smìr na bod B [gon]
  end;

  TOrientations = array of TOrientation;

  TPolarMethodAlgorithm = class(TAlgorithm)
  private
    FStation: TPoint;
    FOrientations: TOrientations;
  public
    property Station: TPoint read FStation write FStation;
    property Orientations: TOrientations read FOrientations write FOrientations;

    function Calculate(const Body: TPointsArray): TPointsArray; override;
  end;

implementation

function TPolarMethodAlgorithm.Calculate(const Body: TPointsArray): TPointsArray;
var
  i, j: Integer;
  d, psi, sigma_AP, sigma_AB, delta, psi_B_rad, sum_delta: Double;
  X, Y: Double;
  n: Integer;
begin
  n := Length(FOrientations);
  if n = 0 then
    raise Exception.Create('Nebyly zadány žádné orientaèní body.');

  sum_delta := 0;
  for i := 0 to n - 1 do
  begin
    sigma_AB := arctan2(FOrientations[i].B.Y - FStation.Y,
                        FOrientations[i].B.X - FStation.X);
    psi_B_rad := FOrientations[i].psi_B * Pi / 200;
    sum_delta := sum_delta + (sigma_AB - psi_B_rad);
  end;

  delta := sum_delta / n;

  SetLength(Result, Length(Body));
  for j := 0 to High(Body) do
  begin
    d := Body[j].Y;
    psi := Body[j].X * Pi / 200;
    sigma_AP := delta + psi;

    X := FStation.X + d * cos(sigma_AP);
    Y := FStation.Y + d * sin(sigma_AP);

    Result[j] := Body[j];
    Result[j].X := X;
    Result[j].Y := Y;
  end;
end;

end.

