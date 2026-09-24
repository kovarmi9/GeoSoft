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
  Vcl.Forms;
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

    FCheckColumn: Integer;            // -1 = no check box column
    FChecked: TArray<Boolean>;        // index 0 is the header "select all"
    FOnCheckChanged: TNotifyEvent;

    procedure SetCheckColumn(const Value: Integer);
    function  GetChecked(ARow: Integer): Boolean;
    procedure SetChecked(ARow: Integer; const Value: Boolean);
    procedure EnsureCheckedLength;
    procedure DrawCheckBox(ARow: Integer; const ARect: TRect);

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

    /// <summary>Intercept Enter/Tab navigation.</summary>
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    /// <summary>Main navigation logic (Enter/Tab behavior).</summary>
    procedure MoveToNextCell(PressedKey: Word; Shift: TShiftState); virtual;

    /// <summary>
    /// Descendants can refuse a cell; the cursor never lands there and no
    /// editor opens on it. Default: every cell is selectable.
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
    /// row. False at the end of the grid; ACol and ARow are then undefined.
    /// </summary>
    function NextSelectable(var ACol, ARow: Integer): Boolean;

    /// <summary>
    /// Previous cell to the left the cursor may land on, wrapping to the
    /// end of the row above. False at the first cell; ACol and ARow are
    /// then undefined.
    /// </summary>
    function PrevSelectable(var ACol, ARow: Integer): Boolean;

    /// <summary>Esc in the editor: drop what was typed, keep the cell.</summary>
    procedure CancelEdit;

    /// <summary>
    /// Steps one cell back. False at the first cell, so the caller can hand
    /// the focus to the previous control.
    /// </summary>
    function MoveToPrevCell(AOpenEditor: Boolean): Boolean;

    /// <summary>Hands the focus to the next or previous control on the form.</summary>
    procedure LeaveGrid(ABackwards: Boolean);

    /// <summary>
    /// Commits current cell value before leaving it.
    /// Base: writes InplaceEditor.Text into Cells[Col, Row].
    /// Override in descendants to add validation or formatting.
    /// Called automatically before any navigation (Enter, Tab, mouse, arrows).
    /// </summary>
    procedure CommitCell; virtual;

    /// <summary>Fires before every cell change — calls CommitCell.</summary>
    function SelectCell(ACol, ARow: Integer): Boolean; override;

    /// <summary>Apply header texts to grid.</summary>
    procedure UpdateHeaders; virtual;

    /// <summary>Called after component is loaded (DFM).</summary>
    procedure Loaded; override;

    /// <summary>Keeps the check box states in step with the row count.</summary>
    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;

    /// <summary>A click in the check box column toggles instead of selecting.</summary>
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

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
    /// Column that shows a check box instead of text, -1 for none. Make it
    /// a fixed column when the flag is not part of the data.
    /// </summary>
    property CheckColumn: Integer
      read FCheckColumn write SetCheckColumn default -1;

    /// <summary>Fired after any check box changes.</summary>
    property OnCheckChanged: TNotifyEvent
      read FOnCheckChanged write FOnCheckChanged;

    /// <summary>What happens when Enter or Tab is pressed on the last cell.</summary>
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior
      default ebStayOnLastCell;

    /// <summary>
    /// Fired after the user leaves a cell and its value is committed.
    /// ACol/ARow identify the cell that was just committed.
    /// </summary>
    property OnCellCommitted: TCellCommittedEvent
      read FOnCellCommitted write FOnCellCommitted;

  end;

implementation

const
  // Pale grey - a locked cell must still read as data, not as a header
  clReadOnlyCell = TColor($00F4F4F4);

{ TGeoInplaceEdit }

// Blocks Enter (#13) so the built-in editor cannot close before validation runs.
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

function TGeoGrid.CreateEditor: TInplaceEdit;
begin
  Result := TGeoInplaceEdit.Create(Self);
end;

// Draw header cells centered and bold
procedure TGeoGrid.DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  S: string;
  TextX, TextY: Integer;
begin
  if IsHeaderCell(ACol, ARow) then
  begin
    Canvas.Brush.Color := clBtnFace;
    Canvas.Font.Style  := [fsBold];
    Canvas.FillRect(Rect);

    S := Cells[ACol, ARow];

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
    inherited DrawCell(ACol, ARow, Rect, State);
  end;

  if ACol = FCheckColumn then
    DrawCheckBox(ARow, Rect);
end;

// Every key the grid answers itself; the inplace editor forwards them here
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

  // Space toggles the row's check box where the cell cannot be typed into
  if (Key = VK_SPACE) and (Shift = []) and not EditorMode and
     (FCheckColumn >= 0) and not (goEditing in Options) then
  begin
    Checked[Row] := not Checked[Row];
    Key := 0;
    Exit;
  end;

  // Arrows must skip locked columns, or the cursor stops dead on them
  // Shift extends the selection and Ctrl scrolls, both belong to the ancestor
  if ((Key = VK_LEFT) or (Key = VK_RIGHT)) and not EditorMode and (Shift = []) then
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
    // Validate before moving — block the key if commit fails
    if not CommitCurrentCell then
    begin
      Key := 0;
      Exit;
    end;

    // Shift means backwards; at the first cell Tab leaves, Enter stays
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
  if AOpenEditor and (goEditing in Options) then
    EditorMode := True;
end;

procedure TGeoGrid.LeaveGrid(ABackwards: Boolean);
begin
  // PostMessage defers the focus change until this event is handled;
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

  // Next cell the cursor may land on; refused columns are skipped
  C := Col;
  R := Row;
  if NextSelectable(C, R) then
    MoveColRow(C, R, True, True)

  // Handle movement at the last cell
  else
  begin
    // Tab is a form key, so at the edge it always leaves; Enter obeys the setting
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
  if (PressedKey = VK_RETURN) and (goEditing in Options) then
    EditorMode := True;
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

    // CommitCell failed — block the move and reopen the editor
    if FLastCommitFailed then
    begin
      FLastCommitFailed := False;
      Result := False;
      if goEditing in Options then
        EditorMode := True;
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

procedure TGeoGrid.EnsureCheckedLength;
begin
  if Length(FChecked) < RowCount then
    SetLength(FChecked, RowCount);
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
  UpdateHeaders;
end;

end.
