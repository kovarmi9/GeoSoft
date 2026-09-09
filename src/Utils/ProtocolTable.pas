unit ProtocolTable;

// Text tables for calculation protocols. Title starts one, Finish ends it.
// Table declares the captions and the widths once; the header, the line
// under it and every Row then use them. Values are strings, use Num for a
// number.
//
//   Prot.Title(Memo1.Lines, 'Vypocet plochy parcely');
//   Prot.Table(['C.', 'Cislo bodu'], [ColWNo, ColWPoint]);
//   Prot.Row([IntToStr(i), '000000 00000 0001']);
//   Prot.Finish(FAlg.Warnings);

interface

uses
  System.SysUtils, System.Classes;

const
  // Width of the title and of the end line. Keep it at least as wide as the
  // widest table in the program - today the check measurements, 104 + indent.
  ProtWidth  = 105;
  ProtIndent = ' ';    // every line starts with this
  ColGap     = '  ';   // space between two columns

  // Standard column widths. A minus width means left aligned.
  ColWNo    = 3;      // row number
  ColWPoint = -17;    // point id from FormatPointId
  ColWCoord = 14;     // one coordinate
  ColWPair  = -(2 * ColWCoord + Length(ColGap));   // both coordinates
  ColWDist  = 10;     // a length or a height in metres
  ColWFlag  = -10;    // a short word like 'dany'

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
    procedure Finish(AWarnings: TStrings);     // warnings and the end line

    // Where the protocol was written; nil before the first Title
    property Lines: TStrings read FLines;
  end;

function Pad(const AText: string; AWidth: Integer): string;
function Num(AValue: Double; ADecimals: Integer = 2): string;

var
  ProtFormat: TFormatSettings;   // decimal comma in every protocol

implementation

// Puts the text into a column AWidth wide, minus width means left aligned
function Pad(const AText: string; AWidth: Integer): string;
begin
  Result := Format('%' + IntToStr(AWidth) + 's', [AText]);
end;

function Num(AValue: Double; ADecimals: Integer): string;
var
  Zero: string;
begin
  Result := FloatToStrF(AValue, ffFixed, 18, ADecimals, ProtFormat);

  // A value rounded away to -0,000 looks like an error in the protocol
  Zero := FloatToStrF(0, ffFixed, 18, ADecimals, ProtFormat);
  if Result = '-' + Zero then
    Result := Zero;
end;

{ TProtocol }

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
  while Length(S) < ProtWidth do
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
    for i := 0 to AWarnings.Count - 1 do
      FLines.Add(' CHYBA: ' + AWarnings[i]);
  end;
  FLines.Add(ProtIndent + StringOfChar('=', ProtWidth - Length(ProtIndent)));
end;

initialization
  ProtFormat := FormatSettings;      // start from the Windows settings
  ProtFormat.DecimalSeparator  := ',';
  ProtFormat.ThousandSeparator := #0;

end.
