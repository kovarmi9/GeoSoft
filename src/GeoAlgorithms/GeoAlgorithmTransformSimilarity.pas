unit GeoAlgorithmTransformSimilarity;

interface

uses
  Math, SysUtils, Point, GeoAlgorithmBase, GeoAlgorithmTransformBase;

type
  TSimilarityTransformation = class(TTransformationAlgorithm)
  private
    FLambda1, FLambda2: Double;
    FX0, FY0: Double;
    FQ: Double;
  public
    procedure ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray); override;
    function Calculate(const InputPoints: TPointsArray): TPointsArray; override;

    property Lambda1: Double read FLambda1;
    property Lambda2: Double read FLambda2;
    property X0: Double read FX0;
    property Y0: Double read FY0;
    property Q: Double read FQ;
  end;

implementation

procedure TSimilarityTransformation.ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray);
var
  i, n: Integer;
  SumY, SumX, SumYG, SumXG: Double;
  yBar, xBar, yGBar, xGBar: Double;
  yr, xr, yGr, xGr: Double;
  SumSq, SumL1, SumL2: Double;
begin
  n := Length(LocalPoints);
  if (n <> Length(GlobalPoints)) or (n < 2) then
    raise Exception.Create('Počet bodů v obou soustavách musí být stejný a alespoň 2.');

  SumY := 0; SumX := 0; SumYG := 0; SumXG := 0;
  for i := 0 to n - 1 do
  begin
    SumY := SumY + LocalPoints[i].Y;
    SumX := SumX + LocalPoints[i].X;
    SumYG := SumYG + GlobalPoints[i].Y;
    SumXG := SumXG + GlobalPoints[i].X;
  end;

  yBar := SumY / n;
  xBar := SumX / n;
  yGBar := SumYG / n;
  xGBar := SumXG / n;

  SumSq := 0;
  SumL1 := 0;
  SumL2 := 0;

  for i := 0 to n - 1 do
  begin
    yr := LocalPoints[i].Y - yBar;
    xr := LocalPoints[i].X - xBar;
    yGr := GlobalPoints[i].Y - yGBar;
    xGr := GlobalPoints[i].X - xGBar;

    SumSq := SumSq + Sqr(xr) + Sqr(yr);
    SumL1 := SumL1 + (xr * xGr + yr * yGr);
    SumL2 := SumL2 + (xr * yGr - yr * xGr);
  end;

  FLambda1 := SumL1 / SumSq;
  FLambda2 := SumL2 / SumSq;
  FQ := Sqrt(Sqr(FLambda1) + Sqr(FLambda2));

  FX0 := xGBar - FLambda1 * xBar + FLambda2 * yBar;
  FY0 := yGBar - FLambda1 * yBar - FLambda2 * xBar;
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
