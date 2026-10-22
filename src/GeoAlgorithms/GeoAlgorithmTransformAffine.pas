unit GeoAlgorithmTransformAffine;

// Affine key, own scale in each axis
//   X = a1 * x + a2 * y, Y = b1 * x + b2 * y
//   A11 = b2, A12 = b1, A21 = a2, A22 = a1

interface

uses
  SysUtils, GeoAlgorithmBase, GeoAlgorithmTransformBase;

type
  /// <summary>Affine key.</summary>
  TAffineTransformation = class(TTransformationAlgorithm)
  protected
    class function MinimumPoints: Integer; override;
    class function KindName: string; override;
    procedure EstimateMatrix(const LocalReduced, GlobalReduced: TPointsArray); override;
  end;

implementation

class function TAffineTransformation.MinimumPoints: Integer;
begin
  Result := 3;
end;

class function TAffineTransformation.KindName: string;
begin
  Result := 'afinní';
end;

procedure TAffineTransformation.EstimateMatrix(
  const LocalReduced, GlobalReduced: TPointsArray);
var
  I: Integer;
  SumXX, SumYY, SumXY: Double;
  SumXTargetX, SumYTargetX, SumXTargetY, SumYTargetY: Double;
  Determinant: Double;
  A1, A2, B1, B2: Double;
begin
  SumXX := 0;
  SumYY := 0;
  SumXY := 0;
  SumXTargetX := 0;
  SumYTargetX := 0;
  SumXTargetY := 0;
  SumYTargetY := 0;
  for I := 0 to High(LocalReduced) do
  begin
    SumXX := SumXX + Sqr(LocalReduced[I].X);
    SumYY := SumYY + Sqr(LocalReduced[I].Y);
    SumXY := SumXY + LocalReduced[I].X * LocalReduced[I].Y;
    SumXTargetX := SumXTargetX + LocalReduced[I].X * GlobalReduced[I].X;
    SumYTargetX := SumYTargetX + LocalReduced[I].Y * GlobalReduced[I].X;
    SumXTargetY := SumXTargetY + LocalReduced[I].X * GlobalReduced[I].Y;
    SumYTargetY := SumYTargetY + LocalReduced[I].Y * GlobalReduced[I].Y;
  end;

  // Points on one line
  Determinant := SumXX * SumYY - Sqr(SumXY);
  if Determinant <= 1e-10 * SumXX * SumYY then
    raise Exception.Create('Identické body leží v přímce, afinní ' +
      'transformaci z nich nelze určit.');

  // Cramer's rule
  A1 := (SumXTargetX * SumYY - SumYTargetX * SumXY) / Determinant;
  A2 := (SumYTargetX * SumXX - SumXTargetX * SumXY) / Determinant;
  B1 := (SumXTargetY * SumYY - SumYTargetY * SumXY) / Determinant;
  B2 := (SumYTargetY * SumXX - SumXTargetY * SumXY) / Determinant;

  FA11 := B2;
  FA12 := B1;
  FA21 := A2;
  FA22 := A1;
end;

end.
