unit MyStringGrid;

interface

uses
  System.Classes,  // TComponent, TStrings, TStringList
  System.Types,    // TRect
  System.Math,     // Max()
  System.SysUtils, // CharInSet, StrToIntDef, Trim...
  Vcl.Controls,    // TShiftState...
  Vcl.Grids,       // TStringGrid...
  ColumnRuleUtils;

type
  // Co mÄ‚Ë‡ grid udĂ„â€şlat, kdyÄąÄľ uÄąÄľivatel stiskne Enter/Tab v poslednÄ‚Â­ datovÄ‚Â© buÄąÂce
  TEnterEndBehavior = (ebStayOnLastCell, ebWrapToStart, ebAddRow, ebMoveFocusNext);

  // ValidÄ‚Ë‡tor bunĂ„â€şk (normÄ‚Ë‡lnÄ‚Â­ procedura, NE metoda objektu)
  TMyGridKeyValidator = procedure(AGrid: TObject; ACol, ARow: Integer; var Key: Char);

  TMyStringGrid = class(TStringGrid)
  private
    // Jak se zachovat, kdyÄąÄľ Enter/Tab na konci tabulky
    FEnterEndBehavior: TEnterEndBehavior;

    FColumnHeaders: TStrings;
    FRowHeaders: TStrings;
    FColumnRuleItems: TColumnRules;
    FSyncingColumnRules: Boolean;

    // Pole validÄ‚Ë‡torÄąĹ» pro sloupce
    FValidators: array of TMyGridKeyValidator;

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);
    procedure SetColumnRules(const Value: TColumnRules);
    procedure UpdateHeaders;
    procedure AutoSizeDataColumns;
    procedure ColumnRulesChanged(Sender: TObject);

    procedure EnsureValidatorSize;
    procedure EnsureColumnRuleCount;
    procedure ApplyColumnRule(ACol, ARow: Integer; var Key: Char);

  protected
    procedure Loaded; override;
    procedure Resize; override;
    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // NastavenÄ‚Â­ validÄ‚Ë‡toru sloupce
    procedure SetColumnValidator(ACol: Integer; AValidator: TMyGridKeyValidator);
    procedure ClearColumnValidator(ACol: Integer);
    procedure ClearAllValidators;
    procedure SetColumnRule(ACol: Integer; const ARule: TColumnRule);
    procedure ClearColumnRule(ACol: Integer);
    procedure ClearAllColumnRules;

  published
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior default ebStayOnLastCell;

    property ColumnHeaders: TStrings
      read FColumnHeaders write SetColumnHeaders;

    property RowHeaders: TStrings
      read FRowHeaders write SetRowHeaders;

    property ColumnRules: TColumnRules
      read FColumnRuleItems write SetColumnRules;
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Graphics;

{ TMyStringGrid }

constructor TMyStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Options := Options + [goEditing, goTabs, goColSizing, goRowSizing];

  FEnterEndBehavior := ebStayOnLastCell;

  FColumnHeaders := TStringList.Create;
  FRowHeaders := TStringList.Create;
  FColumnRuleItems := TColumnRules.Create(Self);
  FColumnRuleItems.OnChanged := ColumnRulesChanged;

  EnsureValidatorSize;
  EnsureColumnRuleCount;
end;

destructor TMyStringGrid.Destroy;
begin
  FColumnHeaders.Free;
  FRowHeaders.Free;
  FColumnRuleItems.Free;
  inherited Destroy;
end;

procedure TMyStringGrid.EnsureValidatorSize;
begin
  // drzi pole validatoru stejne dlouhe jako ColCount
  if Length(FValidators) <> ColCount then
    SetLength(FValidators, ColCount);
end;

procedure TMyStringGrid.EnsureColumnRuleCount;
begin
  if FSyncingColumnRules then
    Exit;
  FSyncingColumnRules := True;
  try
    FColumnRuleItems.EnsureCount(ColCount);
  finally
    FSyncingColumnRules := False;
  end;
end;

procedure TMyStringGrid.ClearAllValidators;
var
  I: Integer;
begin
  EnsureValidatorSize;
  for I := 0 to High(FValidators) do
    FValidators[I] := nil;
end;

procedure TMyStringGrid.SetColumnValidator(ACol: Integer; AValidator: TMyGridKeyValidator);
begin
  EnsureValidatorSize;
  if (ACol >= 0) and (ACol < Length(FValidators)) then
    FValidators[ACol] := AValidator;
end;

procedure TMyStringGrid.SetColumnRule(ACol: Integer; const ARule: TColumnRule);
var
  Item: TColumnRuleItem;
begin
  if ACol < 0 then
    Exit;

  EnsureColumnRuleCount;
  if ACol >= FColumnRuleItems.Count then
    Exit;

  Item := FColumnRuleItems[ACol];
  Item.DataType := ARule.DataType;
  Item.MinLength := ARule.MinLength;
  Item.MaxLength := ARule.MaxLength;
  Item.MinValue := ARule.MinValue;
  Item.MaxValue := ARule.MaxValue;
end;

procedure TMyStringGrid.ClearColumnValidator(ACol: Integer);
begin
  EnsureValidatorSize;
  if (ACol >= 0) and (ACol < Length(FValidators)) then
    FValidators[ACol] := nil;
end;

procedure TMyStringGrid.ClearColumnRule(ACol: Integer);
begin
  SetColumnRule(ACol, TColumnRule.None);
end;

procedure TMyStringGrid.ClearAllColumnRules;
var
  I: Integer;
begin
  EnsureColumnRuleCount;
  for I := 0 to FColumnRuleItems.Count - 1 do
    ClearColumnRule(I);
end;

procedure TMyStringGrid.ApplyColumnRule(ACol, ARow: Integer; var Key: Char);
begin
  if (ARow < FixedRows) or (ACol < FixedCols) then
    Exit;

  ApplyColumnRuleKeyPress(ResolveColumnRule(FColumnRuleItems, ACol), Key);
end;

procedure TMyStringGrid.SetColumnRules(const Value: TColumnRules);
begin
  FColumnRuleItems.Assign(Value);
  EnsureColumnRuleCount;
end;

procedure TMyStringGrid.ColumnRulesChanged(Sender: TObject);
begin
  if FColumnRuleItems.Count <> ColCount then
    EnsureColumnRuleCount;
  Invalidate;
end;

procedure TMyStringGrid.KeyPress(var Key: Char);
var
  V: TMyGridKeyValidator;
  VK: Word;
begin
  // Enter/Tab resime jako navigaci (KeyDown), ne jako psani znaku
  if Key = #13 then
  begin
    Key := #0;
    VK := VK_RETURN;
    KeyDown(VK, []);
    Exit;
  end;

  if Key = #9 then
  begin
    Key := #0;
    VK := VK_TAB;
    KeyDown(VK, []);
    Exit;
  end;

  // validujeme jen v datove casti (ne hlavicky)
  if (Key <> #0) and (Row >= FixedRows) and (Col >= FixedCols) then
  begin
    EnsureValidatorSize;

    if (Col >= 0) and (Col < Length(FValidators)) then
    begin
      V := FValidators[Col];
      if Assigned(V) then
        V(Self, Col, Row, Key);
      if not Assigned(V) then
        ApplyColumnRule(Col, Row, Key);
    end;
  end;

  if Key = #0 then
    Exit;

  inherited KeyPress(Key);
end;

procedure TMyStringGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  PressedKey: Word;
  FirstDataCol, FirstDataRow: Integer;
  GoForward: Boolean;
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    PressedKey := Key;
    Key := 0;

    FirstDataCol := FixedCols;
    FirstDataRow := FixedRows;

    if Row < FirstDataRow then
      Row := FirstDataRow;
    if Col < FirstDataCol then
      Col := FirstDataCol;

    if Col < ColCount - 1 then
      Col := Col + 1
    else if Row < RowCount - 1 then
    begin
      Row := Row + 1;
      Col := FirstDataCol;
    end
    else
    begin
      case FEnterEndBehavior of
        ebStayOnLastCell:
          begin
            Row := RowCount - 1;
            Col := ColCount - 1;
          end;
        ebWrapToStart:
          begin
            Row := FirstDataRow;
            Col := FirstDataCol;
          end;
        ebAddRow:
          begin
            RowCount := RowCount + 1;
            Row := Row + 1;
            Col := FirstDataCol;
          end;
        ebMoveFocusNext:
          begin
            if EditorMode then
              EditorMode := False;
            GoForward := not ((PressedKey = VK_TAB) and (ssShift in Shift));
            SelectNext(Self, GoForward, True);
          end;
      end;
    end;

    if (FEnterEndBehavior <> ebMoveFocusNext) and (goEditing in Options) then
      EditorMode := True;

    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

procedure TMyStringGrid.DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  S: string;
  X, Y: Integer;
  SavedDC: Integer;
begin
  if (ARow < FixedRows) or (ACol < FixedCols) then
  begin
    SavedDC := SaveDC(Canvas.Handle);
    try
      Canvas.Brush.Color := clBtnFace;
      Canvas.Font.Style := [fsBold];
      Canvas.FillRect(Rect);

      S := Cells[ACol, ARow];
      X := Rect.Left + (Rect.Width - Canvas.TextWidth(S)) div 2;
      Y := Rect.Top + (Rect.Height - Canvas.TextHeight(S)) div 2;
      Canvas.TextRect(Rect, X, Y, S);
    finally
      RestoreDC(Canvas.Handle, SavedDC);
    end;
  end
  else
    inherited DrawCell(ACol, ARow, Rect, State);
end;

procedure TMyStringGrid.Loaded;
begin
  inherited;
  EnsureColumnRuleCount;
  UpdateHeaders;
  AutoSizeDataColumns;
end;

procedure TMyStringGrid.SizeChanged(OldColCount, OldRowCount: Integer);
begin
  inherited SizeChanged(OldColCount, OldRowCount);
  EnsureValidatorSize;
  EnsureColumnRuleCount;
end;

procedure TMyStringGrid.SetColumnHeaders(const Value: TStrings);
begin
  FColumnHeaders.Assign(Value);
  UpdateHeaders;
end;

procedure TMyStringGrid.SetRowHeaders(const Value: TStrings);
begin
  FRowHeaders.Assign(Value);
  UpdateHeaders;
end;

procedure TMyStringGrid.UpdateHeaders;
var
  C, R: Integer;
begin
  if (FColumnHeaders.Count > 0) and (FixedRows = 0) then
    FixedRows := 1;
  if (FRowHeaders.Count > 0) and (FixedCols = 0) then
    FixedCols := 1;

  if FixedRows > 0 then
    for C := 0 to ColCount - 1 do
      if C < FColumnHeaders.Count then
        Cells[C, 0] := FColumnHeaders[C];

  if FixedCols > 0 then
    for R := 0 to RowCount - 1 do
      if R < FRowHeaders.Count then
        Cells[0, R] := FRowHeaders[R];

  Invalidate;
end;

procedure TMyStringGrid.Resize;
begin
  inherited;
  // AutoSizeDataColumns;
end;

procedure TMyStringGrid.AutoSizeDataColumns;
var
  C, DataCols, Avail, FixedW, Base, Extra, MinW, Used, Last: Integer;
begin
  if ColCount = 0 then
    Exit;

  FixedW := 0;
  for C := 0 to FixedCols - 1 do
    Inc(FixedW, ColWidths[C]);

  DataCols := ColCount - FixedCols;
  if DataCols <= 0 then
    Exit;

  Avail := ClientWidth - FixedW - GridLineWidth * DataCols;
  if Avail <= 0 then
    Exit;

  MinW := 40;
  Base := Avail div DataCols;
  Extra := Avail mod DataCols;

  Used := 0;
  Last := ColCount - 1;

  for C := FixedCols to Last - 1 do
  begin
    ColWidths[C] := Max(Base + Ord((C - FixedCols) < Extra), MinW);
    Inc(Used, ColWidths[C]);
  end;

  ColWidths[Last] := Max(Avail - Used, MinW);
end;

end.
