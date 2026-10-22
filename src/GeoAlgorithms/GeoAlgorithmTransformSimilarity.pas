unit GeoAlgorithmTransformSimilarity;

// Similarity key, rotation and scale
//   Lambda1 = sum(x * X + y * Y) / sum(x^2 + y^2)
//   Lambda2 = sum(x * Y - y * X) / sum(x^2 + y^2)
//   A11 = Lambda1, A12 = Lambda2, A21 = -Lambda2, A22 = Lambda1

interface

uses
  Math, SysUtils, GeoAlgorithmBase, GeoAlgorithmTransformBase;

type
  /// <summary>Similarity (Helmert) key.</summary>
  TSimilarityTransformation = class(TTransformationAlgorithm)
  protected
    FOmega, FQ: Double;
    class function MinimumPoints: Integer; override;
    class function KindName: string; override;
    procedure EstimateMatrix(const LocalReduced, GlobalReduced: TPointsArray); override;
  public
    property Omega: Double read FOmega;  // rotation [rad]
    property Q: Double read FQ;          // scale
  end;

implementation

class function TSimilarityTransformation.MinimumPoints: Integer;
begin
  Result := 2;
end;

class function TSimilarityTransformation.KindName: string;
begin
  Result := 'podobnostní';
end;

procedure TSimilarityTransformation.EstimateMatrix(
  const LocalReduced, GlobalReduced: TPointsArray);
var
  I: Integer;
  SumSquares, SumLambda1, SumLambda2: Double;
  Lambda1, Lambda2: Double;
begin
  SumSquares := 0;
  SumLambda1 := 0;
  SumLambda2 := 0;
  for I := 0 to High(LocalReduced) do
  begin
    SumSquares := SumSquares + Sqr(LocalReduced[I].X) + Sqr(LocalReduced[I].Y);
    SumLambda1 := SumLambda1 + LocalReduced[I].X * GlobalReduced[I].X +
                               LocalReduced[I].Y * GlobalReduced[I].Y;
    SumLambda2 := SumLambda2 + LocalReduced[I].X * GlobalReduced[I].Y -
                               LocalReduced[I].Y * GlobalReduced[I].X;
  end;

  // Points in one spot
  if SumSquares < 1e-10 then
    raise Exception.Create(
      'Identické body splývají, transformaci z nich nelze určit.');

  Lambda1 := SumLambda1 / SumSquares;
  Lambda2 := SumLambda2 / SumSquares;

  FOmega := ArcTan2(Lambda2, Lambda1);
  FQ := Sqrt(Sqr(Lambda1) + Sqr(Lambda2));

  // Target points in one spot
  if FQ < 1e-10 then
    raise Exception.Create(
      'Identické body splývají, transformaci z nich nelze určit.');

  FA11 := Lambda1;
  FA12 := Lambda2;
  FA21 := -Lambda2;
  FA22 := Lambda1;
end;

end.
