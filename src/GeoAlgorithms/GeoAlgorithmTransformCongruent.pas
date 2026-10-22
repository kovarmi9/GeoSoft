unit GeoAlgorithmTransformCongruent;

// Congruent key, similarity without scale
//   A11 = cos(Omega), A12 = sin(Omega), A21 = -sin(Omega), A22 = cos(Omega)

interface

uses
  GeoAlgorithmBase, GeoAlgorithmTransformSimilarity;

type
  /// <summary>Congruent key, scale always 1.</summary>
  TCongruentTransformation = class(TSimilarityTransformation)
  protected
    class function MinimumPoints: Integer; override;
    class function KindName: string; override;
    procedure EstimateMatrix(const LocalReduced, GlobalReduced: TPointsArray); override;
  end;

implementation

class function TCongruentTransformation.MinimumPoints: Integer;
begin
  Result := 2;
end;

class function TCongruentTransformation.KindName: string;
begin
  Result := 'shodnostní';
end;

procedure TCongruentTransformation.EstimateMatrix(
  const LocalReduced, GlobalReduced: TPointsArray);
begin
  // Lambda1 and Lambda2
  inherited;

  // Divided by scale, cos and sin
  FA11 := FA11 / FQ;
  FA12 := FA12 / FQ;
  FA21 := FA21 / FQ;
  FA22 := FA22 / FQ;
  FQ := 1;
end;

end.
