unit GeoAlgorithmBase;

interface

uses
  System.SysUtils, System.Classes, Point;

type
  // Dynamic array of points used as input/output for all algorithms
  TPointsArray = array of TPoint;

  // Shared infrastructure for every algorithm, whatever its interface is
  TAlgorithmBase = class
  private
    FWarnings: TStringList;
  protected
    procedure AddWarning(const AMsg: string);
    procedure ClearWarnings;
  public
    constructor Create;
    destructor Destroy; override;

    // Warnings produced by the last run (cleared at the start of each run)
    property Warnings: TStringList read FWarnings;
  end;

  // Base for algorithms that take points in and return points out
  TAlgorithm = class abstract(TAlgorithmBase)
  private
    FScale: Double;
  public
    constructor Create;
    constructor CreateWithScale(AScale: Double);

    // Scale factor applied to computed coordinates (default 1.0)
    property Scale: Double read FScale write FScale;

    // Runs the algorithm on InputPoints and returns the computed output points
    function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
  end;

implementation

constructor TAlgorithmBase.Create;
begin
  inherited;
  FWarnings := TStringList.Create;
end;

destructor TAlgorithmBase.Destroy;
begin
  FWarnings.Free;
  inherited;
end;

procedure TAlgorithmBase.AddWarning(const AMsg: string);
begin
  FWarnings.Add(AMsg);
end;

procedure TAlgorithmBase.ClearWarnings;
begin
  FWarnings.Clear;
end;

constructor TAlgorithm.Create;
begin
  inherited Create;
  FScale := 1.0;
end;

constructor TAlgorithm.CreateWithScale(AScale: Double);
begin
  Create;
  FScale := AScale;
end;

end.
