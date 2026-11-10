unit GeoAlgorithmBase;

interface

uses
  System.SysUtils, System.Classes, Point, GeoRow, GeoDataFrame;

const
  GON_TO_RAD = Pi / 200;
  RAD_TO_GON = 200 / Pi;

  MIN_ANGLE = 30;       // [gon] a sharper intersection is weak
  MAX_ANGLE = 170;

type
  // Dynamic array of points, e.g. the input of a transformation
  TPointsArray = array of TPoint;

  // Shared infrastructure for every algorithm, whatever its interface is
  TAlgorithmBase = class
  private
    FErrors: TStringList;
    FWarnings: TStringList;
    FScale: Double;
  protected
    /// <summary>A note, the calculation goes on.</summary>
    procedure AddWarning(const AMsg: string);
    /// <summary>A mistake, that part has no result.</summary>
    procedure AddError(const AMsg: string);
    /// <summary>Empties Errors and Warnings.</summary>
    procedure ClearMessages;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Errors of the last run, parts without a result.</summary>
    property Errors: TStringList read FErrors;
    /// <summary>Notes of the last run, the results stand.</summary>
    property Warnings: TStringList read FWarnings;

    /// <summary>Length scale to the S-JTSK plane, 1 by default.</summary>
    property Scale: Double read FScale write FScale;
  end;

  // Base for an algorithm whose whole input and output is one frame
  TFrameAlgorithm = class abstract(TAlgorithmBase)
  public
    // Goes in filled with measurements, comes out with the results
    procedure Calculate(AFrame: TGeoDataFrame); virtual; abstract;

    /// <summary>A given point has coordinates.</summary>
    class function IsGiven(const ARow: TGeoRow): Boolean;
  end;

implementation

uses
  System.Math;

constructor TAlgorithmBase.Create;
begin
  inherited;
  FErrors := TStringList.Create;
  FWarnings := TStringList.Create;
  FScale := 1.0;
end;

destructor TAlgorithmBase.Destroy;
begin
  FErrors.Free;
  FWarnings.Free;
  inherited;
end;

procedure TAlgorithmBase.AddWarning(const AMsg: string);
begin
  FWarnings.Add(AMsg);
end;

procedure TAlgorithmBase.AddError(const AMsg: string);
begin
  FErrors.Add(AMsg);
end;

procedure TAlgorithmBase.ClearMessages;
begin
  FErrors.Clear;
  FWarnings.Clear;
end;

class function TFrameAlgorithm.IsGiven(const ARow: TGeoRow): Boolean;
begin
  Result := not (IsNan(ARow.X) or IsNan(ARow.Y));
end;

end.
