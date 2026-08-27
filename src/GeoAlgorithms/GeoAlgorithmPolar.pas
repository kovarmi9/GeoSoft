unit GeoAlgorithmPolar;

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TOrientation = record
    B: TPoint;
    psi_B: Double;
    dist_B: Double;
  end;

  TOrientations = array of TOrientation;

  TPolarMethodAlgorithm = class(TAlgorithm)
  private
    class var FStation: TPoint;
    class var FOrientations: TOrientations;
    class var FOrientationShift: Double;
    class var FStredniChybaOrPos: Double;
  public
    class property Station: TPoint read FStation write FStation;
    class property Orientations: TOrientations read FOrientations write FOrientations;
    class property OrientationShift: Double read FOrientationShift;
    class property StredniChybaOrPos: Double read FStredniChybaOrPos;

    class function Calculate(const Body: TPointsArray): TPointsArray; override;
  end;

implementation

const
  GON_TO_RAD = Pi / 200;
  RAD_TO_GON = 200 / Pi;
  MEZNI_DFI  = 0.08;

class function TPolarMethodAlgorithm.Calculate(const Body: TPointsArray): TPointsArray;
var
  i, j, n: Integer;
  sigma_AB, psi_B_rad, delta_i, delta: Double;
  sumSin, sumCos: Double;
  deltas: array of Double;
  dfi, ds, dist_computed: Double;
  sumDfiSqr, maxDist: Double;
  d, psi, sigma_AP: Double;
begin
  ClearWarnings;

  n := Length(FOrientations);
  if n = 0 then
    raise Exception.Create('Nejsou zadány orientační body.');

  SetLength(deltas, n);
  sumSin := 0;
  sumCos := 0;

  for i := 0 to n - 1 do
  begin
    sigma_AB := ArcTan2(FOrientations[i].B.Y - FStation.Y, FOrientations[i].B.X - FStation.X);
    psi_B_rad := FOrientations[i].psi_B * GON_TO_RAD;
    delta_i := sigma_AB - psi_B_rad;
    deltas[i] := delta_i;
    sumCos := sumCos + Cos(delta_i);
    sumSin := sumSin + Sin(delta_i);
  end;

  delta := ArcTan2(sumSin, sumCos);
  FOrientationShift := delta * RAD_TO_GON;

  sumDfiSqr := 0;
  maxDist := 0;

  for i := 0 to n - 1 do
  begin
    dfi := ArcTan2(Sin(deltas[i] - delta), Cos(deltas[i] - delta)) * RAD_TO_GON;
    sumDfiSqr := sumDfiSqr + Sqr(dfi);

    if Abs(dfi) > MEZNI_DFI then
      AddWarning(Format('Orientace %d: odchylka or. posunu dfi = %.4f g překračuje mezní hodnotu %.2f g ' +
        '- bod 10.2 vyhlášky 31/1995 Sb. v platném znění',
        [FOrientations[i].B.PointNumber, dfi, MEZNI_DFI]));

    if FOrientations[i].dist_B > 0 then
    begin
      dist_computed := Sqrt(Sqr(FOrientations[i].B.X - FStation.X) + Sqr(FOrientations[i].B.Y - FStation.Y));
      ds := FOrientations[i].dist_B - dist_computed;

      if dist_computed > maxDist then
        maxDist := dist_computed;

      if Abs(ds) > (0.012 * Sqrt(dist_computed) + 0.10) then
        AddWarning(Format('Orientace %d: odchylka délky ds = %.3f m překračuje mezní hodnotu %.3f m',
          [FOrientations[i].B.PointNumber, ds, 0.012 * Sqrt(dist_computed) + 0.10]));
    end;
  end;

  if n > 1 then
    FStredniChybaOrPos := Sqrt(sumDfiSqr / (n * (n - 1)))
  else
    FStredniChybaOrPos := 0;

  SetLength(Result, Length(Body));
  for j := 0 to High(Body) do
  begin
    d := Body[j].Y;
    psi := Body[j].X * GON_TO_RAD;
    sigma_AP := delta + psi;

    Result[j] := Body[j];
    Result[j].X := FStation.X + d * Cos(sigma_AP);
    Result[j].Y := FStation.Y + d * Sin(sigma_AP);

    if (maxDist > 0) and (d > maxDist) then
      AddWarning(Format('Bod %d: délka rajónu %.1f m je větší než nejvzdálenější orientace %.1f m ' +
        '- bod 4.3.2.2.2 Návodu pro obnovu katastrálního operátu',
        [Body[j].PointNumber, d, maxDist]));
  end;
end;

initialization
  TPolarMethodAlgorithm.FOrientationShift := 0;
  TPolarMethodAlgorithm.FStredniChybaOrPos := 0;

end.
