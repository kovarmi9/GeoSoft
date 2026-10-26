unit GeoAlgorithmBase;

interface

uses
  System.SysUtils, System.Classes, Point, GeoDataFrame;

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

    /// <summary>
    /// Turns a measured length into a length of the S-JTSK plane: the
    /// cartographic distortion and the reduction from elevation in one
    /// number. Prepared, the program keeps it at 1.0.
    /// </summary>
    property Scale: Double read FScale write FScale;
  end;

  // Base for an algorithm whose whole input and output is one frame
  TFrameAlgorithm = class abstract(TAlgorithmBase)
  public
    // Goes in filled with measurements, comes out with the results
    procedure Calculate(AFrame: TGeoDataFrame); virtual; abstract;

    // The code this algorithm writes into TGeoRow.Uloha
    class function TaskCode: Integer; virtual; abstract;
  end;

var
  /// <summary>Object of an error message in Warnings.</summary>
  ErrorMark: TObject;

implementation

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

initialization
  ErrorMark := TObject.Create;

finalization
  ErrorMark.Free;

end.
