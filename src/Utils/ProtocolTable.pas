unit ProtocolTable;

// Text protocols of calculations, Title starts one, Finish ends it

interface

uses
  System.SysUtils, System.Classes, System.Math, Point, GeoRow;

const
  // Where the length limits come from
  LimitSource = 'Mezní rozdíl dle KatV, body přílohy 13.5 a 13.6';
  // A quality code without Mxy gives no limit
  NoMxy = 'kód kvality bez Mxy';
  // Behind a point the run has changed in the list
  UpdatedText = '*** bod v seznamu aktualizován ***';

type
  // What a column holds, it gives the width and the alignment
  TColumnKind = (ckNumber, ckPoint, ckLength, ckAngle, ckInteger, ckPair,
    ckText);

  // One column of a table
  TProtocolColumn = record
    Field: TGeoField;       // where FrameRow takes the value
    Free: Boolean;          // the form gives the value
    Kind: TColumnKind;
    Caption: string;
    Width: Integer;         // 0 = by the kind
  end;

  TProtocol = class
  private
    FLines: TStrings;                    // where the protocol is written
    FColumns: array of TProtocolColumn;  // the current table
    FWidth: Integer;                     // how wide the current table is
    FHasErrors: Boolean;                 // Finish wrote a CHYBA
    FCount: Integer;                     // protocols started by Title
    function Cells(const AValues: array of string): string;
    class function MakeColumn(AKind: TColumnKind; AFree: Boolean; const ACaption: string): TProtocolColumn;
    class function ColumnWidth(const AColumn: TProtocolColumn): Integer;
    class function CoordWidth: Integer;
    class function CoordNames: string;
    class function FieldValue(const ARow: TGeoRow; AField: TGeoField): Double;
    class function Pad(const AText: string; AWidth: Integer; ALeft: Boolean): string;
  public
    /// <summary>Clears ALines and writes the title.</summary>
    procedure Title(ALines: TStrings; const AText: string);
    /// <summary>A blank line and the caption of a part.</summary>
    procedure Section(const ACaption: string);
    /// <summary>One line, '' writes a blank line.</summary>
    procedure Text(const AText: string);
    /// <summary>Lines 'caption = value', in pairs.</summary>
    procedure Values(const AValues: array of string);
    /// <summary>Starts a table with its header.</summary>
    procedure Columns(const AColumns: array of TProtocolColumn);
    /// <summary>One row, the form gives every value.</summary>
    procedure Row(const AValues: array of string; const ATail: string = '');
    /// <summary>One row from the frame, free columns from AFree.</summary>
    procedure FrameRow(const ARow: TGeoRow; const AFree: array of string; const ATail: string = '');
    /// <summary>A line as wide as the table.</summary>
    procedure Line;
    /// <summary>Messages of the run and the end line.</summary>
    procedure Finish(AWarnings: TStrings);

    /// <summary>Where the protocol was written, nil before Title.</summary>
    property Lines: TStrings read FLines;
    /// <summary>The last protocol ended with an error.</summary>
    property HasErrors: Boolean read FHasErrors;
    /// <summary>How many protocols Title has started.</summary>
    property Count: Integer read FCount;
  end;

/// <summary>Č., the row of the grid.</summary>
function ColNumber(AWidth: Integer = 0): TProtocolColumn;
/// <summary>A point number the form gives.</summary>
function ColPoint(const ACaption: string = 'Číslo bodu'): TProtocolColumn;
/// <summary>A field of the row, ACaption replaces its name.</summary>
function ColField(AField: TGeoField; const ACaption: string = ''): TProtocolColumn;
/// <summary>Y and X of the row in the current order.</summary>
function ColPair: TProtocolColumn;
/// <summary>A length the form gives.</summary>
function ColLength(const ACaption: string; AWidth: Integer = 0): TProtocolColumn;
/// <summary>An angle the form gives.</summary>
function ColAngle(const ACaption: string): TProtocolColumn;
/// <summary>A short text the form gives.</summary>
function ColText(const ACaption: string; AWidth: Integer = 0): TProtocolColumn;

/// <summary>Both coordinates of a point in the current order.</summary>
function CoordPair(const P: Point.TPoint; ADecimals: Integer = -1): string; overload;
/// <summary>Both coordinates from X and Y in the current order.</summary>
function CoordPair(AX, AY: Double; ADecimals: Integer = -1): string; overload;

/// <summary>Point number as 000000 00000 0000, '' stays ''.</summary>
function PointId(const AText: string): string; overload;
/// <summary>Point number as 000000 00000 0000.</summary>
function PointId(ANumber: Int64): string; overload;

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
  SettingsState, CoordOrderState, ValidationUtils;

const
  ProtIndent = ' ';    // every line starts with this
  ColGap     = '  ';   // space between two columns

var
  ProtFormat: TFormatSettings;   // decimal comma in every protocol

function ColNumber(AWidth: Integer): TProtocolColumn;
begin
  Result := TProtocol.MakeColumn(ckNumber, True, 'Č.');
  Result.Width := AWidth;
end;

function ColPoint(const ACaption: string): TProtocolColumn;
begin
  Result := TProtocol.MakeColumn(ckPoint, True, ACaption);
end;

function ColField(AField: TGeoField; const ACaption: string): TProtocolColumn;
begin
  case AField of
    CB, CBm:
      Result := TProtocol.MakeColumn(ckPoint, False, 'Číslo bodu');
    HZ, Zuhel:
      Result := TProtocol.MakeColumn(ckAngle, False, 'Směr');
    Uloha, TypS, KK:
      Result := TProtocol.MakeColumn(ckInteger, False,
        GeoFieldNames[AField]);
    Poznamka:
      Result := TProtocol.MakeColumn(ckText, False, 'Poznámka');
  else
    Result := TProtocol.MakeColumn(ckLength, False, GeoFieldNames[AField]);
  end;
  Result.Field := AField;
  if ACaption <> '' then
    Result.Caption := ACaption;
end;

function ColPair: TProtocolColumn;
begin
  Result := TProtocol.MakeColumn(ckPair, False, '');
end;

function ColLength(const ACaption: string; AWidth: Integer): TProtocolColumn;
begin
  Result := TProtocol.MakeColumn(ckLength, True, ACaption);
  Result.Width := AWidth;
end;

function ColAngle(const ACaption: string): TProtocolColumn;
begin
  Result := TProtocol.MakeColumn(ckAngle, True, ACaption);
end;

function ColText(const ACaption: string; AWidth: Integer): TProtocolColumn;
begin
  Result := TProtocol.MakeColumn(ckText, True, ACaption);
  Result.Width := AWidth;
end;

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

function PointId(const AText: string): string;
var
  N: Int64;
  D: string;
begin
  if Trim(AText) = '' then
    Exit('');
  // Keep text that is not a number
  if not TryStrToInt64(Trim(AText), N) then
    Exit(Trim(AText));
  // %.15d pads with zeros, %015d would pad with spaces in Delphi
  D := Format('%.15d', [Abs(N)]);
  Result := Copy(D, 1, 6) + ' ' + Copy(D, 7, 5) + ' ' + Copy(D, 12, 4);
  if N < 0 then
    Result := '-' + Result;
end;

function PointId(ANumber: Int64): string;
begin
  Result := PointId(IntToStr(ANumber));
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
  Result := TValidationUtils.MxyBandText(TValidationUtils.MxyBand(ASxy,
    TValidationUtils.MxyOfQuality(AQuality)));
end;

function QualityText(AQuality: Integer): string;
var
  Mxy: Double;
begin
  Result := 'Kód kvality: ' + IntToStr(AQuality);
  Mxy := TValidationUtils.MxyOfQuality(AQuality);
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

class function TProtocol.MakeColumn(AKind: TColumnKind; AFree: Boolean; const ACaption: string): TProtocolColumn;
begin
  Result.Field := CB;
  Result.Free := AFree;
  Result.Kind := AKind;
  Result.Caption := ACaption;
  Result.Width := 0;
end;

// More decimal places, wider column, never narrower than the caption
class function TProtocol.ColumnWidth(const AColumn: TProtocolColumn): Integer;
begin
  Result := AColumn.Width;
  if Result = 0 then
    case AColumn.Kind of
      ckNumber:  Result := 3;
      ckPoint:   Result := 18;
      ckLength:  Result := 8 + GSettings.LengthDecimals;
      ckAngle:   Result := 6 + GSettings.AngleDecimals;
      ckInteger: Result := 3;
      ckPair:    Result := 2 * CoordWidth + Length(ColGap);
      ckText:    Result := 10;
    end;
  Result := Max(Result, Length(AColumn.Caption));
end;

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

// A number field of the row, NaN for the others
class function TProtocol.FieldValue(const ARow: TGeoRow; AField: TGeoField): Double;
begin
  case AField of
    X:      Result := ARow.X;
    Y:      Result := ARow.Y;
    Z:      Result := ARow.Z;
    Xm:     Result := ARow.Xm;
    Ym:     Result := ARow.Ym;
    Zm:     Result := ARow.Zm;
    SH:     Result := ARow.SH;
    SS:     Result := ARow.SS;
    VS:     Result := ARow.VS;
    VC:     Result := ARow.VC;
    HZ:     Result := ARow.HZ;
    Zuhel:  Result := ARow.Zuhel;
    PolarD: Result := ARow.PolarD;
    PolarK: Result := ARow.PolarK;
    Vy:     Result := ARow.Vy;
    Vx:     Result := ARow.Vx;
    Vz:     Result := ARow.Vz;
    Sxy:    Result := ARow.Sxy;
  else
    Result := NaN;
  end;
end;

// Numbers to the right, texts to the left
class function TProtocol.Pad(const AText: string; AWidth: Integer; ALeft: Boolean): string;
begin
  if ALeft then
    Result := AText + StringOfChar(' ', AWidth - Length(AText))
  else
    Result := StringOfChar(' ', AWidth - Length(AText)) + AText;
end;

function TProtocol.Cells(const AValues: array of string): string;
var
  I: Integer;
  Left: Boolean;
begin
  Result := ProtIndent;
  for I := 0 to High(AValues) do
  begin
    if I > High(FColumns) then
      Break;
    if I > 0 then
      Result := Result + ColGap;
    Left := FColumns[I].Kind in [ckPoint, ckPair, ckText];
    Result := Result + Pad(AValues[I], FColumns[I].Width, Left);
  end;
end;

procedure TProtocol.Title(ALines: TStrings; const AText: string);
begin
  FLines := ALines;
  FLines.Clear;
  SetLength(FColumns, 0);
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

procedure TProtocol.Values(const AValues: array of string);
var
  I: Integer;
begin
  I := 0;
  while I < High(AValues) do
  begin
    Text(AValues[I] + ' = ' + AValues[I + 1]);
    Inc(I, 2);
  end;
end;

procedure TProtocol.Columns(const AColumns: array of TProtocolColumn);
var
  I: Integer;
  Captions: array of string;
  Header: string;
begin
  SetLength(FColumns, Length(AColumns));
  SetLength(Captions, Length(AColumns));
  for I := 0 to High(AColumns) do
  begin
    FColumns[I] := AColumns[I];
    // The order of Y and X may change between two runs
    if FColumns[I].Kind = ckPair then
      FColumns[I].Caption := CoordNames;
    FColumns[I].Width := ColumnWidth(FColumns[I]);
    Captions[I] := FColumns[I].Caption;
  end;
  Header := Cells(Captions);
  FWidth := Length(Header) - Length(ProtIndent);
  FLines.Add(Header);
  Line;
end;

procedure TProtocol.Row(const AValues: array of string; const ATail: string);
begin
  if ATail = '' then
    FLines.Add(Cells(AValues))
  else
    FLines.Add(Cells(AValues) + ColGap + ATail);
end;

procedure TProtocol.FrameRow(const ARow: TGeoRow; const AFree: array of string; const ATail: string);
var
  I, NextFree: Integer;
  Values: array of string;
  Column: TProtocolColumn;
begin
  SetLength(Values, Length(FColumns));
  NextFree := 0;
  for I := 0 to High(FColumns) do
  begin
    Column := FColumns[I];
    if Column.Free then
    begin
      // Free columns take the texts of the form in order
      if NextFree <= High(AFree) then
        Values[I] := AFree[NextFree];
      Inc(NextFree);
    end
    else
      case Column.Kind of
        ckPoint:
          Values[I] := PointId(GeoFieldToText(ARow, Column.Field, '',
            ProtFormat));
        ckInteger, ckText:
          Values[I] := GeoFieldToText(ARow, Column.Field, '', ProtFormat);
        ckPair:
          Values[I] := CoordPair(ARow.X, ARow.Y);
        ckAngle:
          Values[I] := Ang(FieldValue(ARow, Column.Field));
      else
        Values[I] := Num(FieldValue(ARow, Column.Field));
      end;
  end;
  Row(Values, ATail);
end;

procedure TProtocol.Line;
begin
  FLines.Add(ProtIndent + StringOfChar('-', FWidth));
end;

procedure TProtocol.Finish(AWarnings: TStrings);
var
  I, Width: Integer;
begin
  // Title and end line as wide as the widest line, messages aside
  Width := Length(FLines[0]) + 3;
  for I := 1 to FLines.Count - 1 do
    Width := Max(Width, Length(FLines[I]));
  FLines[0] := FLines[0] + StringOfChar('=', Width - Length(FLines[0]));

  if (AWarnings <> nil) and (AWarnings.Count > 0) then
  begin
    // No table, no line to draw, a table line is not drawn twice
    if (FWidth > 0) and
      (FLines[FLines.Count - 1] <> ProtIndent + StringOfChar('-', FWidth)) then
      Line;
    // A message with an object is an error, the others are notes
    for I := 0 to AWarnings.Count - 1 do
      if AWarnings.Objects[I] <> nil then
      begin
        FLines.Add(ProtIndent + 'CHYBA: ' + AWarnings[I]);
        FHasErrors := True;
      end
      else
        FLines.Add(ProtIndent + 'UPOZORNĚNÍ: ' + AWarnings[I]);
  end;
  FLines.Add(ProtIndent + StringOfChar('=', Width - Length(ProtIndent)));
end;

initialization
  ProtFormat := FormatSettings;      // start from the Windows settings
  ProtFormat.DecimalSeparator  := ',';
  ProtFormat.ThousandSeparator := #0;

end.
