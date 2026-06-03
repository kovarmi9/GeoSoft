unit MyStringGrid;

interface

uses
  System.Classes,  // TComponent, TStrings, TStringList
  System.Types,    // TRect
  System.Math,     // Max()
  System.SysUtils, // CharInSet, StrToIntDef, Trim...
  Vcl.Controls,    // TShiftState...
  Vcl.Grids,       // TStringGrid...
  ColumnValidation;

type
  // Defines what the grid does when Enter or Tab is pressed in the last data cell
  TEnterEndBehavior = (ebStayOnLastCell, ebWrapToStart, ebAddRow, ebMoveFocusNext);

  // Per-column key validator — a plain procedure, not an object method
  TMyGridKeyValidator = procedure(AGrid: TObject; ACol, ARow: Integer; var Key: Char);

  // TStringGrid descendant with Enter/Tab navigation, column filters, and bold headers
  TMyStringGrid = class(TStringGrid)
  private
    // What to do when Enter or Tab is pressed on the last cell
    FEnterEndBehavior: TEnterEndBehavior;

    FColumnHeaders: TStrings;
    FRowHeaders: TStrings;
    FColumnFilterItems: TColumnFilters;
    FSyncingColumnFilters: Boolean;

    // Per-column key validator array (parallel to ColCount)
    FValidators: array of TMyGridKeyValidator;

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);
    procedure SetColumnFilters(const Value: TColumnFilters);
    procedure UpdateHeaders;
    procedure AutoSizeDataColumns;
    procedure ColumnFiltersChanged(Sender: TObject);

    procedure EnsureValidatorSize;
    procedure EnsureColumnFilterCount;
    function GetCellText(ACol, ARow: Integer): string;
    function ApplyFilterToCell(ACol, ARow: Integer): Boolean;
    procedure ClearCellIfInvalid(ACol, ARow: Integer);
    procedure ApplyColumnFilter(ACol, ARow: Integer; var Key: Char);

  protected
    procedure Loaded; override;
    procedure Resize; override;
    function SelectCell(ACol, ARow: Integer): Boolean; override;
    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Per-column validator management
    procedure SetColumnValidator(ACol: Integer; AValidator: TMyGridKeyValidator);
    procedure ClearColumnValidator(ACol: Integer);
    procedure ClearAllValidators;
    procedure SetColumnFilter(ACol: Integer; const AFilter: TColumnFilter);
    procedure ClearColumnFilter(ACol: Integer);
    procedure ClearAllColumnFilters;

  published
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior default ebStayOnLastCell;

    property ColumnHeaders: TStrings
      read FColumnHeaders write SetColumnHeaders;

    property RowHeaders: TStrings
      read FRowHeaders write SetRowHeaders;

    property ColumnFilters: TColumnFilters
      read FColumnFilterItems write SetColumnFilters;
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

  FColumnFilterItems := TColumnFilters.Create(Self);
  FColumnFilterItems.OnChanged := ColumnFiltersChanged;

  EnsureValidatorSize;
  EnsureColumnFilterCount;
end;

destructor TMyStringGrid.Destroy;
begin
  FColumnHeaders.Free;
  FRowHeaders.Free;
  FColumnFilterItems.Free;
  inherited Destroy;
end;

// Keeps the validator array the same length as ColCount
procedure TMyStringGrid.EnsureValidatorSize;
begin
  if Length(FValidators) <> ColCount then
    SetLength(FValidators, ColCount);
end;

procedure TMyStringGrid.EnsureColumnFilterCount;
begin
  if FSyncingColumnFilters then
    Exit;
  FSyncingColumnFilters := True;
  try
    FColumnFilterItems.EnsureCount(ColCount);
  finally
    FSyncingColumnFilters := False;
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

procedure TMyStringGrid.SetColumnFilter(ACol: Integer; const AFilter: TColumnFilter);
var
  Item: TColumnFilterItem;
begin
  if ACol < 0 then
    Exit;

  EnsureColumnFilterCount;
  if ACol >= FColumnFilterItems.Count then
    Exit;

  Item := FColumnFilterItems[ACol];
  Item.DataType := AFilter.DataType;
  Item.MinLength := AFilter.MinLength;
  Item.MaxLength := AFilter.MaxLength;
  Item.MinValue := AFilter.MinValue;
  Item.MaxValue := AFilter.MaxValue;
end;

procedure TMyStringGrid.ClearColumnValidator(ACol: Integer);
begin
  EnsureValidatorSize;
  if (ACol >= 0) and (ACol < Length(FValidators)) then
    FValidators[ACol] := nil;
end;

procedure TMyStringGrid.ClearColumnFilter(ACol: Integer);
begin
  SetColumnFilter(ACol, TColumnFilter.None);
end;

procedure TMyStringGrid.ClearAllColumnFilters;
var
  I: Integer;
begin
  EnsureColumnFilterCount;
  for I := 0 to FColumnFilterItems.Count - 1 do
    ClearColumnFilter(I);
end;

procedure TMyStringGrid.ApplyColumnFilter(ACol, ARow: Integer; var Key: Char);
var
  CurrentText: string;
begin
  if (ARow < FixedRows) or (ACol < FixedCols) then
    Exit;

  if EditorMode and Assigned(InplaceEditor) then
    CurrentText := InplaceEditor.Text
  else
    CurrentText := Cells[ACol, ARow];

  ApplyColumnFilterKeyPress(ResolveColumnFilter(FColumnFilterItems, ACol), CurrentText, Key);
end;

// Returns the live editor text when the cell is being edited, otherwise the cell value
function TMyStringGrid.GetCellText(ACol, ARow: Integer): string;
begin
  if EditorMode and Assigned(InplaceEditor) and (ACol = Col) and (ARow = Row) then
    Result := InplaceEditor.Text
  else
    Result := Cells[ACol, ARow];
end;

// Validates and possibly transforms the cell value; beeps and returns False on failure
function TMyStringGrid.ApplyFilterToCell(ACol, ARow: Integer): Boolean;
var
  Filter: TColumnFilter;
  CellText: string;
begin
  Result := True;

  if (ARow < FixedRows) or (ACol < FixedCols) then
    Exit;

  EnsureValidatorSize;
  // Skip filter when a legacy key validator is assigned for this column
  if (ACol >= 0) and (ACol < Length(FValidators)) and Assigned(FValidators[ACol]) then
    Exit;

  Filter := ResolveColumnFilter(FColumnFilterItems, ACol);
  CellText := GetCellText(ACol, ARow);
  Result := TryApplyColumnFilter(Filter, CellText);

  // Commit the possibly-transformed value back to the cell
  if Result and (CellText <> GetCellText(ACol, ARow)) then
  begin
    Cells[ACol, ARow] := CellText;
    if EditorMode and Assigned(InplaceEditor) and (ACol = Col) and (ARow = Row) then
      InplaceEditor.Text := CellText;
  end;

  if not Result then
    MessageBeep(MB_ICONWARNING);
end;

// Clears the cell if it fails validation; used before leaving a cell
procedure TMyStringGrid.ClearCellIfInvalid(ACol, ARow: Integer);
begin
  if ApplyFilterToCell(ACol, ARow) then
    Exit;

  Cells[ACol, ARow] := '';
  if EditorMode and Assigned(InplaceEditor) and (ACol = Col) and (ARow = Row) then
    InplaceEditor.Text := '';
end;

procedure TMyStringGrid.SetColumnFilters(const Value: TColumnFilters);
begin
  FColumnFilterItems.Assign(Value);
  EnsureColumnFilterCount;
end;

procedure TMyStringGrid.ColumnFiltersChanged(Sender: TObject);
begin
  if FColumnFilterItems.Count <> ColCount then
    EnsureColumnFilterCount;
  Invalidate;
end;

// Validate the current cell before moving focus to a different cell
function TMyStringGrid.SelectCell(ACol, ARow: Integer): Boolean;
begin
  if (ACol <> Col) or (ARow <> Row) then
    ClearCellIfInvalid(Col, Row);

  Result := inherited SelectCell(ACol, ARow);
end;

procedure TMyStringGrid.KeyPress(var Key: Char);
var
  V: TMyGridKeyValidator;
  VK: Word;
begin
  // Treat Enter and Tab as navigation, not text input
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

  // Only validate keys in the data area, not in fixed header cells
  if (Key <> #0) and (Row >= FixedRows) and (Col >= FixedCols) then
  begin
    EnsureValidatorSize;

    if (Col >= 0) and (Col < Length(FValidators)) then
    begin
      V := FValidators[Col];
      if Assigned(V) then
        V(Self, Col, Row, Key);
      if not Assigned(V) then
        ApplyColumnFilter(Col, Row, Key);
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
    ClearCellIfInvalid(Col, Row);

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

// Draws fixed cells (headers) centered and bold; delegates data cells to the ancestor
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
  EnsureColumnFilterCount;
  UpdateHeaders;
  AutoSizeDataColumns;
end;

procedure TMyStringGrid.SizeChanged(OldColCount, OldRowCount: Integer);
begin
  inherited SizeChanged(OldColCount, OldRowCount);
  EnsureValidatorSize;
  EnsureColumnFilterCount;
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

// Writes header strings into fixed cells; enables fixed rows/cols if headers are provided
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
  // AutoSizeDataColumns; // disabled — resize on demand only
end;

// Distributes available width equally among data columns (minimum 40 px each)
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

  // Give any remaining pixels to the last column
  ColWidths[Last] := Max(Avail - Used, MinW);
end;

end.
