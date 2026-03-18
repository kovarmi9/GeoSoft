unit ColumnValidation;

interface

uses
  System.Classes,
  System.SysUtils;

type
  // Zatím jen čtyři základní typy vstupu
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
    function HasSettings: Boolean;
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

implementation

// Sjednotí desetinnou tečku nebo čárku podle místního nastavení
function NormalizeDecimalKeyChar(Key: Char): Char;
begin
  Result := Key;
  if (Result = '.') or (Result = ',') then
    Result := FormatSettings.DecimalSeparator;
end;

function GetLastNonSpaceChar(const S: string): Char;
var
  I: Integer;
begin
  Result := #0;
  for I := Length(S) downto 1 do
    if S[I] <> ' ' then
      Exit(S[I]);
end;

function GetFirstNonSpaceChar(const S: string): Char;
var
  I: Integer;
begin
  Result := #0;
  for I := 1 to Length(S) do
    if S[I] <> ' ' then
      Exit(S[I]);
end;

function GetNextNonSpaceChar(const S: string; AIndex: Integer): Char;
var
  I: Integer;
begin
  Result := #0;
  for I := AIndex + 1 to Length(S) do
    if S[I] <> ' ' then
      Exit(S[I]);
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

function TColumnFilter.HasSettings: Boolean;
begin
  Result :=
    (DataType <> fNone) or
    (MinLength >= 0) or
    (MaxLength >= 0) or
    (Trim(MinValue) <> '') or
    (Trim(MaxValue) <> '');
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
      begin
        if CharInSet(Key, [#1, #3, #22, #24]) then
          Exit;

        if not CharInSet(Key, ['0'..'9', #8]) then
          Key := #0;
      end;
    fFloat:
      begin
        if CharInSet(Key, [#1, #3, #22, #24]) then
          Exit;

        Key := NormalizeDecimalKeyChar(Key);

        if not CharInSet(Key, ['0'..'9', FormatSettings.DecimalSeparator, #8]) then
          Key := #0;

        if (Key = FormatSettings.DecimalSeparator) and
           (Pos(FormatSettings.DecimalSeparator, AText) > 0) then
          Key := #0;
      end;
    fExpression:
      begin
        if CharInSet(Key, [#1, #3, #22, #24]) then
          Exit;

        Key := NormalizeDecimalKeyChar(Key);

        if not CharInSet(Key, ['0'..'9', '+', '-', '*', '/', '(', ')', '^',
          FormatSettings.DecimalSeparator, ' ', #8]) then
          Key := #0;

        if CharInSet(Key, ['+', '-', '*', '/', '^']) and CharInSet(GetLastNonSpaceChar(AText), ['+', '-', '*', '/', '^']) then
          Key := #0;

        if (Key = FormatSettings.DecimalSeparator) and
           CharInSet(GetLastNonSpaceChar(AText), ['+', '-', '*', '/', '^', ')', '(',
             FormatSettings.DecimalSeparator]) then
          Key := #0;
      end;
  end;
end;

function ValidateTextByColumnFilter(const AFilter: TColumnFilter; const AText: string): Boolean;
var
  I, DecCount, Balance: Integer;
  Ch, LastCh, FirstCh: Char;
begin
  Result := True;

  if (AFilter.MinLength >= 0) and (Length(AText) < AFilter.MinLength) then
    Exit(False);

  if (AFilter.MaxLength >= 0) and (Length(AText) > AFilter.MaxLength) then
    Exit(False);

  case AFilter.DataType of
    fNone:
      Exit(True);

    fInteger:
      begin
        for Ch in AText do
          if not CharInSet(Ch, ['0'..'9']) then
            Exit(False);
      end;

    fFloat:
      begin
        DecCount := 0;
        for Ch in AText do
        begin
          if Ch = FormatSettings.DecimalSeparator then
            Inc(DecCount)
          else if not CharInSet(Ch, ['0'..'9']) then
            Exit(False);
        end;
        if DecCount > 1 then
          Exit(False);
      end;

    fExpression:
      begin
        Balance := 0;
        LastCh := #0;
        FirstCh := GetFirstNonSpaceChar(AText);

        for I := 1 to Length(AText) do
        begin
          Ch := AText[I];

          if Ch = ' ' then
            Continue;

          if not CharInSet(Ch, ['0'..'9', '+', '-', '*', '/', '^', '(', ')',
            FormatSettings.DecimalSeparator]) then
            Exit(False);

          if Ch = '(' then
            Inc(Balance)
          else if Ch = ')' then
          begin
            Dec(Balance);
            if Balance < 0 then
              Exit(False);
          end;

          if CharInSet(Ch, ['+', '-', '*', '/', '^']) and
             CharInSet(LastCh, ['+', '-', '*', '/', '^']) then
            Exit(False);

          if Ch = FormatSettings.DecimalSeparator then
          begin
            if CharInSet(LastCh, ['+', '-', '*', '/', '^', ')', '(',
              FormatSettings.DecimalSeparator]) then
              Exit(False);

            if CharInSet(GetNextNonSpaceChar(AText, I), ['+', '-', '*', '/', '^', ')',
              '(', FormatSettings.DecimalSeparator]) then
              Exit(False);
          end;

          LastCh := Ch;
        end;

        if Balance <> 0 then
          Exit(False);

        if CharInSet(GetLastNonSpaceChar(AText), ['+', '-', '*', '/', '^']) then
          Exit(False);

        if (FirstCh <> #0) and CharInSet(FirstCh, ['*', '/', '^', ')']) then
          Exit(False);
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

