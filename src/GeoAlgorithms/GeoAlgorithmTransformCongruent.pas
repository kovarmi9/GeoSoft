unit GeoAlgorithmTransformCongruent;

// Congruent transformation (4-parameter, fixed scale Q = 1).
// Model:  X' = X0 + cos(omega)*x - sin(omega)*y
//         Y' = Y0 + sin(omega)*x + cos(omega)*y
// Preserves shape and size; only rotation and translation are estimated.
// Parameters are computed via centroid reduction and a closed-form solution.

interface

uses
  Math, SysUtils, Point, GeoAlgorithmBase, GeoAlgorithmTransformBase;

type
  // Congruent (rigid-body) coordinate transformation — rotation + translation only
  TCongruentTransformation = class(TTransformationAlgorithm)
  private
    FLambda1, FLambda2: Double; // intermediate lambda parameters from centroid solution
    FOmega, FQ: Double;         // rotation angle [rad] and scale factor (always 1)
    FX0, FY0: Double;           // translation parameters
  public
    procedure ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray); override;
    function Calculate(const InputPoints: TPointsArray): TPointsArray; override;

    property Lambda1: Double read FLambda1;
    property Lambda2: Double read FLambda2;
    property Omega: Double read FOmega;   // rotation angle [rad]
    property Q: Double read FQ;           // scale factor (= 1 for congruent)
    property X0: Double read FX0;         // X translation
    property Y0: Double read FY0;         // Y translation
  end;

implementation

procedure TCongruentTransformation.ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray);
var
  i, n: Integer;
  SumYL, SumXL, SumYG, SumXG: Double;
  CentroidYL, CentroidXL, CentroidYG, CentroidXG: Double;
  YrL, XrL, YrG, XrG: Double;
  SumSq, SumL1, SumL2: Double;
begin
  n := Length(LocalPoints);

  // Compute centroids of both point sets
  SumYL := 0; SumXL := 0; SumYG := 0; SumXG := 0;
  for i := 0 to n - 1 do
  begin
    SumYL := SumYL + LocalPoints[i].Y;
    SumXL := SumXL + LocalPoints[i].X;
    SumYG := SumYG + GlobalPoints[i].Y;
    SumXG := SumXG + GlobalPoints[i].X;
  end;

  CentroidYL := SumYL / n;
  CentroidXL := SumXL / n;
  CentroidYG := SumYG / n;
  CentroidXG := SumXG / n;

  SumSq := 0;
  SumL1 := 0;
  SumL2 := 0;

  // Accumulate centroid-reduced cross-products for the lambda solution
  for i := 0 to n - 1 do
  begin
    YrL := LocalPoints[i].Y - CentroidYL;
    XrL := LocalPoints[i].X - CentroidXL;
    YrG := GlobalPoints[i].Y - CentroidYG;
    XrG := GlobalPoints[i].X - CentroidXG;

    SumSq := SumSq + Sqr(XrL) + Sqr(YrL);
    SumL1 := SumL1 + (XrL * XrG + YrL * YrG);
    SumL2 := SumL2 + (XrL * YrG - YrL * XrG);
  end;

  // Lambda parameters (closed-form least-squares solution)
  FLambda1 := SumL1 / SumSq;
  FLambda2 := SumL2 / SumSq;

  // Derive rotation angle, scale (fixed to 1), and translations
  FOmega := ArcTan2(FLambda2, FLambda1);
  FQ := 1;
  FX0 := CentroidXG - Cos(FOmega) * CentroidXL + Sin(FOmega) * CentroidYL;
  FY0 := CentroidYG - Sin(FOmega) * CentroidXL - Cos(FOmega) * CentroidYL;
end;

function TCongruentTransformation.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  i: Integer;
  x, y: Double;
  CosOmega, SinOmega: Double;
begin
  SetLength(Result, Length(InputPoints));

  // Pre-compute trig values to avoid repeated calls in the loop
  CosOmega := Cos(FOmega);
  SinOmega := Sin(FOmega);

  for i := 0 to High(InputPoints) do
  begin
    x := InputPoints[i].X;
    y := InputPoints[i].Y;

    Result[i] := InputPoints[i];
    Result[i].X := FX0 + CosOmega * x - SinOmega * y;
    Result[i].Y := FY0 + SinOmega * x + CosOmega * y;
  end;
end;

end.
