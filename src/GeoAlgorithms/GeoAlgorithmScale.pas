unit GeoAlgorithmScale;

// Length scale from the map projection and from the height
//   projection: m = 0,9999 + 1,22822e-14 dr^2 - 3,154e-21 dr^3
//                   + 1,848e-27 dr^4,  dr = sqrt(X^2 + Y^2) - 1298039
//   height:     m = R / (R + H)

interface

uses
  System.Math;

const
  EARTH_RADIUS = 6381000;   // [m]

type
  /// <summary>Length scale of S-JTSK at one place.</summary>
  TLengthScale = class
  public
    /// <summary>Scale of the Krovak projection, NaN outside S-JTSK.</summary>
    class function ProjectionScale(const AY, AX: Double): Double; static;
    /// <summary>Scale from the height, NaN outside 100 to 3000 m.</summary>
    class function HeightScale(const AHeight: Double): Double; static;
  end;

implementation

class function TLengthScale.ProjectionScale(const AY, AX: Double): Double;
var
  Rho, D: Double;
begin
  Rho := Sqrt(Sqr(AX) + Sqr(AY));
  if (Rho <= 1100000) or (Rho >= 1500000) then
    Exit(NaN);                 // not S-JTSK coordinates

  D := Rho - 1298039;
  Result := 0.9999 + 1.22822e-14 * Power(D, 2) - 3.154e-21 * Power(D, 3) +
    1.848e-27 * Power(D, 4);
end;

class function TLengthScale.HeightScale(const AHeight: Double): Double;
begin
  if (AHeight <= 100) or (AHeight >= 3000) then
    Exit(NaN);                 // no height of the Czech Republic

  Result := EARTH_RADIUS / (EARTH_RADIUS + AHeight);
end;

end.
