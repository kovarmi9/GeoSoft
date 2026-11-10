unit ProtocolTable;

// Text protocols of calculations, Title starts one, Finish ends it

interface

uses
  System.SysUtils, System.Classes, System.Math, Point, GeoRow, GeoDataFrame,
  PointNumber;

const
  // Where the length limits come from
  LengthLimitSource =
    'Mezní rozdíl: vyhláška č. 357/2013 Sb., příloha, body 13.5 a 13.6';
  // Where the coordinate limits come from
  CoordLimitSource =
    'Mezní odchylky: vyhláška č. 357/2013 Sb., příloha, body 13.7 až 13.9';
  // A quality code without Mxy gives no limit
  NoMxy = 'kód kvality bez Mxy';
  // Behind a point the run has changed in the list
  OverwrittenText = '*** bod v seznamu přepsán ***';
  AveragedText    = '*** bod v seznamu zprůměrován ***';

type
  // What only the form knows about the rows of the frame
  TProtocolRows = record
    Numbers: TArray<string>;   // Č. of each frame row, as the grid shows it
    Notes: TArray<string>;     // note behind a point stored again
  end;

  TProtocol = class
  private
    FLines: TStrings;                    // where the protocol is written
    FWidth: Integer;                     // how wide the current table is
    FHasErrors: Boolean;                 // Finish wrote a CHYBA
    FCount: Integer;                     // protocols started by Title
    class function CoordWidth: Integer;
    class function CoordNames: string;
    class function Pad(const AText: string; AWidth: Integer; ALeft: Boolean): string;
    class function IsEmptyFrame(AFrame: TGeoDataFrame): Boolean;
  public
    /// <summary>Title, or the errors of a failed run. False if nothing follows.</summary>
    function Start(ALines: TStrings; const ATitle: string; AValid: Boolean;
      AFrame: TGeoDataFrame; AErrors, AWarnings: TStrings): Boolean;
    /// <summary>Clears ALines and writes the title.</summary>
    procedure Title(ALines: TStrings; const AText: string);
    /// <summary>A blank line and the caption of a part.</summary>
    procedure Section(const ACaption: string);
    /// <summary>One line, '' writes a blank line.</summary>
    procedure Text(const AText: string);
    /// <summary>The header of a table and a line as wide as it.</summary>
    procedure TableHeader(const AText: string);
    /// <summary>A line as wide as the table.</summary>
    procedure Line;
    /// <summary>Errors, warnings and the end line.</summary>
    procedure Finish(AErrors, AWarnings: TStrings);

    /// <summary>Where the protocol was written, nil before Title.</summary>
    property Lines: TStrings read FLines;
    /// <summary>The last protocol ended with an error.</summary>
    property HasErrors: Boolean read FHasErrors;
    /// <summary>How many protocols Title has started.</summary>
    property Count: Integer read FCount;
  end;

/// <summary>Both coordinates of a point in the current order.</summary>
function CoordPair(const P: Point.TPoint; ADecimals: Integer = -1): string; overload;
/// <summary>Both coordinates from X and Y in the current order.</summary>
function CoordPair(AX, AY: Double; ADecimals: Integer = -1): string; overload;
/// <summary>Captions Y and X above CoordPair, in the current order.</summary>
function CoordCaption: string;

/// <summary>Point number as 000000 00000 0000, '' for 0.</summary>
function PointId(ANumber: Int64): string;

/// <summary>Difference against its limit, KatV 13.5: less than ud.</summary>
function LimitText(ADifference, ALimit: Double): string;
/// <summary>Band of Sxy: do Mxy, do Uxy, přes Uxy.</summary>
function BandText(ASxy: Double; AQuality: Integer): string;
/// <summary>The quality code with its Mxy and Uxy.</summary>
function QualityText(AQuality: Integer): string;
/// <summary>splněno or nesplněno.</summary>
function Fulfilled(ACondition: Boolean): string;

/// <summary>A length, coordinate or area, -1 = the setting.</summary>
function Num(AValue: Double; ADecimals: Integer = -1): string;
/// <summary>An angle in gon, by the setting.</summary>
function Ang(AValue: Double): string;

implementation

uses
  SettingsState, CoordOrderState, Accuracy;

const
  ProtIndent = ' ';    // every line starts with this
  ColGap     = '  ';   // space between two columns

var
  ProtFormat: TFormatSettings;   // decimal comma in every protocol

function CoordPair(const P: Point.TPoint; ADecimals: Integer): string;
var
  First, Second: Double;
begin
  CoordRead(P, First, Second);
  Result := TProtocol.Pad(Num(First, ADecimals), TProtocol.CoordWidth, False) +
    ColGap + TProtocol.Pad(Num(Second, ADecimals), TProtocol.CoordWidth, False);
end;

function CoordPair(AX, AY: Double; ADecimals: Integer): string;
var
  P: Point.TPoint;
begin
  P.X := AX;
  P.Y := AY;
  Result := CoordPair(P, ADecimals);
end;

function CoordCaption: string;
begin
  Result := TProtocol.CoordNames;
end;

function PointId(ANumber: Int64): string;
begin
  Result := TPointNumber.ToDisplay(ANumber);
end;

function LimitText(ADifference, ALimit: Double): string;
begin
  Result := 'Odchylka = ' + Num(ADifference) + '    ';
  if IsNan(ALimit) then
    Exit(Result + 'Mezní rozdíl neurčen, ' + NoMxy);
  Result := Result + 'Mezní rozdíl = ' + Num(ALimit) + '    ';
  if Abs(ADifference) < ALimit then
    Result := Result + 'vyhovuje'
  else
    Result := Result + 'nevyhovuje';
end;

function BandText(ASxy: Double; AQuality: Integer): string;
begin
  Result := TAccuracy.MxyBandText(TAccuracy.MxyBand(ASxy,
    TAccuracy.MxyOfQuality(AQuality)));
end;

function QualityText(AQuality: Integer): string;
var
  Mxy: Double;
begin
  Result := 'Kód kvality: ' + IntToStr(AQuality);
  Mxy := TAccuracy.MxyOfQuality(AQuality);
  if IsNan(Mxy) then
    Result := Result + '    ' + NoMxy
  else
    Result := Result + '    Mxy = ' + Num(Mxy) + '    Uxy = ' + Num(2 * Mxy);
end;

function Fulfilled(ACondition: Boolean): string;
begin
  if ACondition then
    Result := 'splněno'
  else
    Result := 'nesplněno';
end;

function Num(AValue: Double; ADecimals: Integer): string;
var
  Zero: string;
begin
  // NaN means nobody filled the value in, so the column stays blank
  if IsNan(AValue) then
    Exit('');
  if ADecimals < 0 then
    ADecimals := GSettings.LengthDecimals;

  // Half rounds up, the same as the grids
  Result := FloatToStrF(AValue, ffFixed, 18, ADecimals, ProtFormat);

  // A value rounded away to -0,000 looks like an error in the protocol
  Zero := FloatToStrF(0, ffFixed, 18, ADecimals, ProtFormat);
  if Result = '-' + Zero then
    Result := Zero;
end;

function Ang(AValue: Double): string;
begin
  Result := Num(AValue, GSettings.AngleDecimals);
end;

{ TProtocol }

// One coordinate
class function TProtocol.CoordWidth: Integer;
begin
  Result := 12 + GSettings.LengthDecimals;
end;

// Captions Y and X in the current order
class function TProtocol.CoordNames: string;
begin
  if GCoordOrder = coYX then
    Result := Pad('Y', CoordWidth, False) + ColGap +
              Pad('X', CoordWidth, False)
  else
    Result := Pad('X', CoordWidth, False) + ColGap +
              Pad('Y', CoordWidth, False);
end;

// Numbers to the right, texts to the left
class function TProtocol.Pad(const AText: string; AWidth: Integer; ALeft: Boolean): string;
begin
  if ALeft then
    Result := AText + StringOfChar(' ', AWidth - Length(AText))
  else
    Result := StringOfChar(' ', AWidth - Length(AText)) + AText;
end;

// An empty notebook, nothing to report yet
class function TProtocol.IsEmptyFrame(AFrame: TGeoDataFrame): Boolean;
var
  I: Integer;
begin
  for I := 0 to AFrame.Count - 1 do
    if AFrame.Rows[I].CB <> 0 then
      Exit(False);
  Result := True;
end;

// An empty notebook says nothing, a failed run says why
function TProtocol.Start(ALines: TStrings; const ATitle: string; AValid: Boolean;
  AFrame: TGeoDataFrame; AErrors, AWarnings: TStrings): Boolean;
begin
  Result := False;
  if not AValid and IsEmptyFrame(AFrame) then
  begin
    ALines.Clear;
    Exit;
  end;
  Title(ALines, ATitle);
  if not AValid then
  begin
    Finish(AErrors, AWarnings);
    Exit;
  end;
  Result := True;
end;

procedure TProtocol.Title(ALines: TStrings; const AText: string);
begin
  FLines := ALines;
  FLines.Clear;
  FWidth := 0;
  FHasErrors := False;
  Inc(FCount);
  // Finish pads it to the width of the protocol
  FLines.Add(ProtIndent + '== ' + AText + ' ');
  FLines.Add('');
end;

procedure TProtocol.Section(const ACaption: string);
begin
  // Title ends with a blank line already
  if FLines[FLines.Count - 1] <> '' then
    Text('');
  if ACaption <> '' then
    Text(ACaption);
end;

procedure TProtocol.Text(const AText: string);
begin
  if AText = '' then
    FLines.Add('')
  else
    FLines.Add(ProtIndent + AText);
end;

procedure TProtocol.TableHeader(const AText: string);
begin
  Text(AText);
  FWidth := Length(AText);
  Line;
end;

procedure TProtocol.Line;
begin
  FLines.Add(ProtIndent + StringOfChar('-', FWidth));
end;

procedure TProtocol.Finish(AErrors, AWarnings: TStrings);
var
  I, Width: Integer;
begin
  // Title and end line as wide as the widest line, messages aside
  Width := Length(FLines[0]) + 3;
  for I := 1 to FLines.Count - 1 do
    Width := Max(Width, Length(FLines[I]));
  FLines[0] := FLines[0] + StringOfChar('=', Width - Length(FLines[0]));

  if AErrors.Count + AWarnings.Count > 0 then
  begin
    // No table, no line to draw, a table line is not drawn twice
    if (FWidth > 0) and
      (FLines[FLines.Count - 1] <> ProtIndent + StringOfChar('-', FWidth)) then
      Line;
    for I := 0 to AErrors.Count - 1 do
      FLines.Add(ProtIndent + 'CHYBA: ' + AErrors[I]);
    for I := 0 to AWarnings.Count - 1 do
      FLines.Add(ProtIndent + 'UPOZORNĚNÍ: ' + AWarnings[I]);
  end;
  FHasErrors := AErrors.Count > 0;
  FLines.Add(ProtIndent + StringOfChar('=', Width - Length(ProtIndent)));
end;

initialization
  ProtFormat := FormatSettings;      // start from the Windows settings
  ProtFormat.DecimalSeparator  := ',';
  ProtFormat.ThousandSeparator := #0;

end.
