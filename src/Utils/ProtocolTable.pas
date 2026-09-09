unit ProtocolTable;

// Text tables for calculation protocols. Declare the columns once with
// Table; the header, the line under it and every Row use the same widths.
//
//   Prot := TProtocol.Create(Memo1.Lines);
//   try
//     Prot.Title('Kontrolni omerne');
//     Prot.Table([ColInt('C.', 3), ColText('Cislo bodu', -17)]);
//     Prot.Row([1, '000000 00000 0001']);
//   finally
//     Prot.Free;
//   end;

interface

uses
  System.SysUtils, System.Classes;

const
  ProtWidth = 78;     // width of the title and of the end line
  ColGap    = '  ';   // space between two columns

type
  TProtKind = (pkText, pkInt, pkFloat);

  TProtCol = record
    Caption:  string;
    Width:    Integer;    // minus means left aligned
    Kind:     TProtKind;
    Decimals: Integer;    // only for pkFloat
  end;

// Make a column
function ColText (const ACaption: string; AWidth: Integer): TProtCol;
function ColInt  (const ACaption: string; AWidth: Integer): TProtCol;
function ColFloat(const ACaption: string; AWidth, ADecimals: Integer): TProtCol;

// Format strings, like '%-17s' or '%10.3f'
function TextFormat(AWidth: Integer): string;
function FloatFormat(AWidth, ADecimals: Integer): string;
function ColFormat(const ACol: TProtCol): string;

type
  TProtocol = class
  private
    FLines:  TStrings;            // where the protocol is written
    FCols:   array of TProtCol;   // columns of the current table
    FWidth:  Integer;             // how wide the current table is
    FIndent: string;              // every line starts with this
    function RowFormat(const AValues: array of const): string;
    procedure FullLine(AChar: Char);
  public
    constructor Create(ALines: TStrings);

    procedure Title(const AText: string);
    procedure Text(const AText: string);
    procedure Blank;

    // Sets the columns and writes the header with a line under it
    procedure Table(const ACols: array of TProtCol);

    // One row. Fewer values than columns fills only the first columns.
    procedure Row(const AValues: array of const);
    // The same plus free text behind the last column
    procedure RowTail(const AValues: array of const; const ATail: string);

    procedure TableLine;   // line as wide as the table
    procedure EndLine;     // line across the whole protocol

    // Writes the warnings. Writes nothing when the list is empty.
    procedure Warnings(AList: TStrings; const APrefix: string = ' CHYBA: ');

    property Indent: string read FIndent write FIndent;
  end;

var
  ProtFormat: TFormatSettings;   // decimal comma in every protocol

implementation

function ColText(const ACaption: string; AWidth: Integer): TProtCol;
begin
  Result.Caption  := ACaption;
  Result.Width    := AWidth;
  Result.Kind     := pkText;
  Result.Decimals := 0;
end;

function ColInt(const ACaption: string; AWidth: Integer): TProtCol;
begin
  Result.Caption  := ACaption;
  Result.Width    := AWidth;
  Result.Kind     := pkInt;
  Result.Decimals := 0;
end;

function ColFloat(const ACaption: string; AWidth, ADecimals: Integer): TProtCol;
begin
  Result.Caption  := ACaption;
  Result.Width    := AWidth;
  Result.Kind     := pkFloat;
  Result.Decimals := ADecimals;
end;

function TextFormat(AWidth: Integer): string;
begin
  Result := '%' + IntToStr(AWidth) + 's';
end;

function FloatFormat(AWidth, ADecimals: Integer): string;
begin
  Result := '%' + IntToStr(AWidth) + '.' + IntToStr(ADecimals) + 'f';
end;

function ColFormat(const ACol: TProtCol): string;
begin
  case ACol.Kind of
    pkInt:   Result := '%' + IntToStr(ACol.Width) + 'd';
    pkFloat: Result := FloatFormat(ACol.Width, ACol.Decimals);
  else
    Result := TextFormat(ACol.Width);
  end;
end;

// True when the value is text, not a number. Then a number column can also
// show '-' or '(1,234)'.
function IsText(const AValue: TVarRec): Boolean;
begin
  Result := AValue.VType in [vtChar, vtString, vtPChar, vtAnsiString,
                             vtWideChar, vtPWideChar, vtWideString,
                             vtUnicodeString];
end;

{ TProtocol }

constructor TProtocol.Create(ALines: TStrings);
begin
  inherited Create;
  FLines  := ALines;
  FIndent := ' ';
end;

function TProtocol.RowFormat(const AValues: array of const): string;
var
  i: Integer;
  Col: TProtCol;
begin
  Result := FIndent;
  for i := 0 to High(AValues) do
  begin
    if i > High(FCols) then
      Break;
    if i > 0 then
      Result := Result + ColGap;

    Col := FCols[i];
    if IsText(AValues[i]) then
      Col.Kind := pkText;

    Result := Result + ColFormat(Col);
  end;
end;

procedure TProtocol.FullLine(AChar: Char);
begin
  FLines.Add(FIndent + StringOfChar(AChar, ProtWidth - Length(FIndent)));
end;

procedure TProtocol.Title(const AText: string);
var
  Line: string;
begin
  Line := FIndent + '== ' + AText + ' ';
  if Length(Line) < ProtWidth then
    Line := Line + StringOfChar('=', ProtWidth - Length(Line));
  FLines.Add(Line);
end;

procedure TProtocol.Text(const AText: string);
begin
  FLines.Add(FIndent + AText);
end;

procedure TProtocol.Blank;
begin
  FLines.Add('');
end;

procedure TProtocol.Table(const ACols: array of TProtCol);
var
  i: Integer;
  Line: string;
begin
  SetLength(FCols, Length(ACols));
  FWidth := 0;
  Line   := FIndent;

  // one pass: keep the column, add its caption, count the width
  for i := 0 to High(ACols) do
  begin
    FCols[i] := ACols[i];

    if i > 0 then
    begin
      Line   := Line + ColGap;
      FWidth := FWidth + Length(ColGap);
    end;

    Line   := Line + Format(TextFormat(ACols[i].Width), [ACols[i].Caption]);
    FWidth := FWidth + Abs(ACols[i].Width);
  end;

  FLines.Add(Line);
  TableLine;
end;

procedure TProtocol.TableLine;
begin
  FLines.Add(FIndent + StringOfChar('-', FWidth));
end;

procedure TProtocol.EndLine;
begin
  FullLine('=');
end;

procedure TProtocol.Warnings(AList: TStrings; const APrefix: string);
var
  i: Integer;
begin
  if (AList = nil) or (AList.Count = 0) then
    Exit;

  FullLine('-');
  for i := 0 to AList.Count - 1 do
    FLines.Add(APrefix + AList[i]);
end;

procedure TProtocol.Row(const AValues: array of const);
begin
  FLines.Add(Format(RowFormat(AValues), AValues, ProtFormat));
end;

procedure TProtocol.RowTail(const AValues: array of const; const ATail: string);
begin
  FLines.Add(Format(RowFormat(AValues), AValues, ProtFormat) + ColGap + ATail);
end;

initialization
  ProtFormat := FormatSettings;      // start from the Windows settings
  ProtFormat.DecimalSeparator  := ',';
  ProtFormat.ThousandSeparator := #0;

end.
