unit GeoAlgorithmBase;

interface

uses
  System.SysUtils, System.Classes, Point;

type
  // Dynamic array of points used as input/output for all algorithms
  TPointsArray = array of TPoint;

  // Abstract base class for all geodetic computation algorithms
  TAlgorithm = class abstract
  private
    FScale: Double;
    FWarnings: TStringList;
  protected
    procedure AddWarning(const AMsg: string);
    procedure ClearWarnings;
  public
    constructor Create;
    constructor CreateWithScale(AScale: Double);
    destructor Destroy; override;

    // Scale factor applied to computed coordinates (default 1.0)
    property Scale: Double read FScale write FScale;

    // Warnings produced by the last Calculate call (cleared at the start of each call)
    property Warnings: TStringList read FWarnings;

    // Runs the algorithm on InputPoints and returns the computed output points
    function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
  end;

implementation

constructor TAlgorithm.Create;
begin
  inherited;
  FScale := 1.0;
  FWarnings := TStringList.Create;
end;

constructor TAlgorithm.CreateWithScale(AScale: Double);
begin
  Create;
  FScale := AScale;
end;

destructor TAlgorithm.Destroy;
begin
  FWarnings.Free;
  inherited;
end;

procedure TAlgorithm.AddWarning(const AMsg: string);
begin
  FWarnings.Add(AMsg);
end;

procedure TAlgorithm.ClearWarnings;
begin
  FWarnings.Clear;
end;

end.
