unit ProtocolTable;

// Fixed-width text tables for calculation protocols. Columns are declared
// once; the header, the rule and every row are built from that declaration,
// so the widths cannot drift apart.
//
// This unit knows nothing about coordinates. The coordinate pair is offered
// as a ready-made column by CoordOrderState.

interface

uses
  System.SysUtils, System.Classes;

const
  ProtWidth = 78;          // total width of a title banner

type
  TProtKind = (pkText, pkInt, pkFloat);

  TProtCol = record
    Caption: string;
    Width: Integer;        // negative = left aligned, as in '%-17s'
    Kind: TProtKind;
    Decimals: Integer;     // pkFloat only
  end;

function ColText (const ACaption: string; AWidth: Integer): TProtCol;
function ColInt  (const ACaption: string; AWidth: Integer): TProtCol;
function ColFloat(const ACaption: string; AWidth, ADecimals: Integer): TProtCol;

// '%3d', '%-17s', '%10.2f' - one place builds a column format
function ColFormat(const ACol: TProtCol): string;

type
  TProtocol = record
  private
    FLines: TStrings;
    FCols: TArray<TProtCol>;
    FIndent: string;
    function BuildFormat(const AValues: array of const): string;
  public
    procedure Init(ALines: TStrings);

    procedure Title(const AText: string);
    procedure Text(const AText: string);
    procedure Blank;

    /// <summary>Declares the columns and writes the header and the rule.</summary>
    procedure Table(const ACols: array of TProtCol; const AIndent: string = ' ');
    procedure Sep(AChar: Char = '-');

    /// <summary>Full width rule, used to close the protocol.</summary>
    procedure Rule(AChar: Char = '=');

    /// <summary>Writes the warnings after a rule. Nothing when the list is empty.</summary>
    procedure Warnings(AList: TStrings; const APrefix: string = ' CHYBA: ');

    /// <summary>One row. Fewer values than columns fills only the first ones.</summary>
    procedure Row(const AValues: array of const);
    procedure RowTail(const AValues: array of const; const ATail: string);
  end;

var
  ProtFormat: TFormatSettings;   // decimal comma, no thousands separator

implementation

{ Column constructors }

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

function ColFormat(const ACol: TProtCol): string;
begin
  case ACol.Kind of
    pkInt:   Result := Format('%%%dd', [ACol.Width]);
    pkFloat: Result := Format('%%%d.%df', [ACol.Width, ACol.Decimals]);
  else
    Result := Format('%%%ds', [ACol.Width]);
  end;
end;

{ TProtocol }

procedure TProtocol.Init(ALines: TStrings);
begin
  FLines := ALines;
  SetLength(FCols, 0);
  FIndent := ' ';
end;

procedure TProtocol.Title(const AText: string);
var
  S: string;
begin
  S := ' == ' + AText + ' ';
  if Length(S) < ProtWidth then
    S := S + StringOfChar('=', ProtWidth - Length(S));
  FLines.Add(S);
end;

procedure TProtocol.Text(const AText: string);
begin
  FLines.Add(AText);
end;

procedure TProtocol.Blank;
begin
  FLines.Add('');
end;

procedure TProtocol.Table(const ACols: array of TProtCol; const AIndent: string);
var
  I: Integer;
  S: string;
begin
  SetLength(FCols, Length(ACols));
  for I := 0 to High(ACols) do
    FCols[I] := ACols[I];
  FIndent := AIndent;

  S := FIndent;
  for I := 0 to High(FCols) do
  begin
    if I > 0 then
      S := S + '  ';
    // captions are always text, whatever the column holds
    S := S + Format(ColFormat(ColText('', FCols[I].Width)), [FCols[I].Caption]);
  end;
  FLines.Add(S);

  Sep;
end;

procedure TProtocol.Sep(AChar: Char);
var
  I, W: Integer;
begin
  W := Length(FIndent);
  for I := 0 to High(FCols) do
  begin
    if I > 0 then
      Inc(W, 2);
    Inc(W, Abs(FCols[I].Width));
  end;
  FLines.Add(StringOfChar(AChar, W));
end;

procedure TProtocol.Rule(AChar: Char);
begin
  FLines.Add(' ' + StringOfChar(AChar, ProtWidth - 1));
end;

procedure TProtocol.Warnings(AList: TStrings; const APrefix: string);
var
  I: Integer;
begin
  if (AList = nil) or (AList.Count = 0) then
    Exit;
  Rule('-');
  for I := 0 to AList.Count - 1 do
    FLines.Add(APrefix + AList[I]);
end;

function TProtocol.BuildFormat(const AValues: array of const): string;
var
  I: Integer;
  C: TProtCol;
begin
  Result := FIndent;
  for I := 0 to High(AValues) do
  begin
    if I > High(FCols) then
      Break;
    if I > 0 then
      Result := Result + '  ';

    C := FCols[I];
    // a string in a numeric column is printed as text, same width
    if AValues[I].VType in [vtChar, vtString, vtPChar, vtAnsiString,
                            vtWideChar, vtPWideChar, vtWideString,
                            vtUnicodeString] then
      C.Kind := pkText;

    Result := Result + ColFormat(C);
  end;
end;

procedure TProtocol.Row(const AValues: array of const);
begin
  FLines.Add(Format(BuildFormat(AValues), AValues, ProtFormat));
end;

procedure TProtocol.RowTail(const AValues: array of const; const ATail: string);
begin
  FLines.Add(Format(BuildFormat(AValues), AValues, ProtFormat) + '  ' + ATail);
end;

initialization
  ProtFormat := TFormatSettings.Create;
  ProtFormat.DecimalSeparator  := ',';
  ProtFormat.ThousandSeparator := #0;

end.
