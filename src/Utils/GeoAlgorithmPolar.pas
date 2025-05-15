unit GeoAlgorithmPolar;

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TPolarMethodAlgorithm = class(TAlgorithm)
  private
    class var
      FPoint_A, FPoint_B: TPoint;
      Fpsi_B: Double; // měřený směr na orientační bod B v gonech
  public
    class property StationPoint: TPoint read FPoint_A write FPoint_A; // A
    class property OrientationPoint: TPoint read FPoint_B write FPoint_B; // B
    class property MeasuredDirection_Orientation: Double read Fpsi_B write Fpsi_B; // ψ_B [gon]

    class function Calculate(const InputPoints: TPointsArray): TPointsArray; override;
  end;

implementation

class function TPolarMethodAlgorithm.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  sigma_AB, psi_B_rad, delta, sigma_AP, psi_P_rad, X, Y: Double;
  i: Integer;
  d: Double;
begin
  // Výpočet směrníku mezi A a B (σ_AB), v radiánech
  sigma_AB := arctan2(FPoint_B.Y - FPoint_A.Y, FPoint_B.X - FPoint_A.X);

  // Měřený směr ψ_B převedený na radiány
  psi_B_rad := Fpsi_B * Pi / 200;

  // Výpočet orientačního posunu: Δ = σ_AB - ψ_B
  delta := sigma_AB - psi_B_rad;

  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    d := InputPoints[i].Y; // délka
    psi_P_rad := InputPoints[i].X * Pi / 200; // ψ_P

    // Výpočet směrníku na podrobný bod: σ_AP = Δ + ψ_P
    sigma_AP := delta + psi_P_rad;

    // Výpočet souřadnic
    X := FPoint_A.X + d * cos(sigma_AP);
    Y := FPoint_A.Y + d * sin(sigma_AP);

    // Výstupní bod
    Result[i].X := X;
    Result[i].Y := Y;
    Result[i].Z := InputPoints[i].Z;
    Result[i].PointNumber := InputPoints[i].PointNumber;
    Result[i].Quality := InputPoints[i].Quality;
    Result[i].Description := InputPoints[i].Description;
  end;
end;

end.

