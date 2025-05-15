unit GeoAlgorithmBase;

interface

uses
  System.SysUtils, Point;

type
  TPointsArray = array of TPoint;

  TAlgorithm = class abstract
  private
    FScale: Double;
  public
    property Scale: Double read FScale write FScale;

    constructor Create; virtual;
    function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
  end;

implementation

constructor TAlgorithm.Create;
begin
  inherited;
  FScale := 1.0;
end;

end.

