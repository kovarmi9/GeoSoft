unit GeoGrid;

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

  /// <summary>
  /// Defines behavior when navigation reaches last cell.
  /// </summary>
  TEnterEndBehavior = (
    ebStayOnLastCell, // stay on last cell
    ebWrapToStart,    // wrap to first cell
    ebAddRow,         // add new row and move there
    ebMoveFocusNext   // move focus to next control
  );

  /// <summary>
  /// Fired after a cell value is committed (user left the cell).
  /// ACol/ARow identify the cell that was just committed.
  /// </summary>
  TCellCommittedEvent = procedure(Sender: TObject; ACol, ARow: Integer) of object;

  /// <summary>
  /// Asks the form about one cell. Set ASelectable to False for a cell that
  /// is not for typing, it is drawn grey and the cursor skips it.
  /// </summary>
  TCellSelectableEvent = procedure(Sender: TObject; ACol, ARow: Integer;
    var ASelectable: Boolean) of object;

  /// <summary>
  /// Custom inplace editor handling Enter/Tab navigation.
  /// </summary>
  TGeoInplaceEdit = class(TInplaceEdit)
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    /// <summary>
    /// Blocks the Enter key (#13) before it reaches the built-in editor.
    /// Without this, the built-in editor would close itself on Enter
    /// and skip our validation. KeyDown handles navigation instead.
    /// </summary>
    procedure KeyPress(var Key: Char); override;
    /// <summary>Text left after the typed key replaces the selection.</summary>
    function TextWithoutSelection: string;
  end;

  /// <summary>
  /// Custom grid with custom navigation and header support.
  /// </summary>
  TGeoGrid = class(TStringGrid)
  private
    FEnterEndBehavior: TEnterEndBehavior;
    FColumnHeaders: TStrings;
    FRowHeaders: TStrings;
    FOnCellCommitted: TCellCommittedEvent;
    FOnCellSelectable: TCellSelectableEvent;

    FCheckColumn: Integer;            // -1 = no check box column
    FChecked: TArray<Boolean>;        // index 0 is the header "select all"
    FDefaultChecked: Boolean;
    FOnCheckChanged: TNotifyEvent;
    FRowNumbers: Boolean;

    procedure SetRowNumbers(const Value: Boolean);

    procedure SetCheckColumn(const Value: Integer);
    procedure SetDefaultChecked(const Value: Boolean);
    function  GetChecked(ARow: Integer): Boolean;
    procedure SetChecked(ARow: Integer; const Value: Boolean);
    procedure EnsureCheckedLength;
    procedure DrawCheckBox(ARow: Integer; const ARect: TRect);
    procedure OpenEditor;
    procedure WMChar(var Msg: TWMChar); message WM_CHAR;

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);

  protected
    /// <summary>
    /// Set to True by CommitCell when validation fails.
    /// SelectCell reads it to block navigation and reopen the editor.
    /// </summary>
    FLastCommitFailed: Boolean;

    /// <summary>Returns True if cell is header (fixed row/col).</summary>
    function IsHeaderCell(ACol, ARow: Integer): Boolean; virtual;

    /// <summary>Returns True if cell is normal data cell.</summary>
    function IsDataCell(ACol, ARow: Integer): Boolean; virtual;

    /// <summary>Create custom inplace editor.</summary>
    function CreateEditor: TInplaceEdit; override;

    /// <summary>Custom drawing (headers centered + bold).</summary>
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;

    /// <summary>Filter of a column, nil when it has none.</summary>
    function CellFilter(ACol: Integer): TColumnFilter; virtual;

    /// <summary>Intercept Enter/Tab navigation.</summary>
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    /// <summary>Main navigation logic (Enter/Tab behavior).</summary>
    procedure MoveToNextCell(PressedKey: Word; Shift: TShiftState); virtual;

    /// <summary>
    /// Descendants can refuse a cell, the cursor never lands there and no
    /// editor opens on it. Default: every cell is selectable, unless
    /// OnCellSelectable says otherwise.
    /// </summary>
    function CellSelectable(ACol, ARow: Integer): Boolean; virtual;

    /// <summary>
    /// First cell at or after ACol in ARow the cursor may land on. ADelta
    /// is 1 forwards, -1 backwards. ACol is undefined when False.
    /// </summary>
    function SelectableInRow(var ACol: Integer; ARow, ADelta: Integer): Boolean;

    /// <summary>First column of a row the cursor may land on.</summary>
    function FirstSelectableCol(ARow: Integer): Integer;

    /// <summary>
    /// Next cell to the right the cursor may land on, wrapping to the next
    /// row. False at the end of the grid, ACol and ARow are then undefined.
    /// </summary>
    function NextSelectable(var ACol, ARow: Integer): Boolean;

    /// <summary>
    /// Previous cell to the left the cursor may land on, wrapping to the
    /// end of the row above. False at the first cell, ACol and ARow are
    /// then undefined.
    /// </summary>
    function PrevSelectable(var ACol, ARow: Integer): Boolean;

    /// <summary>Esc in the editor, drops the typed text.</summary>
    procedure CancelEdit;

    /// <summary>
    /// Steps one cell back. False at the first cell, so the caller can hand
    /// the focus to the previous control.
    /// </summary>
    function MoveToPrevCell(AOpenEditor: Boolean): Boolean;

    /// <summary>Moves the focus to the next or previous control.</summary>
    procedure LeaveGrid(ABackwards: Boolean);

    /// <summary>
    /// Commits current cell value before leaving it.
    /// Base: writes InplaceEditor.Text into Cells[Col, Row].
    /// Override in descendants to add validation or formatting.
    /// Called automatically before any navigation (Enter, Tab, mouse, arrows).
    /// </summary>
    procedure CommitCell; virtual;

    /// <summary>Fires before every cell change - calls CommitCell.</summary>
    function SelectCell(ACol, ARow: Integer): Boolean; override;

    /// <summary>Apply header texts to grid.</summary>
    procedure UpdateHeaders; virtual;

    /// <summary>Called after component is loaded (DFM).</summary>
    procedure Loaded; override;

    /// <summary>Keeps check box states in step with the rows.</summary>
    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;

    /// <summary>A click in the check box column toggles the box.</summary>
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    /// <summary>The cell as shown: a number rounded by its filter.</summary>
    function DisplayText(ACol, ARow: Integer): string;

    /// <summary>Column header captions. Published by descendants.</summary>
    property ColumnHeaders: TStrings
      read FColumnHeaders write SetColumnHeaders;

    /// <summary>Row header captions. Published by descendants.</summary>
    property RowHeaders: TStrings
      read FRowHeaders write SetRowHeaders;

    /// <summary>
    /// Validates the current cell. Returns True if navigation can proceed,
    /// False if the cell value is invalid and navigation is blocked.
    /// </summary>
    function CommitCurrentCell: Boolean;

    /// <summary>
    /// Beeps and keeps the cursor on the cell, with the editor open.
    /// Used by ciaBlock and by forms that refuse a value from
    /// OnCellCommitted.
    /// </summary>
    procedure RejectCommit;

    /// <summary>
    /// State of the check box on one row. Row 0 is the header box, which
    /// switches all the others.
    /// </summary>
    property Checked[ARow: Integer]: Boolean read GetChecked write SetChecked;

  published
    /// <summary>
    /// Column that shows a check box instead of text, -1 for none. As a
    /// data column the cursor reaches it and Space toggles the box.
    /// </summary>
    property CheckColumn: Integer
      read FCheckColumn write SetCheckColumn default -1;

    /// <summary>All boxes start ticked, a new row takes the header box.</summary>
    property DefaultChecked: Boolean
      read FDefaultChecked write SetDefaultChecked default False;

    /// <summary>Numbers 1, 2, 3 in the header column.</summary>
    property RowNumbers: Boolean
      read FRowNumbers write SetRowNumbers default True;

    /// <summary>Fired after any check box changes.</summary>
    property OnCheckChanged: TNotifyEvent
      read FOnCheckChanged write FOnCheckChanged;

    /// <summary>What Enter or Tab does on the last cell.</summary>
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior
      default ebStayOnLastCell;

    /// <summary>
    /// Fired after the user leaves a cell and its value is committed.
    /// ACol/ARow identify the cell that was just committed.
    /// </summary>
    property OnCellCommitted: TCellCommittedEvent
      read FOnCellCommitted write FOnCellCommitted;

    /// <summary>
    /// Lets the form close single cells, e.g. a value the first row has not.
    /// Whole columns are closed by ReadOnlyFields instead.
    /// </summary>
    property OnCellSelectable: TCellSelectableEvent
      read FOnCellSelectable write FOnCellSelectable;

  end;

implementation

uses
  System.SysUtils;

const
  // Pale grey - a locked cell must still read as data, not as a header
  clReadOnlyCell = TColor($00F4F4F4);

{ TGeoInplaceEdit }

// Blocks Enter (#13), the editor must not close before the check.
// Navigation is handled entirely by KeyDown.
procedure TGeoInplaceEdit.KeyPress(var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    Exit;
  end;
  inherited KeyPress(Key);
end;

// Selected text is replaced by the typed key
function TGeoInplaceEdit.TextWithoutSelection: string;
begin
  Result := Copy(Text, 1, SelStart) +
    Copy(Text, SelStart + SelLength + 1, MaxInt);
end;

// Handle Enter/Tab inside inplace editor
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

{ TGeoGrid }

// Initialize grid options
constructor TGeoGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Options := Options + [goEditing, goTabs, goColSizing, goRowSizing];
  FEnterEndBehavior := ebStayOnLastCell;
  FCheckColumn := -1;
  FRowNumbers := True;
  FColumnHeaders := TStringList.Create;
  FRowHeaders    := TStringList.Create;
end;

destructor TGeoGrid.Destroy;
begin
  FColumnHeaders.Free;
  FRowHeaders.Free;
  inherited Destroy;
end;

function TGeoGrid.IsHeaderCell(ACol, ARow: Integer): Boolean;
begin
  Result := (ACol < FixedCols) or (ARow < FixedRows);
end;

function TGeoGrid.IsDataCell(ACol, ARow: Integer): Boolean;
begin
  Result := not IsHeaderCell(ACol, ARow);
end;

// The descendants have the filters
function TGeoGrid.CellFilter(ACol: Integer): TColumnFilter;
begin
  Result := nil;
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

function TGeoGrid.CreateEditor: TInplaceEdit;
begin
  Result := TGeoInplaceEdit.Create(Self);
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

// No typing into the check box column, Space is handled by KeyDown
procedure TGeoGrid.WMChar(var Msg: TWMChar);
begin
  if Col = FCheckColumn then
    Exit;
  inherited;
end;

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
    else if FRowNumbers and (S = '') and (ACol = 0) and
            (ARow >= FixedRows) then
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
      Canvas.Brush.Color := clReadOnlyCell;
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

// Every key the grid answers itself, the inplace editor forwards them here
procedure TGeoGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  C, D: Integer;
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
    if Key = VK_LEFT then D := -1 else D := 1;
    C := Col + D;
    if SelectableInRow(C, Row, D) then
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
    if ssShift in Shift then
    begin
      if not MoveToPrevCell(Key = VK_RETURN) and (Key = VK_TAB) then
        LeaveGrid(True);
    end
    else
      MoveToNextCell(Key, Shift);
    Key := 0;
    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

function TGeoGrid.CellSelectable(ACol, ARow: Integer): Boolean;
begin
  Result := True;
  // The form may close single cells, the rest stays open
  if Assigned(FOnCellSelectable) then
    FOnCellSelectable(Self, ACol, ARow, Result);
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

// Esc leaves the editor and clears the cell, the same as Delete does on a
// selected cell. The cursor stays, so the next Esc steps back.
procedure TGeoGrid.CancelEdit;
begin
  EditorMode := False;      // HideEdit writes the typed text into the cell
  Cells[Col, Row] := '';    // ... and this throws it away
  FLastCommitFailed := False;
  CommitCell;               // the form recomputes what depended on it
end;

// Esc steps back without opening the editor, Shift+Enter opens it
function TGeoGrid.MoveToPrevCell(AOpenEditor: Boolean): Boolean;
var
  C, R: Integer;
begin
  if EditorMode then
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

procedure TGeoGrid.LeaveGrid(ABackwards: Boolean);
begin
  // PostMessage defers the focus change until this event is handled,
  // WM_NEXTDLGCTL moves focus forward or backward
  PostMessage(GetParentForm(Self).Handle, WM_NEXTDLGCTL, Ord(ABackwards), 0);
end;

// Navigation logic
procedure TGeoGrid.MoveToNextCell(PressedKey: Word; Shift: TShiftState);
var
  C, R: Integer;
  EndBehavior: TEnterEndBehavior;
begin
  // Clamp current position to data area
  if Row < FixedRows then
    Row := FixedRows;
  if Col < FixedCols then
    Col := FixedCols;

  // KeyDown has already committed the cell and stops on failure
  if EditorMode then
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
    if PressedKey = VK_TAB then
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

  // Close editor after Enter
  if PressedKey = VK_RETURN then
    OpenEditor;
end;

procedure TGeoGrid.CommitCell;
begin
  // Base implementation: write editor text into cell
  if EditorMode and Assigned(InplaceEditor) then
    Cells[Col, Row] := InplaceEditor.Text;
  if Assigned(FOnCellCommitted) then
    FOnCellCommitted(Self, Col, Row);
end;

function TGeoGrid.CommitCurrentCell: Boolean;
begin
  // CommitCell sets FLastCommitFailed := True when the value is invalid
  CommitCell;
  Result := not FLastCommitFailed;
  FLastCommitFailed := False;
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
  if (ACol <> Col) or (ARow <> Row) then
  begin
    FLastCommitFailed := False;
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

{ --- Check box column --- }

procedure TGeoGrid.SetCheckColumn(const Value: Integer);
begin
  if FCheckColumn = Value then Exit;
  FCheckColumn := Value;
  EnsureCheckedLength;
  Invalidate;
end;

procedure TGeoGrid.SetDefaultChecked(const Value: Boolean);
var
  I: Integer;
begin
  FDefaultChecked := Value;
  for I := 0 to High(FChecked) do
    FChecked[I] := Value;
  Invalidate;
end;

// A new row takes the header box, the header box itself the default
procedure TGeoGrid.EnsureCheckedLength;
var
  I, OldLength: Integer;
begin
  OldLength := Length(FChecked);
  if OldLength >= RowCount then
    Exit;

  SetLength(FChecked, RowCount);
  for I := OldLength to RowCount - 1 do
    if I = 0 then
      FChecked[I] := FDefaultChecked
    else
      FChecked[I] := FChecked[0];
end;

function TGeoGrid.GetChecked(ARow: Integer): Boolean;
begin
  Result := (ARow >= 0) and (ARow < Length(FChecked)) and FChecked[ARow];
end;

procedure TGeoGrid.SetChecked(ARow: Integer; const Value: Boolean);
begin
  EnsureCheckedLength;
  if (ARow < 0) or (ARow > High(FChecked)) then Exit;
  if FChecked[ARow] = Value then Exit;

  FChecked[ARow] := Value;
  if FCheckColumn >= 0 then
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

procedure TGeoGrid.SizeChanged(OldColCount, OldRowCount: Longint);
begin
  inherited SizeChanged(OldColCount, OldRowCount);
  EnsureCheckedLength;
end;

// A click in the check box column toggles the box instead of moving the
// cursor. The box in the header row switches every other row.
procedure TGeoGrid.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  ACol, ARow, I: Integer;
  NewValue: Boolean;
begin
  if (FCheckColumn >= 0) and (Button = mbLeft) then
  begin
    MouseToCell(X, Y, ACol, ARow);
    if (ACol = FCheckColumn) and (ARow >= 0) then
    begin
      EnsureCheckedLength;

      if ARow < FixedRows then
      begin
        NewValue := not Checked[0];
        for I := 0 to High(FChecked) do
          FChecked[I] := NewValue;
        Invalidate;
        if Assigned(FOnCheckChanged) then
          FOnCheckChanged(Self);
      end
      else
        Checked[ARow] := not Checked[ARow];

      Exit;
    end;
  end;

  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TGeoGrid.SetColumnHeaders(const Value: TStrings);
begin
  FColumnHeaders.Assign(Value);
  UpdateHeaders;
end;

procedure TGeoGrid.SetRowNumbers(const Value: Boolean);
begin
  FRowNumbers := Value;
  Invalidate;
end;

procedure TGeoGrid.SetRowHeaders(const Value: TStrings);
begin
  FRowHeaders.Assign(Value);
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

procedure TGeoGrid.Loaded;
begin
  inherited Loaded;
  // Every grid lets the user resize columns
  Options := Options + [goColSizing];
  UpdateHeaders;
end;

end.
