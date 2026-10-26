unit ProtocolTable;

// Text tables for calculation protocols. Title starts one, Finish ends it.
// Table declares the captions and the widths once, the header, the line
// under it and every Row then use them. Values are strings, use Num for a
// number.
//
//   Prot.Title(Memo1.Lines, 'Vypocet plochy parcely');
//   Prot.Table(['C.', 'Cislo bodu'], [ColWNo, ColWPoint]);
//   Prot.Row([IntToStr(i), '000000 00000 0001']);
//   Prot.Finish(FAlg.Warnings);

interface

uses
  System.SysUtils, System.Classes, System.Math;

const
  // Width of the title and of the end line at 2 places. Keep it at least as
  // wide as the widest table - today the check measurements, 106 + indent.
  ProtWidth  = 107;
  ProtIndent = ' ';    // every line starts with this
  ColGap     = '  ';   // space between two columns

  // Standard column widths. A minus width means left aligned.
  ColWNo    = 3;      // row number
  ColWPoint = -18;    // point id from FormatPointId, with a minus sign
  ColWFlag  = -10;    // a short word like 'dany'

  // Where the length limits come from
  LimitSource = 'Mezní rozdíl dle KatV, body přílohy 13.5 a 13.6';
  // A quality code without Mxy gives no limit
  NoMxy = 'kód kvality bez Mxy';

type
  TProtocol = class
  private
    FLines: TStrings;          // where the protocol is written
    FCols:  array of Integer;  // widths of the current table
    FWidth: Integer;           // how wide the current table is
    function Cells(const AValues: array of string): string;
  public
    procedure Title(ALines: TStrings; const AText: string);   // clears ALines
    procedure Text(const AText: string);       // '' writes a blank line
    procedure Table(const ACaptions: array of string;
                    const AWidths: array of Integer);
    // ATail is free text written behind the last column
    procedure Row(const AValues: array of string; const ATail: string = '');
    procedure Line;                            // as wide as the table
    procedure Finish(AWarnings: TStrings);     // messages and the end line

    // A point number the way the protocol writes it: 000000 00000 0000
    function FormatPointId(const S: string): string;
    function PointId(ANum: Int64): string;

    // Where the protocol was written, nil before the first Title
    property Lines: TStrings read FLines;
  end;

function Pad(const AText: string; AWidth: Integer): string;

/// <summary>Column of lengths, AWidth wide at 2 places.</summary>
function LengthWidth(AWidth: Integer): Integer;
/// <summary>Column of angles, AWidth wide at 4 places.</summary>
function AngleWidth(AWidth: Integer): Integer;
/// <summary>One coordinate.</summary>
function ColWCoord: Integer;
/// <summary>Both coordinates.</summary>
function ColWPair: Integer;
/// <summary>A length or a height in metres.</summary>
function ColWDist: Integer;

/// <summary>Difference against its limit, KatV 13.5: less than ud.</summary>
function LimitText(ADifference, ALimit: Double): string;

/// <summary>A length, coordinate or area, -1 = the setting.</summary>
function Num(AValue: Double; ADecimals: Integer = -1): string;
/// <summary>An angle in gon, by the setting.</summary>
function Ang(AValue: Double): string;

var
  ProtFormat: TFormatSettings;   // decimal comma in every protocol

implementation

uses
  SettingsState;

// More places, wider column, the sign stays
function LengthWidth(AWidth: Integer): Integer;
begin
  Result := Sign(AWidth) * (Abs(AWidth) + GSettings.LengthDecimals - 2);
end;

function AngleWidth(AWidth: Integer): Integer;
begin
  Result := Sign(AWidth) * (Abs(AWidth) + GSettings.AngleDecimals - 4);
end;

function ColWCoord: Integer;
begin
  Result := LengthWidth(14);
end;

function ColWPair: Integer;
begin
  Result := -(2 * ColWCoord + Length(ColGap));
end;

function ColWDist: Integer;
begin
  Result := LengthWidth(10);
end;

// Title and end line, the widest table has four length columns
function ProtocolWidth: Integer;
begin
  Result := ProtWidth + 4 * (GSettings.LengthDecimals - 2);
end;

function LimitText(ADifference, ALimit: Double): string;
begin
  Result := 'Odchylka = ' + Num(ADifference) + '    ';
  if IsNan(ALimit) then
    Exit(Result + 'Mezní rozdíl neurčen, ' + NoMxy);
  Result := Result + 'Mezní rozdíl = ' + Num(ALimit) + '    ';
  if ADifference < ALimit then
    Result := Result + 'vyhovuje'
  else
    Result := Result + 'nevyhovuje';
end;

// Puts the text into a column AWidth wide, minus width means left aligned
function Pad(const AText: string; AWidth: Integer): string;
begin
  Result := Format('%' + IntToStr(AWidth) + 's', [AText]);
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

function TProtocol.FormatPointId(const S: string): string;
var
  N: Int64;
  D: string;
begin
  N := StrToInt64Def(Trim(S), 0);
  // %.15d pads with zeros, %015d would pad with spaces in Delphi
  D := Format('%.15d', [Abs(N)]);
  Result := Copy(D, 1, 6) + ' ' + Copy(D, 7, 5) + ' ' + Copy(D, 12, 4);
  if N < 0 then
    Result := '-' + Result;
end;

function TProtocol.PointId(ANum: Int64): string;
begin
  Result := FormatPointId(IntToStr(ANum));
end;

function TProtocol.Cells(const AValues: array of string): string;
var
  i: Integer;
begin
  Result := ProtIndent;
  for i := 0 to High(AValues) do
  begin
    if i > High(FCols) then
      Break;
    if i > 0 then
      Result := Result + ColGap;
    Result := Result + Pad(AValues[i], FCols[i]);
  end;
end;

procedure TProtocol.Title(ALines: TStrings; const AText: string);
var
  S: string;
begin
  FLines := ALines;
  FLines.Clear;
  SetLength(FCols, 0);
  FWidth := 0;
  S := ProtIndent + '== ' + AText + ' ';
  while Length(S) < ProtocolWidth do
    S := S + '=';
  FLines.Add(S);
  FLines.Add('');
end;

procedure TProtocol.Text(const AText: string);
begin
  if AText = '' then
    FLines.Add('')
  else
    FLines.Add(ProtIndent + AText);
end;

procedure TProtocol.Table(const ACaptions: array of string;
                          const AWidths: array of Integer);
var
  i: Integer;
  S: string;
begin
  SetLength(FCols, Length(AWidths));
  for i := 0 to High(FCols) do
    FCols[i] := AWidths[i];
  S := Cells(ACaptions);
  FWidth := Length(S) - Length(ProtIndent);
  FLines.Add(S);
  Line;
end;

procedure TProtocol.Row(const AValues: array of string; const ATail: string);
begin
  if ATail = '' then
    FLines.Add(Cells(AValues))
  else
    FLines.Add(Cells(AValues) + ColGap + ATail);
end;

procedure TProtocol.Line;
begin
  FLines.Add(ProtIndent + StringOfChar('-', FWidth));
end;

procedure TProtocol.Finish(AWarnings: TStrings);
var
  i: Integer;
begin
  if (AWarnings <> nil) and (AWarnings.Count > 0) then
  begin
    Line;
    // A message with an object is an error, the others are notes
    for i := 0 to AWarnings.Count - 1 do
      if AWarnings.Objects[i] <> nil then
        FLines.Add(' CHYBA: ' + AWarnings[i])
      else
        FLines.Add(' UPOZORNĚNÍ: ' + AWarnings[i]);
  end;
  FLines.Add(ProtIndent +
    StringOfChar('=', ProtocolWidth - Length(ProtIndent)));
end;

initialization
  ProtFormat := FormatSettings;      // start from the Windows settings
  ProtFormat.DecimalSeparator  := ',';
  ProtFormat.ThousandSeparator := #0;

end.
