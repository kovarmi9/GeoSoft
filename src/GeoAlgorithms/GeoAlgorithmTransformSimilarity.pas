unit GeoAlgorithmTransformSimilarity;

// Similarity transformation (4-parameter, variable scale).
// Model:  X' = X0 + lambda1*x - lambda2*y
//         Y' = Y0 + lambda2*x + lambda1*y
// Where:  omega = ArcTan2(lambda2, lambda1)  — rotation angle [rad]
//         Q     = sqrt(lambda1^2 + lambda2^2) — uniform scale factor
// Preserves angles; allows rotation, uniform scaling, and translation.
// Parameters are computed via centroid reduction and a closed-form solution.

interface

uses
  Math, SysUtils, Point, GeoAlgorithmBase, GeoAlgorithmTransformBase;

type
  // Similarity (Helmert) coordinate transformation — rotation + uniform scale + translation
  TSimilarityTransformation = class(TTransformationAlgorithm)
  private
    FLambda1, FLambda2: Double; // intermediate lambda parameters
    FOmega, FQ: Double;         // rotation angle [rad] and scale factor
    FX0, FY0: Double;           // translation parameters
  public
    procedure ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray); override;
    function Calculate(const InputPoints: TPointsArray): TPointsArray; override;

    property Lambda1: Double read FLambda1;
    property Lambda2: Double read FLambda2;
    property Omega: Double read FOmega;  // rotation angle [rad]
    property Q: Double read FQ;          // uniform scale factor
    property X0: Double read FX0;        // X translation
    property Y0: Double read FY0;        // Y translation
  end;

implementation

procedure TSimilarityTransformation.ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray);
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

  // Derive rotation, scale, and translation from lambda values
  FOmega := ArcTan2(FLambda2, FLambda1);
  FQ := Sqrt(Sqr(FLambda1) + Sqr(FLambda2)); // scale factor differs from 1 in similarity
  FX0 := CentroidXG - FLambda1 * CentroidXL + FLambda2 * CentroidYL;
  FY0 := CentroidYG - FLambda1 * CentroidYL - FLambda2 * CentroidXL;
end;

function TSimilarityTransformation.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  i: Integer;
  x, y: Double;
begin
  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    x := InputPoints[i].X;
    y := InputPoints[i].Y;

    Result[i] := InputPoints[i];
    Result[i].X := FX0 + FLambda1 * x - FLambda2 * y;
    Result[i].Y := FY0 + FLambda2 * x + FLambda1 * y;
  end;
end;

end.
