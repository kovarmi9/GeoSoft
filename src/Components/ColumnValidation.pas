unit ColumnValidation;

interface

uses
  System.Classes,
  System.SysUtils,
  ComObj;

type
  // Datové typy povolené pro vstup + výrazy
  TColumnDataType = (
    fNone,
    fInteger,
    fFloat,
    fExpression
  );

  // Pravidla pro jeden sloupec
  TColumnFilter = record
    DataType: TColumnDataType;
    MinLength: Integer;
    MaxLength: Integer;
    MinValue: string;
    MaxValue: string;
    class function None: TColumnFilter; static;
    class function Integer: TColumnFilter; static;
    class function Float: TColumnFilter; static;
    class function Expression: TColumnFilter; static;
  end;

  // Jeden item odpovídá jednomu sloupci
  TColumnFilterItem = class(TCollectionItem)
  private
    FDataType: TColumnDataType;
    FMinLength: Integer;
    FMaxLength: Integer;
    FMinValue: string;
    FMaxValue: string;
    procedure SetDataType(const Value: TColumnDataType);
    procedure SetMinLength(const Value: Integer);
    procedure SetMaxLength(const Value: Integer);
    procedure SetMinValue(const Value: string);
    procedure SetMaxValue(const Value: string);
    function GetColumn: Integer;
  public
    constructor Create(Collection: TCollection); override;
    function ToFilter: TColumnFilter;
  published
    property Column: Integer read GetColumn stored False;
    property DataType: TColumnDataType read FDataType write SetDataType default fNone;
    property MinLength: Integer read FMinLength write SetMinLength default -1;
    property MaxLength: Integer read FMaxLength write SetMaxLength default -1;
    property MinValue: string read FMinValue write SetMinValue;
    property MaxValue: string read FMaxValue write SetMaxValue;
  end;

  // Kolekce pravidel pro všechny sloupce
  TColumnFilters = class(TOwnedCollection)
  private
    FOnChanged: TNotifyEvent;
    function GetItem(Index: Integer): TColumnFilterItem;
    procedure SetItem(Index: Integer; const Value: TColumnFilterItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TColumnFilterItem;
    procedure EnsureCount(AColCount: Integer);
    property Items[Index: Integer]: TColumnFilterItem read GetItem write SetItem; default;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

procedure ApplyColumnFilterKeyPress(const AFilter: TColumnFilter; const AText: string; var Key: Char);
function ValidateTextByColumnFilter(const AFilter: TColumnFilter; const AText: string): Boolean;
function ResolveColumnFilter(AFilters: TColumnFilters; AColumn: Integer): TColumnFilter;
function TryApplyColumnFilter(const AFilter: TColumnFilter; var AText: string): Boolean;

implementation

function ValidateExpressionText(const AText: string): Boolean; forward;
function TryEvaluateExpression(const Expr: string; out Value: Double): Boolean; forward;

// Sjednotí desetinnou tečku nebo čárku podle místního nastavení
function NormalizeDecimalKeyChar(Key: Char): Char;
begin
  Result := Key;
  if (Result = '.') or (Result = ',') then
    Result := FormatSettings.DecimalSeparator;
end;

function LastTextChar(const S: string): Char;
var
  I: Integer;
begin
  Result := #0;
  for I := Length(S) downto 1 do
    if S[I] <> ' ' then
    begin
      Result := S[I];
      Exit;
    end;
end;

function FirstTextChar(const S: string): Char;
var
  I: Integer;
begin
  Result := #0;
  for I := 1 to Length(S) do
    if S[I] <> ' ' then
    begin
      Result := S[I];
      Exit;
    end;
end;

function NextTextChar(const S: string; StartIndex: Integer): Char;
var
  I: Integer;
begin
  Result := #0;
  for I := StartIndex + 1 to Length(S) do
    if S[I] <> ' ' then
    begin
      Result := S[I];
      Exit;
    end;
end;

function NormalizeDecimalText(const S: string): string;
begin
  Result := StringReplace(S, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
  Result := StringReplace(Result, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]);
end;

function CurrentNumberHasDecimal(const S: string): Boolean;
var
  I: Integer;
  Ch: Char;
begin
  Result := False;
  for I := Length(S) downto 1 do
  begin
    Ch := S[I];

    if Ch = ' ' then
      Continue;

    if CharInSet(Ch, ['+', '-', '*', '/', '^', '(', ')']) then
      Exit;

    if Ch = FormatSettings.DecimalSeparator then
      Exit(True);
  end;
end;

function TryParseLimit(const S: string; out Value: Double): Boolean;
var
  Text: string;
begin
  Text := Trim(S);
  if Text = '' then
    Exit(False);

  Text := NormalizeDecimalText(Text);
  Result := TryStrToFloat(Text, Value);
end;

function TryGetFilterValue(const AFilter: TColumnFilter; const AText: string; out Value: Double): Boolean;
var
  Text: string;
begin
  Result := False;
  Text := Trim(AText);
  if Text = '' then
    Exit;

  case AFilter.DataType of
    fInteger, fFloat:
      begin
        Text := NormalizeDecimalText(Text);
        Result := TryStrToFloat(Text, Value);
      end;
    fExpression:
      begin
        if not ValidateExpressionText(Text) then
          Exit(False);
        Result := TryEvaluateExpression(Text, Value);
      end;
  else
    begin
      Text := NormalizeDecimalText(Text);
      Result := TryStrToFloat(Text, Value);
    end;
  end;
end;

function CheckMinMaxValue(const AFilter: TColumnFilter; const AText: string): Boolean;
var
  Value, MinValue, MaxValue: Double;
begin
  Result := True;

  if not TryGetFilterValue(AFilter, AText, Value) then
    Exit(True);

  if TryParseLimit(AFilter.MinValue, MinValue) and (Value < MinValue) then
    Exit(False);

  if TryParseLimit(AFilter.MaxValue, MaxValue) and (Value > MaxValue) then
    Exit(False);
end;

function CheckMaxValueWhileTyping(const AFilter: TColumnFilter; const AText: string; Key: Char): Boolean;
var
  Candidate: string;
  Value, MaxValue: Double;
begin
  Result := True;

  if not TryParseLimit(AFilter.MaxValue, MaxValue) then
    Exit(True);

  if CharInSet(Key, [#0, #1, #3, #8, #22, #24]) then
    Exit(True);

  Candidate := AText + Key;
  if not TryGetFilterValue(AFilter, Candidate, Value) then
    Exit(True);

  Result := Value <= MaxValue;
end;

procedure ApplyIntegerKeyPress(var Key: Char);
begin
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  if not CharInSet(Key, ['0'..'9', #8]) then
    Key := #0;
end;

procedure ApplyFloatKeyPress(const AText: string; var Key: Char);
begin
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  Key := NormalizeDecimalKeyChar(Key);

  if not CharInSet(Key, ['0'..'9', FormatSettings.DecimalSeparator, #8]) then
  begin
    Key := #0;
    Exit;
  end;

  if (Key = FormatSettings.DecimalSeparator) and
     (Pos(FormatSettings.DecimalSeparator, AText) > 0) then
    Key := #0;
end;

procedure ApplyExpressionKeyPress(const AText: string; var Key: Char);
var
  LastChar: Char;
begin
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  Key := NormalizeDecimalKeyChar(Key);

  if not CharInSet(Key, ['0'..'9', '+', '-', '*', '/', '(', ')', '^',
    FormatSettings.DecimalSeparator, ' ', #8]) then
  begin
    Key := #0;
    Exit;
  end;

  LastChar := LastTextChar(AText);

  if CharInSet(Key, ['+', '*', '/', '^']) and
     CharInSet(LastChar, ['+', '-', '*', '/', '^']) then
    Key := #0;

  if (Key = '-') and CharInSet(LastChar, ['+', '-', '*', '/', '^']) and
     (LastChar = '-') then
    Key := #0;

  if (Key = FormatSettings.DecimalSeparator) and
     (CharInSet(LastChar, ['+', '-', '*', '/', '^', ')', '(',
       FormatSettings.DecimalSeparator]) or CurrentNumberHasDecimal(AText)) then
      Key := #0;
end;

function ValidateIntegerText(const AText: string): Boolean;
var
  Ch: Char;
begin
  Result := True;
  for Ch in AText do
    if not CharInSet(Ch, ['0'..'9']) then
      Exit(False);
end;

function ValidateFloatText(const AText: string): Boolean;
var
  Ch: Char;
  HasDecimal: Boolean;
begin
  Result := True;
  HasDecimal := False;

  for Ch in AText do
  begin
    if Ch = FormatSettings.DecimalSeparator then
    begin
      if HasDecimal then
        Exit(False);
      HasDecimal := True;
    end
    else if not CharInSet(Ch, ['0'..'9']) then
      Exit(False);
  end;
end;

function ValidateExpressionText(const AText: string): Boolean;
var
  I, Balance: Integer;
  Ch, PrevChar, NextChar, FirstChar, LastChar: Char;
  NumberHasDecimal: Boolean;
begin
  Result := True;
  Balance := 0;
  PrevChar := #0;
  FirstChar := FirstTextChar(AText);
  LastChar := LastTextChar(AText);
  NumberHasDecimal := False;

  for I := 1 to Length(AText) do
  begin
    Ch := AText[I];

    if Ch = ' ' then
      Continue;

    if not CharInSet(Ch, ['0'..'9', '+', '-', '*', '/', '^', '(', ')',
      FormatSettings.DecimalSeparator]) then
      Exit(False);

    if CharInSet(Ch, ['+', '-', '*', '/', '^', '(', ')']) then
      NumberHasDecimal := False;

    if Ch = '(' then
      Inc(Balance)
    else if Ch = ')' then
    begin
      Dec(Balance);
      if Balance < 0 then
        Exit(False);
    end;

    if CharInSet(Ch, ['+', '*', '/', '^']) and
       CharInSet(PrevChar, ['+', '-', '*', '/', '^']) then
      Exit(False);

    if (Ch = '-') and CharInSet(PrevChar, ['+', '-', '*', '/', '^']) and
       (PrevChar = '-') then
      Exit(False);

    if Ch = FormatSettings.DecimalSeparator then
    begin
      if NumberHasDecimal then
        Exit(False);

      if CharInSet(PrevChar, ['+', '-', '*', '/', '^', ')', '(',
        FormatSettings.DecimalSeparator]) then
        Exit(False);

      NextChar := NextTextChar(AText, I);
      if CharInSet(NextChar, ['+', '-', '*', '/', '^', ')', '(',
        FormatSettings.DecimalSeparator]) then
        Exit(False);

      NumberHasDecimal := True;
    end;

    PrevChar := Ch;
  end;

  if Balance <> 0 then
    Exit(False);

  if CharInSet(LastChar, ['+', '*', '/', '^']) then
    Exit(False);

  if (FirstChar <> #0) and CharInSet(FirstChar, ['*', '/', '^', ')']) then
    Exit(False);
end;

function TryEvaluateExpression(const Expr: string; out Value: Double): Boolean;
var
  ScriptEngine: OleVariant;
  FixedExpr: string;
begin
  Result := False;
  try
    FixedExpr := StringReplace(Expr, ',', '.', [rfReplaceAll]);
    ScriptEngine := CreateOleObject('MSScriptControl.ScriptControl');
    ScriptEngine.Language := 'VBScript';
    Value := ScriptEngine.Eval(FixedExpr);
    Result := True;
  except
    Value := 0;
  end;
end;

class function TColumnFilter.None: TColumnFilter;
begin
  Result.DataType := fNone;
  Result.MinLength := -1;
  Result.MaxLength := -1;
  Result.MinValue := '';
  Result.MaxValue := '';
end;

class function TColumnFilter.Integer: TColumnFilter;
begin
  Result := None;
  Result.DataType := fInteger;
end;

class function TColumnFilter.Float: TColumnFilter;
begin
  Result := None;
  Result.DataType := fFloat;
end;

class function TColumnFilter.Expression: TColumnFilter;
begin
  Result := None;
  Result.DataType := fExpression;
end;

constructor TColumnFilterItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FDataType := fNone;
  FMinLength := -1;
  FMaxLength := -1;
  FMinValue := '';
  FMaxValue := '';
end;

procedure TColumnFilterItem.SetDataType(const Value: TColumnDataType);
begin
  if FDataType = Value then
    Exit;
  FDataType := Value;
  Changed(False);
end;

function TColumnFilterItem.GetColumn: Integer;
begin
  Result := Index;
end;

procedure TColumnFilterItem.SetMinLength(const Value: Integer);
begin
  if FMinLength = Value then
    Exit;
  FMinLength := Value;
  Changed(False);
end;

procedure TColumnFilterItem.SetMaxLength(const Value: Integer);
begin
  if FMaxLength = Value then
    Exit;
  FMaxLength := Value;
  Changed(False);
end;

procedure TColumnFilterItem.SetMinValue(const Value: string);
begin
  if FMinValue = Value then
    Exit;
  FMinValue := Value;
  Changed(False);
end;

procedure TColumnFilterItem.SetMaxValue(const Value: string);
begin
  if FMaxValue = Value then
    Exit;
  FMaxValue := Value;
  Changed(False);
end;

function TColumnFilterItem.ToFilter: TColumnFilter;
begin
  Result.DataType := FDataType;
  Result.MinLength := FMinLength;
  Result.MaxLength := FMaxLength;
  Result.MinValue := FMinValue;
  Result.MaxValue := FMaxValue;
end;

constructor TColumnFilters.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TColumnFilterItem);
end;

function TColumnFilters.Add: TColumnFilterItem;
begin
  Result := TColumnFilterItem(inherited Add);
end;

procedure TColumnFilters.EnsureCount(AColCount: Integer);
begin
  while Count < AColCount do
    Add;
  while Count > AColCount do
    Delete(Count - 1);
end;

function TColumnFilters.GetItem(Index: Integer): TColumnFilterItem;
begin
  Result := TColumnFilterItem(inherited GetItem(Index));
end;

procedure TColumnFilters.SetItem(Index: Integer; const Value: TColumnFilterItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TColumnFilters.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure ApplyColumnFilterKeyPress(const AFilter: TColumnFilter; const AText: string; var Key: Char);
begin
  if (Key <> #8) and (Key >= #32) and (AFilter.MaxLength >= 0) and (Length(AText) >= AFilter.MaxLength) then
  begin
    Key := #0;
    Exit;
  end;

  case AFilter.DataType of
    fNone:
      Exit;
    fInteger:
      ApplyIntegerKeyPress(Key);
    fFloat:
      ApplyFloatKeyPress(AText, Key);
    fExpression:
      ApplyExpressionKeyPress(AText, Key);
  end;

  if not CheckMaxValueWhileTyping(AFilter, AText, Key) then
    Key := #0;
end;

function ValidateTextByColumnFilter(const AFilter: TColumnFilter; const AText: string): Boolean;
begin
  Result := True;

  if (AFilter.MinLength >= 0) and (Length(AText) < AFilter.MinLength) then
    Exit(False);

  if (AFilter.MaxLength >= 0) and (Length(AText) > AFilter.MaxLength) then
    Exit(False);

  case AFilter.DataType of
    fNone:
      Result := True;
    fInteger:
      Result := ValidateIntegerText(AText);
    fFloat:
      Result := ValidateFloatText(AText);
    fExpression:
      Result := ValidateExpressionText(AText);
  end;

  if not Result then
    Exit(False);

  Result := CheckMinMaxValue(AFilter, AText);
end;

function TryApplyColumnFilter(const AFilter: TColumnFilter; var AText: string): Boolean;
var
  Value: Double;
begin
  Result := ValidateTextByColumnFilter(AFilter, AText);
  if not Result then
    Exit;

  Result := CheckMinMaxValue(AFilter, AText);
  if not Result then
    Exit;

  if (AFilter.DataType = fExpression) and (Trim(AText) <> '') then
  begin
    Result := TryEvaluateExpression(AText, Value);
    if Result then
    begin
      AText := FloatToStr(Value);
      Result := CheckMinMaxValue(AFilter, AText);
    end;
  end;
end;

function ResolveColumnFilter(AFilters: TColumnFilters; AColumn: Integer): TColumnFilter;
begin
  Result := TColumnFilter.None;
  if AFilters = nil then
    Exit;
  if (AColumn >= 0) and (AColumn < AFilters.Count) then
    Result := AFilters[AColumn].ToFilter;
end;

end.

