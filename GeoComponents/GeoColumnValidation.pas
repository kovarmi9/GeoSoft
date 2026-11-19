unit GeoColumnValidation;

// Column validation and formatting rules for TGeoGrid descendants.

interface

uses
  System.Classes,
  System.SysUtils,
  System.Math;

type
  /// <summary>Supported data types for a single column.</summary>
  TColumnDataType = (
    cdtNone,        // any text, no type restriction
    cdtInteger,     // whole number
    cdtFloat,       // floating point number
    cdtExpression   // arithmetic expression, evaluated at commit
  );

  /// <summary>Action taken when cell commit validation fails.</summary>
  TCommitInvalidAction = (
    ciaBlock,        // beep + stay on cell, don't clear (default)
    ciaBeepAndClear  // beep + clear the cell
  );

  /// <summary>Text for an empty cell, '' gives the column default.</summary>
  TGetDefaultTextEvent = procedure(var AText: string) of object;

  /// <summary>Validation and formatting rules for one column.</summary>
  TColumnFilter = class(TCollectionItem)
  private
    FDataType: TColumnDataType;
    FMinLength: Integer;
    FMaxLength: Integer;
    FHasMinValue: Boolean;
    FMinValue: Double;
    FHasMaxValue: Boolean;
    FMaxValue: Double;
    FDecimalPlaces: Integer;
    FAllowEmpty: Boolean;
    FWrapAt: Double;
    FReadOnly: Boolean;
    FOnInvalidCommit: TCommitInvalidAction;
    FOnGetDefaultText: TGetDefaultTextEvent;

    // Setters that change the table look
    procedure SetDecimalPlaces(const Value: Integer);
    procedure SetReadOnly(const Value: Boolean);

    function GetColumn: Integer;

  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;

    /// <summary>Default text for an empty cell, set in code.</summary>
    property OnGetDefaultText: TGetDefaultTextEvent read FOnGetDefaultText write FOnGetDefaultText;

  published
    /// <summary>Column index, read-only, given by the position.</summary>
    property Column: Integer read GetColumn stored False;

    /// <summary>Data type accepted by this column.</summary>
    property DataType: TColumnDataType read FDataType write FDataType default cdtNone;

    /// <summary>Minimum required length (0 = no minimum).</summary>
    property MinLength: Integer read FMinLength write FMinLength default 0;

    /// <summary>Maximum allowed length (0 = unlimited).</summary>
    property MaxLength: Integer read FMaxLength write FMaxLength default 0;

    /// <summary>Enable lower bound check on numeric value.</summary>
    property HasMinValue: Boolean read FHasMinValue write FHasMinValue default False;

    /// <summary>Lowest value, used when HasMinValue is True.</summary>
    property MinValue: Double read FMinValue write FMinValue;

    /// <summary>Enable upper bound check on numeric value.</summary>
    property HasMaxValue: Boolean read FHasMaxValue write FHasMaxValue default False;

    /// <summary>Highest value, used when HasMaxValue is True.</summary>
    property MaxValue: Double read FMaxValue write FMaxValue;

    /// <summary>Decimals shown, -1 as is, the cell keeps all.</summary>
    property DecimalPlaces: Integer read FDecimalPlaces write SetDecimalPlaces default -1;

    /// <summary>True keeps an empty cell, False makes it 0.</summary>
    property AllowEmpty: Boolean read FAllowEmpty write FAllowEmpty default False;

    /// <summary>Period of the value, 400 for gon, 0 for none.</summary>
    property WrapAt: Double read FWrapAt write FWrapAt;

    /// <summary>ciaBlock keeps the value, ciaBeepAndClear clears it.</summary>
    property OnInvalidCommit: TCommitInvalidAction read FOnInvalidCommit write FOnInvalidCommit default ciaBlock;

    /// <summary>Filled by the program, the cursor skips it.</summary>
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
  end;

  /// <summary>Filters of a grid, one per column.</summary>
  TColumnFilters = class(TOwnedCollection)
  private
    FOnChanged: TNotifyEvent;

    function GetItem(Index: Integer): TColumnFilter;

  protected
    procedure Update(Item: TCollectionItem); override;

  public
    constructor Create(AOwner: TPersistent);

    /// <summary>Append a new filter item at the end.</summary>
    function Add: TColumnFilter;

    /// <summary>Grows or shrinks the collection to the column count.</summary>
    procedure EnsureCount(AColCount: Integer);

    /// <summary>The filter of column Index.</summary>
    property Items[Index: Integer]: TColumnFilter read GetItem; default;

    /// <summary>Fires after any item inside the collection changes.</summary>
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

/// <summary>Drops a typed character the column does not allow.</summary>
procedure FilterKeyPress(AFilter: TColumnFilter; const AText: string; var Key: Char);

/// <summary>True if the text passes length, type and range.</summary>
function ValidateText(AFilter: TColumnFilter; const AText: string): Boolean;

/// <summary>Validates the text, an expression becomes its value.</summary>
function TryCommitText(AFilter: TColumnFilter; var AText: string): Boolean;

/// <summary>A number with ADecimals places, half rounds up.</summary>
function FormatDouble(AValue: Double; ADecimals: Integer): string;

/// <summary>Evaluates + - * / ^ ( ), True on success.</summary>
function TryEvaluateExpression(const AExpression: string; out AValue: Double): Boolean;

implementation

{ TColumnFilter }

constructor TColumnFilter.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FDecimalPlaces := -1;   // the rest starts as 0, False
end;

procedure TColumnFilter.Assign(Source: TPersistent);
var
  SourceFilter: TColumnFilter;
begin
  if Source is TColumnFilter then
  begin
    SourceFilter := TColumnFilter(Source);
    FDataType        := SourceFilter.FDataType;
    FMinLength       := SourceFilter.FMinLength;
    FMaxLength       := SourceFilter.FMaxLength;
    FHasMinValue     := SourceFilter.FHasMinValue;
    FMinValue        := SourceFilter.FMinValue;
    FHasMaxValue     := SourceFilter.FHasMaxValue;
    FMaxValue        := SourceFilter.FMaxValue;
    FDecimalPlaces   := SourceFilter.FDecimalPlaces;
    FAllowEmpty      := SourceFilter.FAllowEmpty;
    FWrapAt          := SourceFilter.FWrapAt;
    FReadOnly        := SourceFilter.FReadOnly;
    FOnInvalidCommit := SourceFilter.FOnInvalidCommit;
    // FOnGetDefaultText is not copied, it is set in code, not in the designer
    Changed(False);   // this item only, grid redraws
  end
  else
    inherited Assign(Source);
end;

function TColumnFilter.GetColumn: Integer;
begin
  Result := Index;
end;

procedure TColumnFilter.SetDecimalPlaces(const Value: Integer);
begin
  if FDecimalPlaces = Value then Exit;
  FDecimalPlaces := Value;
  Changed(False);   // this item only, grid redraws
end;

procedure TColumnFilter.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly = Value then Exit;
  FReadOnly := Value;
  Changed(False);   // this item only, grid redraws
end;

{ TColumnFilters }

constructor TColumnFilters.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TColumnFilter);
end;

function TColumnFilters.Add: TColumnFilter;
begin
  Result := TColumnFilter(inherited Add);
end;

// Shrinking deletes the trailing filters for good. Anything set in the
// designer is lost when ColCount goes down and does not come back.
procedure TColumnFilters.EnsureCount(AColCount: Integer);
begin
  while Count < AColCount do
    Add;
  while Count > AColCount do
    Delete(Count - 1);
end;

function TColumnFilters.GetItem(Index: Integer): TColumnFilter;
begin
  Result := TColumnFilter(inherited GetItem(Index));
end;

procedure TColumnFilters.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

{ --- Expression parser --- }
//
//  Grammar:
//    Expression := Term   (('+' | '-') Term)*            left-associative
//    Term       := Unary  (('*' | '/') Unary)*           left-associative
//    Unary      := ('+' | '-') Unary | Factor
//    Factor     := Primary ('^' Unary)?                  right-associative
//    Primary    := '(' Expression ')' | Number
//    Number     := Digit+ (DecimalSep Digit+)?

type
  EExpressionParserError = class(Exception);

  /// <summary>Computes a typed expression by the grammar.</summary>
  // The text is read from left to right, FPosition is the cursor. Each
  // Parse method reads its part of the text and leaves the cursor behind
  // it. A method calls the one below first, so * goes before +. A mistake
  // raises EExpressionParserError and Parse turns it into False.
  TExpressionParser = class
  private
    FText: string;
    FPosition: Integer;           // cursor, 1 = first character
    function AtEnd: Boolean;
    function Peek: Char;
    function Consume: Char;
    procedure Expect(AChar: Char);
    procedure SkipSpaces;
    function ParseExpression: Double;
    function ParseTerm: Double;
    function ParseUnary: Double;
    function ParseFactor: Double;
    function ParsePrimary: Double;
    function ParseNumber: Double;
  public
    constructor Create(const AText: string);
    function Parse(out AValue: Double): Boolean;
  end;

constructor TExpressionParser.Create(const AText: string);
begin
  FText := AText;
  FPosition := 1;
end;

function TExpressionParser.AtEnd: Boolean;
begin
  Result := FPosition > Length(FText);
end;

// #0 at the end
function TExpressionParser.Peek: Char;
begin
  if AtEnd then
    Result := #0
  else
    Result := FText[FPosition];
end;

function TExpressionParser.Consume: Char;
begin
  Result := Peek;
  if not AtEnd then
    Inc(FPosition);
end;

procedure TExpressionParser.Expect(AChar: Char);
begin
  SkipSpaces;
  if Peek <> AChar then
    raise EExpressionParserError.CreateFmt(
      'Expected "%s" at position %d', [AChar, FPosition]);
  Consume;
end;

procedure TExpressionParser.SkipSpaces;
begin
  while Peek = ' ' do
    Inc(FPosition);
end;

// a + b - c
function TExpressionParser.ParseExpression: Double;
var
  Symbol: Char;
  Right: Double;
begin
  Result := ParseTerm;
  SkipSpaces;
  while CharInSet(Peek, ['+', '-']) do
  begin
    Symbol := Consume;
    Right := ParseTerm;
    if Symbol = '+' then
      Result := Result + Right
    else
      Result := Result - Right;
    SkipSpaces;
  end;
end;

// a * b / c
function TExpressionParser.ParseTerm: Double;
var
  Symbol: Char;
  Right: Double;
begin
  Result := ParseUnary;
  SkipSpaces;
  while CharInSet(Peek, ['*', '/']) do
  begin
    Symbol := Consume;
    Right := ParseUnary;
    if Symbol = '*' then
      Result := Result * Right
    else
    begin
      if Right = 0 then
        raise EExpressionParserError.Create('Division by zero');
      Result := Result / Right;
    end;
    SkipSpaces;
  end;
end;

// -2^2 = -4
function TExpressionParser.ParseUnary: Double;
begin
  SkipSpaces;
  if Peek = '-' then
  begin
    Consume;
    Result := -ParseUnary;
  end
  else if Peek = '+' then
  begin
    Consume;
    Result := ParseUnary;
  end
  else
    Result := ParseFactor;
end;

// a ^ b
function TExpressionParser.ParseFactor: Double;
var
  Exponent: Double;
begin
  Result := ParsePrimary;
  SkipSpaces;
  if Peek = '^' then
  begin
    Consume;
    Exponent := ParseUnary;   // right-associative, 2^-1 too
    Result := Power(Result, Exponent);
  end;
end;

// (a) or a number
function TExpressionParser.ParsePrimary: Double;
begin
  SkipSpaces;
  if Peek = '(' then
  begin
    Consume;
    Result := ParseExpression;
    Expect(')');
  end
  else
    Result := ParseNumber;
end;

// Dot and comma mean decimals
function TExpressionParser.ParseNumber: Double;
var
  Start: Integer;
  NumberText: string;
  Separator: Char;
begin
  SkipSpaces;
  Start := FPosition;
  while CharInSet(Peek, ['0'..'9']) do
    Consume;

  Separator := FormatSettings.DecimalSeparator;
  if (Peek = '.') or (Peek = ',') or (Peek = Separator) then
  begin
    Consume;
    while CharInSet(Peek, ['0'..'9']) do
      Consume;
  end;

  if Start = FPosition then
    raise EExpressionParserError.CreateFmt(
      'Expected number at position %d', [FPosition]);

  NumberText := Copy(FText, Start, FPosition - Start);
  NumberText := StringReplace(NumberText, '.', Separator, [rfReplaceAll]);
  NumberText := StringReplace(NumberText, ',', Separator, [rfReplaceAll]);
  if not TryStrToFloat(NumberText, Result, FormatSettings) then
    raise EExpressionParserError.CreateFmt('Invalid number "%s"', [NumberText]);
end;

function TExpressionParser.Parse(out AValue: Double): Boolean;
begin
  AValue := 0;
  try
    AValue := ParseExpression;
    // NaN or Inf is not a valid value
    if IsNan(AValue) or IsInfinite(AValue) then
      Exit(False);
    SkipSpaces;
    // Any trailing non-whitespace means the expression did not fully parse
    Result := AtEnd;
  except
    on EExpressionParserError do
      Result := False;
  end;
end;

function TryEvaluateExpression(const AExpression: string; out AValue: Double): Boolean;
var
  Parser: TExpressionParser;
begin
  AValue := 0;
  if Trim(AExpression) = '' then
    Exit(False);

  Parser := TExpressionParser.Create(AExpression);
  try
    Result := Parser.Parse(AValue);
  finally
    Parser.Free;
  end;
end;

{ --- Shared helpers --- }

function FormatDouble(AValue: Double; ADecimals: Integer): string;
begin
  if ADecimals < 0 then
    Result := FloatToStr(AValue)
  else if ADecimals = 0 then
    Result := FormatFloat('0', AValue)
  else
    Result := FormatFloat('0.' + StringOfChar('0', ADecimals), AValue);
end;

function CheckLengthBounds(AFilter: TColumnFilter; const AText: string): Boolean;
begin
  Result := True;
  if (AFilter.MinLength > 0) and (Length(AText) < AFilter.MinLength) then
    Exit(False);
  if (AFilter.MaxLength > 0) and (Length(AText) > AFilter.MaxLength) then
    Exit(False);
end;

function CheckValueBounds(AFilter: TColumnFilter; AValue: Double): Boolean;
begin
  Result := True;
  if AFilter.HasMinValue and (AValue < AFilter.MinValue) then
    Exit(False);
  if AFilter.HasMaxValue and (AValue > AFilter.MaxValue) then
    Exit(False);
end;

// Takes away whole periods, so a repeating value lands in 0..WrapAt.
procedure Wrap(AFilter: TColumnFilter; var AValue: Double);
begin
  if AFilter.WrapAt <= 0 then
    Exit;
  AValue := AValue - AFilter.WrapAt * Int(AValue / AFilter.WrapAt);
  if AValue < 0 then
    AValue := AValue + AFilter.WrapAt;
end;

function TryGetNumericValue(AFilter: TColumnFilter; const AText: string; out AValue: Double): Boolean;
var
  Text: string;
begin
  AValue := 0;
  Result := False;
  Text := Trim(AText);
  if Text = '' then
    Exit;

  case AFilter.DataType of
    cdtExpression:
      Result := TryEvaluateExpression(Text, AValue);
  else
    Result := TryStrToFloat(Text, AValue, FormatSettings);
  end;
end;

{ --- Text validation --- }

function ValidateIntegerText(const AText: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if (AText = '') or (AText = '-') then
    Exit;
  for I := 1 to Length(AText) do
    // A minus sign only in front
    if not CharInSet(AText[I], ['0'..'9']) and
      not ((AText[I] = '-') and (I = 1)) then
      Exit;
  Result := True;
end;

function ValidateFloatText(const AText: string): Boolean;
var
  I: Integer;
  Character: Char;
  HasDecimal, HasDigit: Boolean;
  Separator: Char;
begin
  Result := False;
  if AText = '' then
    Exit;

  Separator := FormatSettings.DecimalSeparator;
  HasDecimal := False;
  HasDigit := False;

  for I := 1 to Length(AText) do
  begin
    Character := AText[I];
    if (Character = '-') and (I = 1) then
      Continue
    else if Character = Separator then
    begin
      if HasDecimal then Exit;
      HasDecimal := True;
    end
    else if CharInSet(Character, ['0'..'9']) then
      HasDigit := True
    else
      Exit;
  end;

  Result := HasDigit;
end;

{ --- Key filtering --- }

procedure FilterIntegerKey(const AText: string; var Key: Char);
begin
  if CharInSet(Key, ['0'..'9']) then
    Exit;

  if (Key = '-') and (AText = '') then
    Exit;

  Key := #0;
end;

procedure FilterFloatKey(const AText: string; var Key: Char);
var
  Separator: Char;
begin
  Separator := FormatSettings.DecimalSeparator;

  if (Key = '.') or (Key = ',') then
    Key := Separator;

  if CharInSet(Key, ['0'..'9']) then
    Exit;

  if (Key = Separator) and (Pos(Separator, AText) = 0) then
    Exit;

  if (Key = '-') and (AText = '') then
    Exit;

  Key := #0;
end;

procedure FilterExpressionKey(const AText: string; var Key: Char);
var
  Separator: Char;
begin
  Separator := FormatSettings.DecimalSeparator;

  if (Key = '.') or (Key = ',') then
    Key := Separator;

  if CharInSet(Key, ['0'..'9']) then
    Exit;

  if Key = Separator then
    Exit;

  if CharInSet(Key, ['+', '-', '*', '/', '^', '(', ')', ' ']) then
    Exit;

  Key := #0;
end;

{ --- Public API --- }

procedure FilterKeyPress(AFilter: TColumnFilter; const AText: string; var Key: Char);
begin
  if AFilter = nil then
    Exit;

  // Control characters (backspace, Ctrl+C/V/X/A, arrows, ...) pass through
  if Key < #32 then
    Exit;

  // Length cap - once reached, block any printable input
  if (AFilter.MaxLength > 0) and (Length(AText) >= AFilter.MaxLength) then
  begin
    Key := #0;
    Exit;
  end;

  case AFilter.DataType of
    cdtNone:
      ;

    cdtInteger:
      FilterIntegerKey(AText, Key);

    cdtFloat:
      FilterFloatKey(AText, Key);

    cdtExpression:
      FilterExpressionKey(AText, Key);
  end;
end;

function ValidateText(AFilter: TColumnFilter; const AText: string): Boolean;
var
  Value: Double;
begin
  Result := True;
  if AFilter = nil then
    Exit;

  if not CheckLengthBounds(AFilter, AText) then
    Exit(False);

  case AFilter.DataType of
    cdtNone:
      ;

    cdtInteger:
      if not ValidateIntegerText(AText) then Exit(False);

    cdtFloat:
      if not ValidateFloatText(AText) then Exit(False);

    cdtExpression:
      if not TryEvaluateExpression(AText, Value) then Exit(False);
  end;

  // Value bound check only makes sense for numeric types
  if (AFilter.DataType <> cdtNone) and
    (AFilter.HasMinValue or AFilter.HasMaxValue) then
  begin
    if TryGetNumericValue(AFilter, AText, Value) then
      if not CheckValueBounds(AFilter, Value) then
        Exit(False);
  end;
end;

// Plain digits, the check refuses 5E-05
function PlainFloatText(const AValue: Double): string;
begin
  Result := FloatToStr(AValue);
  if Pos('E', Result) > 0 then
    Result := FormatFloat('0.##################', AValue);
end;

function TryCommitText(AFilter: TColumnFilter; var AText: string): Boolean;
var
  Value: Double;
begin
  if (AFilter <> nil) and (Trim(AText) = '') then
  begin
    // An empty cell is either a value of its own, or it means zero
    if AFilter.AllowEmpty then
    begin
      AText := '';          // drop stray spaces
      Exit(True);
    end;
    if AFilter.DataType in [cdtInteger, cdtFloat, cdtExpression] then
      AText := '0';
  end;

  Result := ValidateText(AFilter, AText);
  if not Result then
    Exit;

  if AFilter = nil then
    Exit;

  if (AFilter.DataType in [cdtFloat, cdtExpression]) and
    TryGetNumericValue(AFilter, AText, Value) then
  begin
    Wrap(AFilter, Value);
    if not CheckValueBounds(AFilter, Value) then
      Exit(False);
    AText := PlainFloatText(Value); // full value, the grid rounds the drawing
  end;
end;

end.
