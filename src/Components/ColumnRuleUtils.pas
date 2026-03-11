unit ColumnRuleUtils;

interface

uses
  System.Classes,
  System.SysUtils;

type
  TColumnDataType = (
    cdtNone,
    cdtString,
    cdtInteger,
    cdtFloat,
    cdtExpression
  );

  TColumnRule = record
    DataType: TColumnDataType;
    MinLength: Integer;
    MaxLength: Integer;
    MinValue: string;
    MaxValue: string;
    class function None: TColumnRule; static;
    class function Integer: TColumnRule; static;
    class function Float: TColumnRule; static;
    class function Expression: TColumnRule; static;
    function HasSettings: Boolean;
  end;

  TColumnRuleItem = class(TCollectionItem)
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
    function ToRule: TColumnRule;
  published
    property Column: Integer read GetColumn stored False;
    property DataType: TColumnDataType read FDataType write SetDataType default cdtNone;
    property MinLength: Integer read FMinLength write SetMinLength default -1;
    property MaxLength: Integer read FMaxLength write SetMaxLength default -1;
    property MinValue: string read FMinValue write SetMinValue;
    property MaxValue: string read FMaxValue write SetMaxValue;
  end;

  TColumnRules = class(TOwnedCollection)
  private
    FOnChanged: TNotifyEvent;
    function GetItem(Index: Integer): TColumnRuleItem;
    procedure SetItem(Index: Integer; const Value: TColumnRuleItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TColumnRuleItem;
    procedure EnsureCount(AColCount: Integer);
    property Items[Index: Integer]: TColumnRuleItem read GetItem write SetItem; default;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

procedure ApplyColumnRuleKeyPress(const ARule: TColumnRule; var Key: Char);
function ResolveColumnRule(ARules: TColumnRules; AColumn: Integer): TColumnRule;

implementation

function NormalizeDecimalKeyChar(Key: Char): Char;
begin
  Result := Key;
  if (Result = '.') or (Result = ',') then
    Result := FormatSettings.DecimalSeparator;
end;

class function TColumnRule.None: TColumnRule;
begin
  Result.DataType := cdtNone;
  Result.MinLength := -1;
  Result.MaxLength := -1;
  Result.MinValue := '';
  Result.MaxValue := '';
end;

class function TColumnRule.Integer: TColumnRule;
begin
  Result := None;
  Result.DataType := cdtInteger;
end;

class function TColumnRule.Float: TColumnRule;
begin
  Result := None;
  Result.DataType := cdtFloat;
end;

class function TColumnRule.Expression: TColumnRule;
begin
  Result := None;
  Result.DataType := cdtExpression;
end;

function TColumnRule.HasSettings: Boolean;
begin
  Result :=
    (DataType <> cdtNone) or
    (MinLength >= 0) or
    (MaxLength >= 0) or
    (Trim(MinValue) <> '') or
    (Trim(MaxValue) <> '');
end;

constructor TColumnRuleItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FDataType := cdtNone;
  FMinLength := -1;
  FMaxLength := -1;
  FMinValue := '';
  FMaxValue := '';
end;

procedure TColumnRuleItem.SetDataType(const Value: TColumnDataType);
begin
  if FDataType = Value then
    Exit;
  FDataType := Value;
  Changed(False);
end;

function TColumnRuleItem.GetColumn: Integer;
begin
  Result := Index;
end;

procedure TColumnRuleItem.SetMinLength(const Value: Integer);
begin
  if FMinLength = Value then
    Exit;
  FMinLength := Value;
  Changed(False);
end;

procedure TColumnRuleItem.SetMaxLength(const Value: Integer);
begin
  if FMaxLength = Value then
    Exit;
  FMaxLength := Value;
  Changed(False);
end;

procedure TColumnRuleItem.SetMinValue(const Value: string);
begin
  if FMinValue = Value then
    Exit;
  FMinValue := Value;
  Changed(False);
end;

procedure TColumnRuleItem.SetMaxValue(const Value: string);
begin
  if FMaxValue = Value then
    Exit;
  FMaxValue := Value;
  Changed(False);
end;

function TColumnRuleItem.ToRule: TColumnRule;
begin
  Result.DataType := FDataType;
  Result.MinLength := FMinLength;
  Result.MaxLength := FMaxLength;
  Result.MinValue := FMinValue;
  Result.MaxValue := FMaxValue;
end;

constructor TColumnRules.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TColumnRuleItem);
end;

function TColumnRules.Add: TColumnRuleItem;
begin
  Result := TColumnRuleItem(inherited Add);
end;

procedure TColumnRules.EnsureCount(AColCount: Integer);
begin
  while Count < AColCount do
    Add;
  while Count > AColCount do
    Delete(Count - 1);
end;

function TColumnRules.GetItem(Index: Integer): TColumnRuleItem;
begin
  Result := TColumnRuleItem(inherited GetItem(Index));
end;

procedure TColumnRules.SetItem(Index: Integer; const Value: TColumnRuleItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TColumnRules.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure ApplyColumnRuleKeyPress(const ARule: TColumnRule; var Key: Char);
begin
  case ARule.DataType of
    cdtNone, cdtString:
      Exit;
    cdtInteger:
      begin
        if CharInSet(Key, [#1, #3, #22, #24]) then
          Exit;

        if not CharInSet(Key, ['0'..'9', #8]) then
          Key := #0;
      end;
    cdtFloat:
      begin
        if CharInSet(Key, [#1, #3, #22, #24]) then
          Exit;

        Key := NormalizeDecimalKeyChar(Key);

        if not CharInSet(Key, ['0'..'9', '+', '-', FormatSettings.DecimalSeparator, #8]) then
          Key := #0;
      end;
    cdtExpression:
      begin
        if CharInSet(Key, [#1, #3, #22, #24]) then
          Exit;

        Key := NormalizeDecimalKeyChar(Key);

        if not CharInSet(Key, ['0'..'9', '+', '-', '*', '/', '(', ')', FormatSettings.DecimalSeparator, #8]) then
          Key := #0;
      end;
  end;
end;

function ResolveColumnRule(ARules: TColumnRules; AColumn: Integer): TColumnRule;
begin
  Result := TColumnRule.None;
  if ARules = nil then
    Exit;
  if (AColumn >= 0) and (AColumn < ARules.Count) then
    Result := ARules[AColumn].ToRule;
end;

end.
