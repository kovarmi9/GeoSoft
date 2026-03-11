unit ColumnRuleUtils;

interface

uses
  System.Classes,
  System.SysUtils;

type
  TColumnRuleKind = (
    crNone,
    crInteger,
    crFloat,
    crExpression
  );

  TColumnRule = record
    Enabled: Boolean;
    Kind: TColumnRuleKind;
    class function None: TColumnRule; static;
    class function Integer: TColumnRule; static;
    class function Float: TColumnRule; static;
    class function Expression: TColumnRule; static;
  end;

  TColumnRuleItem = class(TCollectionItem)
  private
    FColumn: Integer;
    FEnabled: Boolean;
    FKind: TColumnRuleKind;
    procedure SetColumn(const Value: Integer);
    procedure SetEnabled(const Value: Boolean);
    procedure SetKind(const Value: TColumnRuleKind);
  public
    constructor Create(Collection: TCollection); override;
    function ToRule: TColumnRule;
  published
    property Column: Integer read FColumn write SetColumn default 0;
    property Enabled: Boolean read FEnabled write SetEnabled default False;
    property Kind: TColumnRuleKind read FKind write SetKind default crNone;
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
    function FindByColumn(AColumn: Integer): TColumnRuleItem;
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
  Result.Enabled := False;
  Result.Kind := crNone;
end;

class function TColumnRule.Integer: TColumnRule;
begin
  Result.Enabled := True;
  Result.Kind := crInteger;
end;

class function TColumnRule.Float: TColumnRule;
begin
  Result.Enabled := True;
  Result.Kind := crFloat;
end;

class function TColumnRule.Expression: TColumnRule;
begin
  Result.Enabled := True;
  Result.Kind := crExpression;
end;

constructor TColumnRuleItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FColumn := 0;
  FEnabled := False;
  FKind := crNone;
end;

procedure TColumnRuleItem.SetColumn(const Value: Integer);
begin
  if FColumn = Value then
    Exit;
  FColumn := Value;
  Changed(False);
end;

procedure TColumnRuleItem.SetEnabled(const Value: Boolean);
begin
  if FEnabled = Value then
    Exit;
  FEnabled := Value;
  Changed(False);
end;

procedure TColumnRuleItem.SetKind(const Value: TColumnRuleKind);
begin
  if FKind = Value then
    Exit;
  FKind := Value;
  Changed(False);
end;

function TColumnRuleItem.ToRule: TColumnRule;
begin
  Result.Enabled := FEnabled;
  Result.Kind := FKind;
end;

constructor TColumnRules.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TColumnRuleItem);
end;

function TColumnRules.Add: TColumnRuleItem;
begin
  Result := TColumnRuleItem(inherited Add);
end;

function TColumnRules.FindByColumn(AColumn: Integer): TColumnRuleItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if Items[I].Column = AColumn then
      Exit(Items[I]);
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
  if not ARule.Enabled then
    Exit;

  case ARule.Kind of
    crNone:
      Exit;
    crInteger:
      begin
        if CharInSet(Key, [#1, #3, #22, #24]) then
          Exit;

        if not CharInSet(Key, ['0'..'9', #8]) then
          Key := #0;
      end;
    crFloat:
      begin
        if CharInSet(Key, [#1, #3, #22, #24]) then
          Exit;

        Key := NormalizeDecimalKeyChar(Key);

        if not CharInSet(Key, ['0'..'9', '+', '-', FormatSettings.DecimalSeparator, #8]) then
          Key := #0;
      end;
    crExpression:
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
var
  Item: TColumnRuleItem;
begin
  Result := TColumnRule.None;
  if ARules = nil then
    Exit;

  Item := ARules.FindByColumn(AColumn);
  if Item <> nil then
    Result := Item.ToRule;
end;

end.
