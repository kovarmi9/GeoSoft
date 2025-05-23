unit GeoAlgorithmTransformBase;

interface

uses Point, GeoAlgorithmBase;

type
  TTransformationAlgorithm = class abstract
  public
    procedure ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray); virtual; abstract;
    function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
  end;

implementation

end.

