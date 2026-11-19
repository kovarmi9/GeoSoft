unit GeoGrid;

// TStringGrid with Enter navigation, filters and check boxes

interface

uses
  System.Classes,
  System.Types,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Grids,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  GeoColumnValidation;

type
  /// <summary>Defines behavior when navigation reaches last cell.</summary>
  TEnterEndBehavior = (
    ebStayOnLastCell, // stay on last cell
    ebWrapToStart,    // wrap to first cell
    ebAddRow,         // add new row and move there
    ebMoveFocusNext   // move focus to next control
  );

  /// <summary>Fired after a cell value is committed.</summary>
  TCellCommittedEvent = procedure(Sender: TObject; ACol, ARow: Integer) of object;

  /// <summary>Asks the form whether a cell is for typing.</summary>
  TCellSelectableEvent = procedure(Sender: TObject; ACol, ARow: Integer; var ASelectable: Boolean) of object;

  /// <summary>Custom inplace editor handling Enter/Tab navigation.</summary>
  TGeoInplaceEdit = class(TInplaceEdit)
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    /// <summary>Blocks Enter and drops keys the column refuses.</summary>
    procedure KeyPress(var Key: Char); override;
    /// <summary>Text left after the typed key replaces the selection.</summary>
    function TextWithoutSelection: string;
  end;

  /// <summary>Grid with Enter navigation, filters and check boxes.</summary>
  TGeoGrid = class(TStringGrid)
  private
    // Moving the cursor
    FEnterEndBehavior: TEnterEndBehavior;
    FOnCellSelectable: TCellSelectableEvent;
    // Committing a cell
    FOnCellCommitted: TCellCommittedEvent;
    FCommitted: Boolean;              // Enter committed it already
    /// <summary>Set by CommitCell when the value is invalid.</summary>
    FLastCommitFailed: Boolean;
    // Column filters
    FColumnFilters: TColumnFilters;   // one per data column
    // Check box column
    FCheckColumn: Integer;            // -1 = no check box column
    FHeaderChecked: Boolean;          // the header "select all" box
    FDefaultChecked: Boolean;
    FOnCheckChanged: TNotifyEvent;
    // Headers
    FColumnHeaders: TStrings;
    FRowHeaders: TStrings;
    FRowNumbers: Boolean;

    // Moving the cursor
    procedure OpenEditor;
    procedure WMChar(var Msg: TWMChar); message WM_CHAR;
    /// <summary>First selectable cell from ACol, ADelta 1 or -1.</summary>
    function SelectableInRow(var ACol: Integer; ARow, ADelta: Integer): Boolean;
    /// <summary>First column of a row the cursor may land on.</summary>
    function FirstSelectableCol(ARow: Integer): Integer;
    /// <summary>Next selectable cell, False at the grid end.</summary>
    function NextSelectable(var ACol, ARow: Integer): Boolean;
    /// <summary>Previous selectable cell, False at the first.</summary>
    function PrevSelectable(var ACol, ARow: Integer): Boolean;
    /// <summary>Steps one cell back, False at the first cell.</summary>
    function MoveToPrevCell(AOpenEditor: Boolean): Boolean;
    /// <summary>Moves the focus to the next or previous control.</summary>
    procedure LeaveGrid(ABackwards: Boolean);
    // Committing a cell
    /// <summary>Esc in the editor, drops the typed text.</summary>
    procedure CancelEdit;
    // Column filters
    procedure SetColumnFilters(const Value: TColumnFilters);
    procedure ColumnFiltersChanged(Sender: TObject);
    // Check box column
    procedure SetCheckColumn(const Value: Integer);
    procedure SetDefaultChecked(const Value: Boolean);
    function GetChecked(ARow: Integer): Boolean;
    procedure SetChecked(ARow: Integer; const Value: Boolean);
    procedure DrawCheckBox(ARow: Integer; const ARect: TRect);
    // Headers
    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);
    procedure SetRowNumbers(const Value: Boolean);

  protected
    // Moving the cursor
    /// <summary>Create custom inplace editor.</summary>
    function CreateEditor: TInplaceEdit; override;
    /// <summary>Every key the grid answers itself.</summary>
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    /// <summary>Main navigation logic (Enter/Tab behavior).</summary>
    procedure MoveToNextCell(AKey: Word); virtual;
    /// <summary>False for a cell the cursor must skip.</summary>
    function CellSelectable(ACol, ARow: Integer): Boolean; virtual;

    // Committing a cell
    /// <summary>Writes the editor text and fires OnCellCommitted.</summary>
    procedure CommitCell; virtual;
    /// <summary>Fires before every cell change - calls CommitCell.</summary>
    function SelectCell(ACol, ARow: Integer): Boolean; override;

    // Column filters
    /// <summary>Filter of a column, nil when it has none.</summary>
    function CellFilter(ACol: Integer): TColumnFilter;
    /// <summary>One filter per data column, filled by descendants.</summary>
    property ColumnFilters: TColumnFilters read FColumnFilters write SetColumnFilters;

    // Drawing
    /// <summary>Returns True if cell is header (fixed row/col).</summary>
    function IsHeaderCell(ACol, ARow: Integer): Boolean; virtual;
    /// <summary>Returns True if cell is normal data cell.</summary>
    function IsDataCell(ACol, ARow: Integer): Boolean; virtual;
    /// <summary>Custom drawing (headers centered + bold).</summary>
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;

    // Check box column
    /// <summary>A click in the check box column toggles the box.</summary>
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    // Headers
    /// <summary>Apply header texts to grid.</summary>
    procedure UpdateHeaders; virtual;
    /// <summary>Called after component is loaded (DFM).</summary>
    procedure Loaded; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Committing a cell
    /// <summary>Commits the cell, False blocks the navigation.</summary>
    function CommitCurrentCell: Boolean;
    /// <summary>Beeps and keeps the editor open on the cell.</summary>
    procedure RejectCommit;

    // Drawing
    /// <summary>The cell as shown: a number rounded by its filter.</summary>
    function DisplayText(ACol, ARow: Integer): string;

    // Check box column
    /// <summary>Check box of a row, kept in its cell as 1 or 0.</summary>
    property Checked[ARow: Integer]: Boolean read GetChecked write SetChecked;

    // Headers
    /// <summary>Column header captions. Published by descendants.</summary>
    property ColumnHeaders: TStrings read FColumnHeaders write SetColumnHeaders;
    /// <summary>Row header captions. Published by descendants.</summary>
    property RowHeaders: TStrings read FRowHeaders write SetRowHeaders;

  published
    // Moving the cursor
    /// <summary>What Enter or Tab does on the last cell.</summary>
    property EnterEndBehavior: TEnterEndBehavior read FEnterEndBehavior write FEnterEndBehavior default ebStayOnLastCell;
    /// <summary>Lets the form close single cells.</summary>
    property OnCellSelectable: TCellSelectableEvent read FOnCellSelectable write FOnCellSelectable;

    // Committing a cell
    /// <summary>Fired after a cell value is committed.</summary>
    property OnCellCommitted: TCellCommittedEvent read FOnCellCommitted write FOnCellCommitted;

    // Check box column
    /// <summary>Check box column, -1 none, set by field grids.</summary>
    property CheckColumn: Integer read FCheckColumn write SetCheckColumn default -1;
    /// <summary>State of a box whose cell is empty.</summary>
    property DefaultChecked: Boolean read FDefaultChecked write SetDefaultChecked default False;
    /// <summary>Fired after any check box changes.</summary>
    property OnCheckChanged: TNotifyEvent read FOnCheckChanged write FOnCheckChanged;

    // Headers
    /// <summary>Numbers 1, 2, 3 in the header column.</summary>
    property RowNumbers: Boolean read FRowNumbers write SetRowNumbers default True;
  end;

implementation

uses
  System.SysUtils;

{ TGeoInplaceEdit }

procedure TGeoInplaceEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    // The grid owns the navigation, the same as it does for Esc
    if Owner is TGeoGrid then
      TGeoGrid(Owner).KeyDown(Key, Shift);
    Key := 0;
    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

// Enter is KeyDown's job, the filter drops other keys
procedure TGeoInplaceEdit.KeyPress(var Key: Char);
var
  Filter: TColumnFilter;
begin
  if Key = #13 then
  begin
    Key := #0;
    Exit;
  end;
  // The column allows only some characters
  if Owner is TGeoGrid then
  begin
    Filter := TGeoGrid(Owner).CellFilter(TGeoGrid(Owner).Col);
    if Filter <> nil then
      FilterKeyPress(Filter, TextWithoutSelection, Key);
  end;
  inherited KeyPress(Key);
end;

// Selected text is replaced by the typed key
function TGeoInplaceEdit.TextWithoutSelection: string;
begin
  Result := Copy(Text, 1, SelStart) +
    Copy(Text, SelStart + SelLength + 1, MaxInt);
end;

{ TGeoGrid }

constructor TGeoGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Options := Options + [goEditing, goTabs, goColSizing, goRowSizing];
  FCheckColumn := -1;
  FRowNumbers := True;
  FColumnHeaders := TStringList.Create;
  FRowHeaders    := TStringList.Create;
  FColumnFilters := TColumnFilters.Create(Self);
  FColumnFilters.OnChanged := ColumnFiltersChanged;
end;

destructor TGeoGrid.Destroy;
begin
  FColumnHeaders.Free;
  FRowHeaders.Free;
  FColumnFilters.Free;
  inherited Destroy;
end;

{ --- Moving the cursor --- }

function TGeoGrid.CreateEditor: TInplaceEdit;
begin
  Result := TGeoInplaceEdit.Create(Self);
end;

// Every key the grid answers itself, the inplace editor forwards them here
procedure TGeoGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  C, Direction: Integer;
begin
  // The inplace editor forwards Esc here, so one branch serves both states
  if Key = VK_ESCAPE then
  begin
    if EditorMode then
      CancelEdit                // first Esc: drop the entry
    else
      MoveToPrevCell(False);    // second Esc: step back, stay in selection
    Key := 0;
    Exit;
  end;

  // Delete clears the cell and keeps the selection, the Windows way
  if (Key = VK_DELETE) and not EditorMode then
  begin
    if CellSelectable(Col, Row) then
    begin
      Cells[Col, Row] := '';
      CommitCell;               // the form recomputes what depended on it
    end;
    Key := 0;
    Exit;
  end;

  // Space toggles the check box the cursor stands on, F2 opens nothing
  if (Col = FCheckColumn) and (Shift = []) and
    ((Key = VK_SPACE) or (Key = VK_F2)) then
  begin
    if Key = VK_SPACE then
      Checked[Row] := not Checked[Row];
    Key := 0;
    Exit;
  end;

  // Arrows must skip locked columns, or the cursor stops dead on them
  // Shift extends the selection and Ctrl scrolls, both belong to the ancestor
  if ((Key = VK_LEFT) or (Key = VK_RIGHT)) and not EditorMode and
    (Shift = []) then
  begin
    if Key = VK_LEFT then Direction := -1 else Direction := 1;
    C := Col + Direction;
    if SelectableInRow(C, Row, Direction) then
      MoveColRow(C, Row, True, True);
    Key := 0;
    Exit;
  end;

  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    // Validate before moving - block the key if commit fails
    if not CommitCurrentCell then
    begin
      Key := 0;
      Exit;
    end;

    // Shift means backwards, at the first cell Tab leaves, Enter stays
    FCommitted := True;
    try
      if ssShift in Shift then
      begin
        if not MoveToPrevCell(Key = VK_RETURN) and (Key = VK_TAB) then
          LeaveGrid(True);
      end
      else
        MoveToNextCell(Key);
    finally
      FCommitted := False;
    end;
    Key := 0;
    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

// No typing into the check box column, Space is handled by KeyDown
procedure TGeoGrid.WMChar(var Msg: TWMChar);
begin
  if Col = FCheckColumn then
    Exit;
  inherited;
end;

procedure TGeoGrid.MoveToNextCell(AKey: Word);
var
  C, R: Integer;
  EndBehavior: TEnterEndBehavior;
begin
  // KeyDown has already committed the cell and stops on failure
  EditorMode := False;

  // Next cell the cursor may land on, refused columns are skipped
  C := Col;
  R := Row;
  if NextSelectable(C, R) then
    MoveColRow(C, R, True, True)

  // Handle movement at the last cell
  else
  begin
    // Tab is a form key and always leaves at the edge, Enter obeys the setting
    if AKey = VK_TAB then
      EndBehavior := ebMoveFocusNext
    else
      EndBehavior := FEnterEndBehavior;

    case EndBehavior of
      ebStayOnLastCell:
        ;                          // already on the last cell we may use

      ebWrapToStart:
        MoveColRow(FirstSelectableCol(FixedRows), FixedRows, True, True);

      ebAddRow:
        begin
          RowCount := RowCount + 1;
          MoveColRow(FirstSelectableCol(Row + 1), Row + 1, True, True);
        end;

      ebMoveFocusNext:
        begin
          LeaveGrid(False);
          Exit;
        end;
    end;
  end;

  // Open the editor after Enter
  if AKey = VK_RETURN then
    OpenEditor;
end;

// Esc steps back without opening the editor, Shift+Enter opens it
function TGeoGrid.MoveToPrevCell(AOpenEditor: Boolean): Boolean;
var
  C, R: Integer;
begin
  EditorMode := False;

  C := Col;
  R := Row;
  Result := PrevSelectable(C, R);
  if not Result then
    Exit;                       // already at the start

  MoveColRow(C, R, True, True);
  if AOpenEditor then
    OpenEditor;
end;

function TGeoGrid.NextSelectable(var ACol, ARow: Integer): Boolean;
begin
  Inc(ACol);
  while ARow < RowCount do
  begin
    if SelectableInRow(ACol, ARow, 1) then
      Exit(True);
    Inc(ARow);
    ACol := FixedCols;
  end;
  Result := False;                // end of grid, the caller decides
end;

function TGeoGrid.PrevSelectable(var ACol, ARow: Integer): Boolean;
begin
  Dec(ACol);
  while ARow >= FixedRows do
  begin
    if SelectableInRow(ACol, ARow, -1) then
      Exit(True);
    Dec(ARow);
    ACol := ColCount - 1;
  end;
  Result := False;                // first cell, nowhere to step back
end;

function TGeoGrid.SelectableInRow(var ACol: Integer; ARow, ADelta: Integer): Boolean;
begin
  while (ACol >= FixedCols) and (ACol < ColCount) and
    not CellSelectable(ACol, ARow) do
    Inc(ACol, ADelta);

  Result := (ACol >= FixedCols) and (ACol < ColCount);
end;

function TGeoGrid.FirstSelectableCol(ARow: Integer): Integer;
begin
  Result := FixedCols;
  if not SelectableInRow(Result, ARow, 1) then
    Result := ColCount - 1;   // whole row locked, land on the last column
end;

function TGeoGrid.CellSelectable(ACol, ARow: Integer): Boolean;
var
  Filter: TColumnFilter;
begin
  Result := True;
  // The form may close single cells, the rest stays open
  if Assigned(FOnCellSelectable) then
    FOnCellSelectable(Self, ACol, ARow, Result);
  // A column the program fills is not for the cursor
  Filter := CellFilter(ACol);
  if Result and (Filter <> nil) and Filter.ReadOnly then
    Result := False;
end;

// Opens the editor, never on the check box column
procedure TGeoGrid.OpenEditor;
begin
  if (goEditing in Options) and (Col <> FCheckColumn) then
  begin
    EditorMode := True;
    InplaceEditor.SelectAll;
  end;
end;

procedure TGeoGrid.LeaveGrid(ABackwards: Boolean);
begin
  // PostMessage defers the focus change until this event is handled,
  // WM_NEXTDLGCTL moves focus forward or backward
  PostMessage(GetParentForm(Self).Handle, WM_NEXTDLGCTL, Ord(ABackwards), 0);
end;

{ --- Committing a cell --- }

function TGeoGrid.CommitCurrentCell: Boolean;
begin
  // CommitCell sets FLastCommitFailed := True when the value is invalid
  CommitCell;
  Result := not FLastCommitFailed;
  FLastCommitFailed := False;
end;

procedure TGeoGrid.CommitCell;
var
  Filter: TColumnFilter;
  Text: string;
begin
  FLastCommitFailed := False;
  if EditorMode and Assigned(InplaceEditor) and not IsHeaderCell(Col, Row) then
  begin
    Text := InplaceEditor.Text;
    Filter := CellFilter(Col);
    if Filter <> nil then
    begin
      // Empty cell takes the default
      if (Trim(Text) = '') and Assigned(Filter.OnGetDefaultText) then
      begin
        Text := '';
        Filter.OnGetDefaultText(Text);
      end;

      if not TryCommitText(Filter, Text) then
      begin
        if Filter.OnInvalidCommit = ciaBlock then
        begin
          RejectCommit;
          Exit;
        end;
        // ciaBeepAndClear, form still recomputes
        Text := '';
        InplaceEditor.Text := '';
        MessageBeep(MB_ICONWARNING);
      end;
    end;
    Cells[Col, Row] := Text;
  end;

  if Assigned(FOnCellCommitted) then
    FOnCellCommitted(Self, Col, Row);
end;

procedure TGeoGrid.RejectCommit;
begin
  MessageBeep(MB_ICONWARNING);
  FLastCommitFailed := True;
end;

function TGeoGrid.SelectCell(ACol, ARow: Integer): Boolean;
begin
  if not CellSelectable(ACol, ARow) then
    Exit(False);

  // Commit current cell before moving (mouse clicks, arrow keys)
  if ((ACol <> Col) or (ARow <> Row)) and not FCommitted then
  begin
    CommitCell;

    // CommitCell failed - block the move and reopen the editor
    if FLastCommitFailed then
    begin
      FLastCommitFailed := False;
      Result := False;
      OpenEditor;
      Exit;
    end;
  end;

  Result := inherited SelectCell(ACol, ARow);
end;

// Esc leaves the editor and clears the cell, the same as Delete does on a
// selected cell. The cursor stays, so the next Esc steps back.
procedure TGeoGrid.CancelEdit;
begin
  EditorMode := False;      // HideEdit writes the typed text into the cell
  Cells[Col, Row] := '';    // ... and this throws it away
  FLastCommitFailed := False;
  CommitCell;               // the form recomputes what depended on it
end;

{ --- Column filters --- }

// Filters start at the first data column
function TGeoGrid.CellFilter(ACol: Integer): TColumnFilter;
var
  I: Integer;
begin
  I := ACol - FixedCols;
  if (I >= 0) and (I < FColumnFilters.Count) then
    Result := FColumnFilters[I]
  else
    Result := nil;
end;

procedure TGeoGrid.SetColumnFilters(const Value: TColumnFilters);
begin
  FColumnFilters.Assign(Value);
end;

// Decimals and ReadOnly change the look
procedure TGeoGrid.ColumnFiltersChanged(Sender: TObject);
begin
  Invalidate;
end;

{ --- Drawing --- }

// Draw header cells centered and bold
procedure TGeoGrid.DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  S: string;
  TextX, TextY: Integer;
  TextArea: TRect;
begin
  if IsHeaderCell(ACol, ARow) then
  begin
    Canvas.Brush.Color := clBtnFace;
    Canvas.Font.Style  := [fsBold];
    Canvas.FillRect(Rect);

    S := Cells[ACol, ARow];
    if ACol = FCheckColumn then
      S := ''                     // no caption, only the box
    else if FRowNumbers and (S = '') and (ACol = 0) and (ARow >= FixedRows) then
      S := IntToStr(ARow - FixedRows + 1);   // only drawn, not in Cells

    TextX := Rect.Left + (Rect.Width  - Canvas.TextWidth(S)) div 2;
    TextY := Rect.Top  + (Rect.Height - Canvas.TextHeight(S)) div 2;
    Canvas.TextRect(Rect, TextX, TextY, S);

    // The form may paint over the header - a checkbox, an icon, ...
    // Called directly: inherited would draw the caption a second time.
    if Assigned(OnDrawCell) then
      OnDrawCell(Self, ACol, ARow, Rect, State);
  end
  else
  begin
    // A cell the cursor cannot reach is not for typing - show it
    if not CellSelectable(ACol, ARow) then
      Canvas.Brush.Color := clWebWhiteSmoke;   // lighter than the header
    S := DisplayText(ACol, ARow);
    if ACol = FCheckColumn then
      S := '';                    // only the box, not the text under it
    // A form that paints cells itself takes DisplayText on its own
    if (S = Cells[ACol, ARow]) or Assigned(OnDrawCell) then
      inherited DrawCell(ACol, ARow, Rect, State)
    else
    begin
      // Delphi would draw the full value, so draw the rounded one here
      DefaultTextDrawing := False;
      try
        inherited DrawCell(ACol, ARow, Rect, State);
      finally
        DefaultTextDrawing := True;
      end;
      TextArea := Rect;
      TextArea.Inflate(-1, -1);
      Canvas.TextRect(TextArea, TextArea.Left + 5,
        TextArea.Top + (TextArea.Height - Canvas.TextHeight(S)) div 2, S);
    end;
  end;

  if ACol = FCheckColumn then
    DrawCheckBox(ARow, Rect);
end;

// The cell keeps the full value, only what is shown is rounded
function TGeoGrid.DisplayText(ACol, ARow: Integer): string;
var
  Filter: TColumnFilter;
  Value: Double;
begin
  Result := Cells[ACol, ARow];
  Filter := CellFilter(ACol);
  if (Filter <> nil) and (Filter.DecimalPlaces >= 0) and
    (Filter.DataType in [cdtFloat, cdtExpression]) and
    TryStrToFloat(Result, Value) then
    Result := FormatDouble(Value, Filter.DecimalPlaces);
end;

function TGeoGrid.IsHeaderCell(ACol, ARow: Integer): Boolean;
begin
  Result := (ACol < FixedCols) or (ARow < FixedRows);
end;

function TGeoGrid.IsDataCell(ACol, ARow: Integer): Boolean;
begin
  Result := not IsHeaderCell(ACol, ARow);
end;

{ --- Check box column --- }

// A click in the check box column toggles the box instead of moving the
// cursor. The box in the header row switches every other row.
procedure TGeoGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ClickCol, ClickRow, I: Integer;
begin
  if (FCheckColumn >= 0) and (Button = mbLeft) then
  begin
    MouseToCell(X, Y, ClickCol, ClickRow);
    if (ClickCol = FCheckColumn) and (ClickRow >= 0) then
    begin
      if ClickRow < FixedRows then
      begin
        FHeaderChecked := not FHeaderChecked;
        for I := FixedRows to RowCount - 1 do
          if FHeaderChecked then
            Cells[FCheckColumn, I] := '1'
          else
            Cells[FCheckColumn, I] := '0';
        Invalidate;
        if Assigned(FOnCheckChanged) then
          FOnCheckChanged(Self);
      end
      else
        Checked[ClickRow] := not Checked[ClickRow];

      Exit;
    end;
  end;

  inherited MouseDown(Button, Shift, X, Y);
end;

// The cell keeps the state, so it moves with its row
function TGeoGrid.GetChecked(ARow: Integer): Boolean;
var
  S: string;
begin
  if ARow < FixedRows then
    Exit(FHeaderChecked);
  if (FCheckColumn < 0) or (ARow >= RowCount) then
    Exit(False);

  S := Cells[FCheckColumn, ARow];
  if S = '' then
    Result := FDefaultChecked     // a new row
  else
    Result := S <> '0';
end;

procedure TGeoGrid.SetChecked(ARow: Integer; const Value: Boolean);
begin
  if (FCheckColumn < 0) or (ARow < FixedRows) or (ARow >= RowCount) then
    Exit;
  if GetChecked(ARow) = Value then
    Exit;

  if Value then
    Cells[FCheckColumn, ARow] := '1'
  else
    Cells[FCheckColumn, ARow] := '0';
  InvalidateCell(FCheckColumn, ARow);
  if Assigned(FOnCheckChanged) then
    FOnCheckChanged(Self);
end;

procedure TGeoGrid.DrawCheckBox(ARow: Integer; const ARect: TRect);
var
  R: TRect;
  Flags: Integer;
begin
  Flags := DFCS_BUTTONCHECK;
  if Checked[ARow] then
    Flags := Flags or DFCS_CHECKED;

  R := ARect;
  InflateRect(R, -4, -4);
  DrawFrameControl(Canvas.Handle, R, DFC_BUTTON, Flags);
end;

procedure TGeoGrid.SetCheckColumn(const Value: Integer);
begin
  if FCheckColumn = Value then Exit;
  FCheckColumn := Value;
  Invalidate;
end;

procedure TGeoGrid.SetDefaultChecked(const Value: Boolean);
begin
  if FDefaultChecked = Value then Exit;   // keeps the header box
  FDefaultChecked := Value;
  FHeaderChecked := Value;
  Invalidate;
end;

{ --- Headers --- }

procedure TGeoGrid.Loaded;
begin
  inherited Loaded;
  // Every grid lets the user resize columns
  Options := Options + [goColSizing];
  UpdateHeaders;
end;

procedure TGeoGrid.UpdateHeaders;
var
  C, R: Integer;
begin
  // Ensure header row exists if column headers are defined
  if (FColumnHeaders.Count > 0) and (FixedRows = 0) then
    FixedRows := 1;

  // Ensure header column exists if row headers are defined
  if (FRowHeaders.Count > 0) and (FixedCols = 0) then
    FixedCols := 1;

  // Fill column headers
  if FixedRows > 0 then
    for C := 0 to ColCount - 1 do
      if C < FColumnHeaders.Count then
        Cells[C, 0] := FColumnHeaders[C];

  // Fill row headers
  if FixedCols > 0 then
    for R := 0 to RowCount - 1 do
      if R < FRowHeaders.Count then
        Cells[0, R] := FRowHeaders[R];
end;

procedure TGeoGrid.SetColumnHeaders(const Value: TStrings);
begin
  FColumnHeaders.Assign(Value);
  UpdateHeaders;
end;

procedure TGeoGrid.SetRowHeaders(const Value: TStrings);
begin
  FRowHeaders.Assign(Value);
  UpdateHeaders;
end;

procedure TGeoGrid.SetRowNumbers(const Value: Boolean);
begin
  FRowNumbers := Value;
  Invalidate;
end;

end.
