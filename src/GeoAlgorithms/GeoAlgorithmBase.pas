unit GeoAlgorithmBase;

interface

uses
  System.SysUtils, Point, GeoDataFrame;

type
  // Dynamic array of points used as input/output for all algorithms
  TPointsArray = array of TPoint;

  // Abstract base class for all geodetic computation algorithms
  TAlgorithm = class abstract
  private
    FScale: Double;
  public
    // Scale factor applied to computed coordinates (default 1.0)
    property Scale: Double read FScale write FScale;

    constructor Create;
    // Creates the algorithm with an explicit scale factor
    constructor CreateWithScale(AScale: Double);

    // Runs the algorithm on InputPoints and returns the computed output points
    function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
  end;

implementation

constructor TAlgorithm.Create;
begin
  inherited;
  FScale := 1.0;
end;

constructor TAlgorithm.CreateWithScale(AScale: Double);
begin
  Create;
  FScale := AScale;
end;

end.
