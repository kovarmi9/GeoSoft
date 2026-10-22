unit GeoAlgorithmTransformBase;

// Base of the transformation keys
//   Y = ShiftY + A11 * y + A12 * x
//   X = ShiftX + A21 * y + A22 * x

interface

uses SysUtils, Point, GeoAlgorithmBase;

type
  // Residuals of one identical point
  TPointResidual = record
    PointNumber: Int64;
    Vy, Vx: Double;   // transformed minus given
    Sxy:    Double;   // sqrt((Vy^2 + Vx^2) / 2)
  end;

  TPointResiduals = array of TPointResidual;

  /// <summary>Centroids, shifts and residuals of a key.</summary>
  TTransformationAlgorithm = class abstract(TAlgorithmBase)
  private
    FResiduals: TPointResiduals;
    FSumVV: Double;
    FShiftY, FShiftX: Double;
    /// <summary>Centroid of the points.</summary>
    class function Centroid(const Points: TPointsArray): TPoint;
  protected
    FA11, FA12, FA21, FA22: Double;

    /// <summary>Fewest identical points of the key.</summary>
    class function MinimumPoints: Integer; virtual; abstract;
    /// <summary>Name of the key for messages.</summary>
    class function KindName: string; virtual; abstract;
    /// <summary>Fills A11..A22 from points reduced to centroids.</summary>
    procedure EstimateMatrix(const LocalReduced, GlobalReduced: TPointsArray); virtual; abstract;
  public
    /// <summary>Makes the key and the residuals.</summary>
    procedure ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray);

    /// <summary>Applies the key, Z stays as it was.</summary>
    function Calculate(const InputPoints: TPointsArray): TPointsArray;

    property A11: Double read FA11;
    property A12: Double read FA12;
    property A21: Double read FA21;
    property A22: Double read FA22;
    property ShiftY: Double read FShiftY;
    property ShiftX: Double read FShiftX;

    /// <summary>Residuals of the identical points.</summary>
    property Residuals: TPointResiduals read FResiduals;

    /// <summary>Sum of Vy^2 + Vx^2.</summary>
    property SumVV: Double read FSumVV;
  end;

implementation

// Centroid, mean of Y and X
class function TTransformationAlgorithm.Centroid(
  const Points: TPointsArray): TPoint;
var
  I: Integer;
begin
  Result := Default(TPoint);
  for I := 0 to High(Points) do
  begin
    Result.Y := Result.Y + Points[I].Y;
    Result.X := Result.X + Points[I].X;
  end;
  Result.Y := Result.Y / Length(Points);
  Result.X := Result.X / Length(Points);
end;

// Checks, centroids, matrix, shifts, residuals
procedure TTransformationAlgorithm.ComputeParametersFromPoints(
  const LocalPoints, GlobalPoints: TPointsArray);
var
  LocalCentroid, GlobalCentroid: TPoint;
  LocalReduced, GlobalReduced, Transformed: TPointsArray;
  I, Count: Integer;
  Residual: TPointResidual;
begin
  ClearWarnings;

  // No residuals of the last key
  SetLength(FResiduals, 0);
  FSumVV := 0;

  // Checks
  Count := Length(LocalPoints);
  if Count <> Length(GlobalPoints) then
    raise Exception.Create(
      'Počet bodů v místní a cílové soustavě se neshoduje.');
  if Count < MinimumPoints then
    raise Exception.Create(Format(
      'Pro %s transformaci jsou potřeba alespoň %d identické body.',
      [KindName, MinimumPoints]));

  // Reduced to centroids, keeps digits
  LocalCentroid := Centroid(LocalPoints);
  GlobalCentroid := Centroid(GlobalPoints);
  SetLength(LocalReduced, Count);
  SetLength(GlobalReduced, Count);
  for I := 0 to Count - 1 do
  begin
    LocalReduced[I] := LocalPoints[I];
    LocalReduced[I].Y := LocalPoints[I].Y - LocalCentroid.Y;
    LocalReduced[I].X := LocalPoints[I].X - LocalCentroid.X;
    GlobalReduced[I] := GlobalPoints[I];
    GlobalReduced[I].Y := GlobalPoints[I].Y - GlobalCentroid.Y;
    GlobalReduced[I].X := GlobalPoints[I].X - GlobalCentroid.X;
  end;

  // Matrix from the descendant
  EstimateMatrix(LocalReduced, GlobalReduced);

  // Centroid lands on centroid
  FShiftY := GlobalCentroid.Y - FA11 * LocalCentroid.Y - FA12 * LocalCentroid.X;
  FShiftX := GlobalCentroid.X - FA21 * LocalCentroid.Y - FA22 * LocalCentroid.X;

  // Residuals of the identical points
  Transformed := Calculate(LocalPoints);
  SetLength(FResiduals, Count);
  for I := 0 to Count - 1 do
  begin
    Residual.PointNumber := GlobalPoints[I].PointNumber;
    Residual.Vy  := Transformed[I].Y - GlobalPoints[I].Y;
    Residual.Vx  := Transformed[I].X - GlobalPoints[I].X;
    Residual.Sxy := Sqrt((Sqr(Residual.Vy) + Sqr(Residual.Vx)) / 2);

    FResiduals[I] := Residual;
    FSumVV := FSumVV + Sqr(Residual.Vy) + Sqr(Residual.Vx);
  end;
end;

// Key applied to each point
function TTransformationAlgorithm.Calculate(
  const InputPoints: TPointsArray): TPointsArray;
var
  I: Integer;
begin
  SetLength(Result, Length(InputPoints));
  for I := 0 to High(InputPoints) do
  begin
    Result[I] := InputPoints[I];
    Result[I].Y := FShiftY + FA11 * InputPoints[I].Y + FA12 * InputPoints[I].X;
    Result[I].X := FShiftX + FA21 * InputPoints[I].Y + FA22 * InputPoints[I].X;
  end;
end;

end.
