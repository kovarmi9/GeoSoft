unit GeoAlgorithmBase;

// Class-based (static) variant of the algorithm base — uses class vars and class methods.
// This is a legacy alternative to the instance-based version in src/GeoAlgorithms/.

interface

uses
  System.SysUtils, System.Classes, Point;

type
  // Dynamic array of points used as input/output for all algorithms
  TPointsArray = array of TPoint;

  // Abstract base class; Scale and Warnings are shared class variables
  TAlgorithm = class abstract
  private
    class var FScale: Double;
    class var FWarnings: TStringList;
  protected
    class procedure AddWarning(const AMsg: string);
    class procedure ClearWarnings;
  public
    // Scale factor applied to computed coordinates (default 1.0, set in initialization)
    class property Scale: Double read FScale write FScale;

    // Warnings produced by the last Calculate call (cleared at the start of each call)
    class property Warnings: TStringList read FWarnings;

    // Runs the algorithm on InputPoints and returns computed output points
    function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
  end;

implementation

class procedure TAlgorithm.AddWarning(const AMsg: string);
begin
  FWarnings.Add(AMsg);
end;

class procedure TAlgorithm.ClearWarnings;
begin
  FWarnings.Clear;
end;

initialization
  TAlgorithm.FScale := 1.0;
  TAlgorithm.FWarnings := TStringList.Create;

finalization
  TAlgorithm.FWarnings.Free;

end.
