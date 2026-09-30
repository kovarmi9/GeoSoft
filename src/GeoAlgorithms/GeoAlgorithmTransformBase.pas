unit GeoAlgorithmTransformBase;

// Abstract base for coordinate transformation algorithms.
// A transformation is a two-step process:
//   1. ComputeParametersFromPoints — estimate the key and measure its fit
//   2. Calculate                   — apply the estimated transform to new points

interface

uses Math, Point, GeoAlgorithmBase;

type
  // What one identical point says about the fit.
  // Sxy is the mean coordinate error of that point, not the length of the
  // residual vector: sqrt((Vy^2 + Vx^2) / 2), the way GEUS prints it.
  TPointResidual = record
    PointNumber: Int64;
    Vy, Vx: Double;   // given minus transformed
    Sxy:    Double;
  end;

  TPointResiduals = array of TPointResidual;

  // Where one point falls against the mean coordinate error of its
  // accuracy class. Uxy = 2 * Mxy; mbUnknown means the class has no
  // value yet, so nothing may be claimed about the point.
  TMxyBand = (mbUnknown, mbWithinMxy, mbWithin2Mxy, mbOver2Mxy);

  // Abstract base class for all coordinate transformation algorithms.
  // TAlgorithmBase gives it the shared Warnings list; the point-in/point-out
  // contract of TAlgorithm does not fit here, so it is not used.
  TTransformationAlgorithm = class abstract(TAlgorithmBase)
  private
    FResiduals: TPointResiduals;
    FSumVV: Double;
  protected
    // Estimates transformation parameters using matched local and global control points
    procedure EstimateParameters(const LocalPoints, GlobalPoints: TPointsArray); virtual; abstract;
  public
    /// <summary>
    /// Estimates the parameters and then measures how well they fit, so no
    /// descendant can forget the residuals.
    /// </summary>
    procedure ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray);

    // Applies the computed transformation to InputPoints and returns the result
    function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;

    /// <summary>
    /// Where a point falls. The decree tests single points, not the fit as
    /// a whole, so nothing here judges the key itself.
    /// </summary>
    class function MxyBand(const ASxy, AMxy: Double): TMxyBand;

    /// <summary>What every identical point says about the last fit.</summary>
    property Residuals: TPointResiduals read FResiduals;

    /// <summary>
    /// Sum of Vy^2 + Vx^2 over the identical points. Kept so the mean error
    /// of the key can be added once its formula is settled.
    /// </summary>
    property SumVV: Double read FSumVV;
  end;

implementation

class function TTransformationAlgorithm.MxyBand(
  const ASxy, AMxy: Double): TMxyBand;
begin
  if IsNan(AMxy) then
    Result := mbUnknown
  else if ASxy <= AMxy then
    Result := mbWithinMxy
  else if ASxy <= 2 * AMxy then
    Result := mbWithin2Mxy
  else
    Result := mbOver2Mxy;
end;

procedure TTransformationAlgorithm.ComputeParametersFromPoints(
  const LocalPoints, GlobalPoints: TPointsArray);
var
  Transformed: TPointsArray;
  I: Integer;
  R: TPointResidual;
begin
  // A failed estimate must not leave the residuals of the last one
  SetLength(FResiduals, 0);
  FSumVV := 0;

  EstimateParameters(LocalPoints, GlobalPoints);

  // The identical points go through the key and meet their given place
  Transformed := Calculate(LocalPoints);
  SetLength(FResiduals, Length(LocalPoints));
  for I := 0 to High(LocalPoints) do
  begin
    R.PointNumber := GlobalPoints[I].PointNumber;
    R.Vy  := GlobalPoints[I].Y - Transformed[I].Y;
    R.Vx  := GlobalPoints[I].X - Transformed[I].X;
    R.Sxy := Sqrt((Sqr(R.Vy) + Sqr(R.Vx)) / 2);

    FResiduals[I] := R;
    FSumVV := FSumVV + Sqr(R.Vy) + Sqr(R.Vx);
  end;
end;

end.
