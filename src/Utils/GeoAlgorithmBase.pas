unit GeoAlgorithmBase;

// Class-based (static) variant of the algorithm base — uses class vars and class methods.
// This is a legacy alternative to the instance-based version in src/GeoAlgorithms/.

interface

uses
  System.SysUtils, Point;

type
  // Dynamic array of points used as input/output for all algorithms
  TPointsArray = array of TPoint;

  // Abstract base class; Scale is a shared class variable
  TAlgorithm = class abstract
  private
    class var FScale: Double;
  public
    // Scale factor applied to computed coordinates (default 1.0, set in initialization)
    class property Scale: Double read FScale write FScale;
    // Runs the algorithm on InputPoints and returns computed output points
    class function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
  end;

implementation

initialization
  TAlgorithm.Scale := 1.0;

end.
