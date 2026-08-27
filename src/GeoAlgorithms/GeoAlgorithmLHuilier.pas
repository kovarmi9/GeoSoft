unit GeoAlgorithmLHuilier;

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TLHuilierAlgorithm = class(TAlgorithm)
  private
    class var FArea: Double;
    class var FSphericalExcess: Double;
    class var FEarthRadius: Double;
    class function AngularDistance(const P1, P2: TPoint): Double;
    class function TriangleExcess(const P1, P2, P3: TPoint): Double;
  public
    class property Area: Double read FArea;
    class property SphericalExcess: Double read FSphericalExcess;
    class property EarthRadius: Double read FEarthRadius write FEarthRadius;

    // InputPoints: vrcholy polygonu, X = zeměpisná šířka [°], Y = zeměpisná délka [°]
    // Výsledná plocha je ve vlastnosti Area [m²]
    class function Calculate(const InputPoints: TPointsArray): TPointsArray; override;
  end;

implementation

const
  DEG_TO_RAD = Pi / 180;

class function TLHuilierAlgorithm.AngularDistance(const P1, P2: TPoint): Double;
var
  lat1, lon1, lat2, lon2, dLat, dLon, a: Double;
begin
  lat1 := P1.X * DEG_TO_RAD;
  lon1 := P1.Y * DEG_TO_RAD;
  lat2 := P2.X * DEG_TO_RAD;
  lon2 := P2.Y * DEG_TO_RAD;

  dLat := lat2 - lat1;
  dLon := lon2 - lon1;

  a := Sqr(Sin(dLat / 2)) + Cos(lat1) * Cos(lat2) * Sqr(Sin(dLon / 2));
  Result := 2 * ArcTan2(Sqrt(a), Sqrt(1 - a));
end;

class function TLHuilierAlgorithm.TriangleExcess(const P1, P2, P3: TPoint): Double;
var
  a, b, c, s, tanE4: Double;
begin
  a := AngularDistance(P2, P3);
  b := AngularDistance(P1, P3);
  c := AngularDistance(P1, P2);

  s := (a + b + c) / 2;

  tanE4 := Sqrt(Abs(
    Tan(s / 2) * Tan((s - a) / 2) * Tan((s - b) / 2) * Tan((s - c) / 2)
  ));

  Result := 4 * ArcTan(tanE4);
end;

class function TLHuilierAlgorithm.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  i, n: Integer;
  totalExcess: Double;
begin
  ClearWarnings;

  n := Length(InputPoints);
  if n < 3 then
    raise Exception.Create('Pro výpočet plochy jsou potřeba alespoň 3 body.');

  totalExcess := 0;
  for i := 1 to n - 2 do
    totalExcess := totalExcess + TriangleExcess(InputPoints[0], InputPoints[i], InputPoints[i + 1]);

  FSphericalExcess := totalExcess;
  FArea := Abs(totalExcess) * Sqr(FEarthRadius);

  if Abs(FSphericalExcess) < 1e-15 then
    AddWarning('Sférický exces je nulový — body mohou být kolineární.');

  Result := Copy(InputPoints);
end;

initialization
  TLHuilierAlgorithm.FEarthRadius := 6371000.0;
  TLHuilierAlgorithm.FArea := 0;
  TLHuilierAlgorithm.FSphericalExcess := 0;

end.
