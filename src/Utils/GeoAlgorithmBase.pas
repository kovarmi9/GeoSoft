unit GeoAlgorithmBase;

interface

uses
  System.SysUtils, Point;

type
  TPointsArray = array of TPoint;

  TAlgorithm = class abstract
  private
    class var FScale: Double;
  public
    class property Scale: Double read FScale write FScale;
    class function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
  end;

implementation

initialization
  TAlgorithm.Scale := 1.0;

end.

