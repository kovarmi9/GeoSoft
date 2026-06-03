unit GeoAlgorithmTransformBase;

// Abstract base for coordinate transformation algorithms.
// A transformation is a two-step process:
//   1. ComputeParametersFromPoints — estimate transform parameters from control points
//   2. Calculate                   — apply the estimated transform to new points

interface

uses Point, GeoAlgorithmBase;

type
  // Abstract base class for all coordinate transformation algorithms
  TTransformationAlgorithm = class abstract
  public
    // Estimates transformation parameters using matched local and global control points
    procedure ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray); virtual; abstract;
    // Applies the computed transformation to InputPoints and returns the result
    function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
  end;

implementation

end.
