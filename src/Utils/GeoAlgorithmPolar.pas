unit GeoAlgorithmPolar;

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  // Záznam pro jeden orientační bod a měřený směr na něj
  TOrientation = record
    B: TPoint;       // orientační bod
    psi_B: Double;   // měřený směr na bod B [gon]
  end;

  TOrientations = array of TOrientation;

  TPolarMethodAlgorithm = class(TAlgorithm)
  private
    class var
      FA: TPoint;               // stanovisko A
      FB: TOrientations;        // orientační body B
  public
    // Veřejné vlastnosti pro přístup ke stanovisku a orientačním bodům
    class property A: TPoint read FA write FA;
    class property B: TOrientations read FB write FB;

    // Hlavní výpočetní funkce – vrací pole vypočtených bodů
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
  // Výpočet průměrného orientačního posunu Δ
  n := Length(FB);
  if n = 0 then
    raise Exception.Create('Nejsou zadány orientační body.');

  sum_delta := 0;
  for i := 0 to n - 1 do
  begin
    // výpočet směrníku σ_AB mezi A a Bᵢ
    sigma_AB := arctan2(FB[i].B.Y - FA.Y,
                        FB[i].B.X - FA.X);
    // převedení měřeného směru ψ_Bᵢ na radiány
    psi_B_rad := FB[i].psi_B * Pi / 200;

    // rozdíl mezi skutečným směrem a měřeným směrem = orientační posun
    sum_delta := sum_delta + (sigma_AB - psi_B_rad);
  end;

  delta := sum_delta / n; // průměrný orientační posun

  // Výpočet podrobných bodů s tímto Δ
  SetLength(Result, Length(Body));
  for j := 0 to High(Body) do
  begin
    d := Body[j].Y;                  // měřená délka
    psi := Body[j].X * Pi / 200;    // měřený směr ψ_P převedený na radiány
    sigma_AP := delta + psi;        // směrník na určovaný bod

    // výpočet souřadnic podrobného bodu
    X := FA.X + d * cos(sigma_AP);
    Y := FA.Y + d * sin(sigma_AP);

    // uložení do výstupního pole
    Result[j].X := X;
    Result[j].Y := Y;
    Result[j].Z := Body[j].Z;
    Result[j].PointNumber := Body[j].PointNumber;
    Result[j].Quality := Body[j].Quality;
    Result[j].Description := Body[j].Description;
  end;
end;

end.

