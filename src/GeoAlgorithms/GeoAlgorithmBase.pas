// GeoAlgorithmBase.pas

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

    constructor Create;
    constructor CreateWithScale(AScale: Double);

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

