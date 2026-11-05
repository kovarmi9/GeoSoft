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
    FWarnings: TStringList;
    FScale: Double;
  protected
    /// <summary>A note, the calculation goes on.</summary>
    procedure AddWarning(const AMsg: string);
    /// <summary>The calculation cannot go on, marked by ErrorMark.</summary>
    procedure AddError(const AMsg: string);
    procedure ClearWarnings;
  public
    constructor Create;
    destructor Destroy; override;

    // Messages of the last run, an error has ErrorMark in Objects
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

var
  /// <summary>Object of an error message in Warnings.</summary>
  ErrorMark: TObject;

implementation

uses
  System.Math;

constructor TAlgorithmBase.Create;
begin
  inherited;
  FWarnings := TStringList.Create;
  FScale := 1.0;
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

procedure TAlgorithmBase.AddError(const AMsg: string);
begin
  FWarnings.AddObject(AMsg, ErrorMark);
end;

procedure TAlgorithmBase.ClearWarnings;
begin
  FWarnings.Clear;
end;

class function TFrameAlgorithm.IsGiven(const ARow: TGeoRow): Boolean;
begin
  Result := not (IsNan(ARow.X) or IsNan(ARow.Y));
end;

initialization
  ErrorMark := TObject.Create;

finalization
  ErrorMark.Free;

end.
