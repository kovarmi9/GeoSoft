unit GeoColumnValidation;

// Column validation and formatting rules for TGeoGrid descendants.
//
// Phases:
//   1. Types (TColumnDataType, TColumnFilter, TColumnFilters)           — done
//   2. Keypress filtering (Integer, Float)                              — done
//   3. Full-text validation (length, type, value bounds)                — done
//   4. Commit (validate + format, replace expression with result)       — done
//   5. Expression parser (recursive descent, no COM)                    — done
//   6. Expression integration into keypress + validate + commit         — done

interface

uses
  System.Classes,
  System.SysUtils,
  System.Math;

type
  /// <summary>
  /// Supported data types for a single column.
  /// </summary>
  TColumnDataType = (
    cdtNone,        // any text, no type restriction
    cdtInteger,     // whole number
    cdtFloat,       // floating point number
    cdtExpression   // arithmetic expression, evaluated at commit
  );

  /// <summary>
  /// Validation and formatting rules for one column.
  ///
  /// Length limits:
  ///   MinLength = 0 means no minimum length (empty allowed)
  ///   MaxLength = 0 means no maximum length (unlimited)
  ///
  /// Value limits:
  ///   Only applied when HasMinValue / HasMaxValue is True.
  ///   Used for numeric types (Integer, Float, Expression).
  ///
  /// Formatting:
  ///   DecimalPlaces = -1 means no formatting (raw string)
  ///   DecimalPlaces = 0..N forces N decimals on commit (Float/Expression)
  /// </summary>
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

    procedure SetDataType(const Value: TColumnDataType);
    procedure SetMinLength(const Value: Integer);
    procedure SetMaxLength(const Value: Integer);
    procedure SetHasMinValue(const Value: Boolean);
    procedure SetMinValue(const Value: Double);
    procedure SetHasMaxValue(const Value: Boolean);
    procedure SetMaxValue(const Value: Double);
    procedure SetDecimalPlaces(const Value: Integer);

    function GetColumn: Integer;

  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;

  published
    /// <summary>Column index (read-only, derived from collection position).</summary>
    property Column: Integer read GetColumn stored False;

    /// <summary>Data type accepted by this column.</summary>
    property DataType: TColumnDataType
      read FDataType write SetDataType default cdtNone;

    /// <summary>Minimum required length (0 = no minimum).</summary>
    property MinLength: Integer
      read FMinLength write SetMinLength default 0;

    /// <summary>Maximum allowed length (0 = unlimited).</summary>
    property MaxLength: Integer
      read FMaxLength write SetMaxLength default 0;

    /// <summary>Enable lower bound check on numeric value.</summary>
    property HasMinValue: Boolean
      read FHasMinValue write SetHasMinValue default False;

    /// <summary>Lower bound for numeric value (used when HasMinValue = True).</summary>
    property MinValue: Double
      read FMinValue write SetMinValue;

    /// <summary>Enable upper bound check on numeric value.</summary>
    property HasMaxValue: Boolean
      read FHasMaxValue write SetHasMaxValue default False;

    /// <summary>Upper bound for numeric value (used when HasMaxValue = True).</summary>
    property MaxValue: Double
      read FMaxValue write SetMaxValue;

    /// <summary>
    /// Decimal places applied on commit for Float / Expression.
    ///   -1 = no formatting
    ///    0..N = force exactly N decimals
    /// </summary>
    property DecimalPlaces: Integer
      read FDecimalPlaces write SetDecimalPlaces default -1;
  end;

  /// <summary>
  /// Owned collection of TColumnFilter items, one per grid column.
  /// </summary>
  TColumnFilters = class(TOwnedCollection)
  private
    FOnChanged: TNotifyEvent;

    function GetItem(Index: Integer): TColumnFilter;
    procedure SetItem(Index: Integer; const Value: TColumnFilter);

  protected
    procedure Update(Item: TCollectionItem); override;

  public
    constructor Create(AOwner: TPersistent);

    /// <summary>Append a new filter item at the end.</summary>
    function Add: TColumnFilter;

    /// <summary>Grow or shrink the collection to match exact column count.</summary>
    procedure EnsureCount(AColCount: Integer);

    property Items[Index: Integer]: TColumnFilter
      read GetItem write SetItem; default;

    /// <summary>Fires after any item inside the collection changes.</summary>
    property OnChanged: TNotifyEvent
      read FOnChanged write FOnChanged;
  end;

/// <summary>
/// Keypress-level input filtering. Call from KeyPress event handler.
/// Modifies Key to #0 to swallow disallowed input.
///
/// Rules:
///   - Control characters (Key &lt; #32) always pass through
///   - MaxLength &gt; 0 blocks further input once reached
///   - Type-specific rules:
///       cdtNone       - no restriction
///       cdtInteger    - digits only
///       cdtFloat      - digits + one decimal separator (normalized to locale)
///       cdtExpression - digits + decimal + operators + parentheses + space
/// </summary>
procedure FilterKeyPress(AFilter: TColumnFilter;
                         const AText: string; var Key: Char);

/// <summary>
/// Full-text validation after editing is complete.
/// Checks length bounds, type conformance and value bounds.
/// Returns True when text passes all rules (or AFilter is nil).
/// </summary>
function ValidateText(AFilter: TColumnFilter;
                      const AText: string): Boolean;

/// <summary>
/// Commit-time validation and formatting:
///   - Runs ValidateText
///   - For cdtExpression: evaluates and replaces AText with the result
///   - For cdtFloat / cdtExpression with DecimalPlaces &gt;= 0: formats to N decimals
/// Returns True when text was accepted (and possibly rewritten).
/// </summary>
function TryCommitText(AFilter: TColumnFilter;
                       var AText: string): Boolean;

/// <summary>Nil-safe lookup of filter for a given column index.</summary>
function ResolveFilter(AFilters: TColumnFilters;
                       AColumn: Integer): TColumnFilter;

/// <summary>
/// Evaluate arithmetic expression: + - * / ^ ( ) unary- decimals.
/// Returns True on success.
/// </summary>
function TryEvaluateExpression(const Expr: string;
                               out Value: Double): Boolean;

implementation

{ TColumnFilter }

constructor TColumnFilter.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FDataType      := cdtNone;
  FMinLength     := 0;
  FMaxLength     := 0;
  FHasMinValue   := False;
  FMinValue      := 0.0;
  FHasMaxValue   := False;
  FMaxValue      := 0.0;
  FDecimalPlaces := -1;
end;

procedure TColumnFilter.Assign(Source: TPersistent);
var
  Src: TColumnFilter;
begin
  if Source is TColumnFilter then
  begin
    Src := TColumnFilter(Source);
    FDataType      := Src.FDataType;
    FMinLength     := Src.FMinLength;
    FMaxLength     := Src.FMaxLength;
    FHasMinValue   := Src.FHasMinValue;
    FMinValue      := Src.FMinValue;
    FHasMaxValue   := Src.FHasMaxValue;
    FMaxValue      := Src.FMaxValue;
    FDecimalPlaces := Src.FDecimalPlaces;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TColumnFilter.GetColumn: Integer;
begin
  Result := Index;
end;

procedure TColumnFilter.SetDataType(const Value: TColumnDataType);
begin
  if FDataType = Value then Exit;
  FDataType := Value;
  Changed(False);
end;

procedure TColumnFilter.SetMinLength(const Value: Integer);
begin
  if FMinLength = Value then Exit;
  FMinLength := Value;
  Changed(False);
end;

procedure TColumnFilter.SetMaxLength(const Value: Integer);
begin
  if FMaxLength = Value then Exit;
  FMaxLength := Value;
  Changed(False);
end;

procedure TColumnFilter.SetHasMinValue(const Value: Boolean);
begin
  if FHasMinValue = Value then Exit;
  FHasMinValue := Value;
  Changed(False);
end;

procedure TColumnFilter.SetMinValue(const Value: Double);
begin
  if FMinValue = Value then Exit;
  FMinValue := Value;
  Changed(False);
end;

procedure TColumnFilter.SetHasMaxValue(const Value: Boolean);
begin
  if FHasMaxValue = Value then Exit;
  FHasMaxValue := Value;
  Changed(False);
end;

procedure TColumnFilter.SetMaxValue(const Value: Double);
begin
  if FMaxValue = Value then Exit;
  FMaxValue := Value;
  Changed(False);
end;

procedure TColumnFilter.SetDecimalPlaces(const Value: Integer);
begin
  if FDecimalPlaces = Value then Exit;
  FDecimalPlaces := Value;
  Changed(False);
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

procedure TColumnFilters.SetItem(Index: Integer; const Value: TColumnFilter);
begin
  inherited SetItem(Index, Value);
end;

procedure TColumnFilters.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

{ --- Phase 5: Expression parser (recursive descent) --- }
//
//  Grammar:
//    Expression := Term   (('+' | '-') Term)*            left-associative
//    Term       := Factor (('*' | '/') Factor)*          left-associative
//    Factor     := Unary  ('^' Factor)?                  right-associative
//    Unary      := ('+' | '-') Unary | Primary
//    Primary    := '(' Expression ')' | Number
//    Number     := Digit+ (DecimalSep Digit+)?

type
  EExpressionParserError = class(Exception);

  TExpressionParser = class
  private
    FText: string;
    FPos: Integer;
    function AtEnd: Boolean;
    function Peek: Char;
    function Consume: Char;
    procedure Expect(Ch: Char);
    procedure SkipSpaces;
    function ParseExpression: Double;
    function ParseTerm: Double;
    function ParseFactor: Double;
    function ParseUnary: Double;
    function ParsePrimary: Double;
    function ParseNumber: Double;
  public
    constructor Create(const AText: string);
    function Parse(out Value: Double): Boolean;
  end;

constructor TExpressionParser.Create(const AText: string);
begin
  FText := AText;
  FPos := 1;
end;

function TExpressionParser.AtEnd: Boolean;
begin
  Result := FPos > Length(FText);
end;

function TExpressionParser.Peek: Char;
begin
  if AtEnd then
    Result := #0
  else
    Result := FText[FPos];
end;

function TExpressionParser.Consume: Char;
begin
  Result := Peek;
  if not AtEnd then
    Inc(FPos);
end;

procedure TExpressionParser.Expect(Ch: Char);
begin
  SkipSpaces;
  if Peek <> Ch then
    raise EExpressionParserError.CreateFmt(
      'Expected "%s" at position %d', [Ch, FPos]);
  Consume;
end;

procedure TExpressionParser.SkipSpaces;
begin
  while (not AtEnd) and (Peek = ' ') do
    Inc(FPos);
end;

function TExpressionParser.ParseExpression: Double;
var
  Op: Char;
  Rhs: Double;
begin
  Result := ParseTerm;
  SkipSpaces;
  while (not AtEnd) and CharInSet(Peek, ['+', '-']) do
  begin
    Op := Consume;
    Rhs := ParseTerm;
    if Op = '+' then
      Result := Result + Rhs
    else
      Result := Result - Rhs;
    SkipSpaces;
  end;
end;

function TExpressionParser.ParseTerm: Double;
var
  Op: Char;
  Rhs: Double;
begin
  Result := ParseFactor;
  SkipSpaces;
  while (not AtEnd) and CharInSet(Peek, ['*', '/']) do
  begin
    Op := Consume;
    Rhs := ParseFactor;
    if Op = '*' then
      Result := Result * Rhs
    else
    begin
      if Rhs = 0 then
        raise EExpressionParserError.Create('Division by zero');
      Result := Result / Rhs;
    end;
    SkipSpaces;
  end;
end;

function TExpressionParser.ParseFactor: Double;
var
  Rhs: Double;
begin
  Result := ParseUnary;
  SkipSpaces;
  if (not AtEnd) and (Peek = '^') then
  begin
    Consume;
    Rhs := ParseFactor;  // right-associative
    Result := Power(Result, Rhs);
  end;
end;

function TExpressionParser.ParseUnary: Double;
begin
  SkipSpaces;
  if Peek = '+' then
  begin
    Consume;
    Result := ParseUnary;
  end
  else if Peek = '-' then
  begin
    Consume;
    Result := -ParseUnary;
  end
  else
    Result := ParsePrimary;
end;

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

function TExpressionParser.ParseNumber: Double;
var
  StartPos: Integer;
  NumStr: string;
  Sep: Char;
begin
  SkipSpaces;
  StartPos := FPos;

  while (not AtEnd) and CharInSet(Peek, ['0'..'9']) do
    Consume;

  Sep := FormatSettings.DecimalSeparator;
  if (not AtEnd) and ((Peek = '.') or (Peek = ',') or (Peek = Sep)) then
  begin
    Consume;
    while (not AtEnd) and CharInSet(Peek, ['0'..'9']) do
      Consume;
  end;

  if StartPos = FPos then
    raise EExpressionParserError.CreateFmt(
      'Expected number at position %d', [FPos]);

  NumStr := Copy(FText, StartPos, FPos - StartPos);
  NumStr := StringReplace(NumStr, '.', Sep, [rfReplaceAll]);
  NumStr := StringReplace(NumStr, ',', Sep, [rfReplaceAll]);

  if not TryStrToFloat(NumStr, Result, FormatSettings) then
    raise EExpressionParserError.CreateFmt(
      'Invalid number "%s"', [NumStr]);
end;

function TExpressionParser.Parse(out Value: Double): Boolean;
begin
  Value := 0;
  Result := False;
  try
    Value := ParseExpression;
    SkipSpaces;
    // Any trailing non-whitespace means the expression did not fully parse
    Result := AtEnd;
  except
    on EExpressionParserError do
      Result := False;
    on EConvertError do
      Result := False;
  end;
end;

function TryEvaluateExpression(const Expr: string;
                               out Value: Double): Boolean;
var
  Parser: TExpressionParser;
begin
  Value := 0;
  if Trim(Expr) = '' then
    Exit(False);

  Parser := TExpressionParser.Create(Expr);
  try
    Result := Parser.Parse(Value);
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

function CheckLengthBounds(AFilter: TColumnFilter;
                           const AText: string): Boolean;
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

function TryGetNumericValue(AFilter: TColumnFilter;
                            const AText: string; out Value: Double): Boolean;
var
  Text: string;
begin
  Value := 0;
  Result := False;
  Text := Trim(AText);
  if Text = '' then
    Exit;

  case AFilter.DataType of
    cdtExpression:
      Result := TryEvaluateExpression(Text, Value);
  else
    Result := TryStrToFloat(Text, Value, FormatSettings);
  end;
end;

{ --- Phase 3: Text validation (private helpers) --- }

function ValidateIntegerText(const AText: string): Boolean;
var
  Ch: Char;
begin
  Result := False;
  if AText = '' then
    Exit;
  for Ch in AText do
    if not CharInSet(Ch, ['0'..'9']) then
      Exit;
  Result := True;
end;

function ValidateFloatText(const AText: string): Boolean;
var
  Ch: Char;
  HasDecimal, HasDigit: Boolean;
  Sep: Char;
begin
  Result := False;
  if AText = '' then
    Exit;

  Sep := FormatSettings.DecimalSeparator;
  HasDecimal := False;
  HasDigit := False;

  for Ch in AText do
  begin
    if Ch = Sep then
    begin
      if HasDecimal then Exit;
      HasDecimal := True;
    end
    else if CharInSet(Ch, ['0'..'9']) then
      HasDigit := True
    else
      Exit;
  end;

  Result := HasDigit;
end;

function ValidateExpressionText(const AText: string): Boolean;
var
  V: Double;
begin
  Result := TryEvaluateExpression(AText, V);
end;

{ --- Phase 2 + 6: Keypress filtering (private helpers) --- }

procedure FilterIntegerKey(const AText: string; var Key: Char);
begin
  if not CharInSet(Key, ['0'..'9']) then
    Key := #0;
end;

procedure FilterFloatKey(const AText: string; var Key: Char);
var
  Sep: Char;
begin
  Sep := FormatSettings.DecimalSeparator;

  if (Key = '.') or (Key = ',') then
    Key := Sep;

  if CharInSet(Key, ['0'..'9']) then
    Exit;

  if (Key = Sep) and (Pos(Sep, AText) = 0) then
    Exit;

  Key := #0;
end;

procedure FilterExpressionKey(const AText: string; var Key: Char);
var
  Sep: Char;
begin
  Sep := FormatSettings.DecimalSeparator;

  if (Key = '.') or (Key = ',') then
    Key := Sep;

  if CharInSet(Key, ['0'..'9']) then
    Exit;

  if Key = Sep then
    Exit;

  if CharInSet(Key, ['+', '-', '*', '/', '^', '(', ')', ' ']) then
    Exit;

  Key := #0;
end;

{ --- Public API --- }

procedure FilterKeyPress(AFilter: TColumnFilter;
                         const AText: string; var Key: Char);
begin
  if AFilter = nil then
    Exit;

  // Control characters (backspace, Ctrl+C/V/X/A, arrows, ...) pass through
  if Key < #32 then
    Exit;

  // Length cap — once reached, block any printable input
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

function ValidateText(AFilter: TColumnFilter;
                      const AText: string): Boolean;
var
  V: Double;
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
      if not ValidateExpressionText(AText) then Exit(False);
  end;

  // Value bound check only makes sense for numeric types
  if (AFilter.DataType <> cdtNone) and
     (AFilter.HasMinValue or AFilter.HasMaxValue) then
  begin
    if TryGetNumericValue(AFilter, AText, V) then
      if not CheckValueBounds(AFilter, V) then
        Exit(False);
  end;
end;

function TryCommitText(AFilter: TColumnFilter;
                       var AText: string): Boolean;
var
  V: Double;
begin
  Result := ValidateText(AFilter, AText);
  if not Result then
    Exit;

  if AFilter = nil then
    Exit;

  case AFilter.DataType of
    cdtExpression:
      if TryEvaluateExpression(AText, V) then
      begin
        if not CheckValueBounds(AFilter, V) then
          Exit(False);
        AText := FormatDouble(V, AFilter.DecimalPlaces);
      end;

    cdtFloat:
      if (AFilter.DecimalPlaces >= 0) and
         TryStrToFloat(AText, V, FormatSettings) then
        AText := FormatDouble(V, AFilter.DecimalPlaces);
  end;
end;

function ResolveFilter(AFilters: TColumnFilters;
                       AColumn: Integer): TColumnFilter;
begin
  Result := nil;
  if AFilters = nil then
    Exit;
  if (AColumn >= 0) and (AColumn < AFilters.Count) then
    Result := AFilters[AColumn];
end;

end.
