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

    /// <summary>First column of a row the cursor may land on.</summary>
    function FirstSelectableCol(ARow: Integer): Integer;

    /// <summary>
    /// Next cell to the right the cursor may land on, wrapping to the next
    /// row. False at the end of the grid.
    /// </summary>
    function NextSelectable(var ACol, ARow: Integer): Boolean;

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
    if Owner is TGeoGrid then
    begin
      // Validate before moving — if commit fails, stay on current cell
      if not TGeoGrid(Owner).CommitCurrentCell then
      begin
        Key := 0;
        Exit;
      end;
      TGeoGrid(Owner).MoveToNextCell(Key, Shift);
    end;

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

// Handle Enter/Tab inside grid
procedure TGeoGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    // Validate before moving — block the key if commit fails
    if not CommitCurrentCell then
    begin
      Key := 0;
      Exit;
    end;
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

function TGeoGrid.FirstSelectableCol(ARow: Integer): Integer;
begin
  Result := FixedCols;
  while (Result < ColCount - 1) and not CellSelectable(Result, ARow) do
    Inc(Result);
end;

function TGeoGrid.NextSelectable(var ACol, ARow: Integer): Boolean;
var
  Guard: Integer;
begin
  Guard := ColCount * RowCount;   // never loop over the whole grid twice

  repeat
    if ACol < ColCount - 1 then
      Inc(ACol)
    else if ARow < RowCount - 1 then
    begin
      Inc(ARow);
      ACol := FixedCols;
    end
    else
      Exit(False);                // end of grid, the caller decides

    Dec(Guard);
  until CellSelectable(ACol, ARow) or (Guard <= 0);

  Result := CellSelectable(ACol, ARow);
end;

// Navigation logic
procedure TGeoGrid.MoveToNextCell(PressedKey: Word; Shift: TShiftState);
var
  FirstDataCol, FirstDataRow, C, R: Integer;
begin
  // First editable cell position
  FirstDataCol := FixedCols;
  FirstDataRow := FixedRows;

  // Clamp current position to data area
  if Row < FirstDataRow then
    Row := FirstDataRow;
  if Col < FirstDataCol then
    Col := FirstDataCol;

  // Commit current value before closing editor
  CommitCell;

  // CommitCell set FLastCommitFailed — stay on current cell and reopen editor
  if FLastCommitFailed then
  begin
    FLastCommitFailed := False;
    if goEditing in Options then
      EditorMode := True;
    Exit;
  end;

  // Close editor before moving
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
    case FEnterEndBehavior of
      ebStayOnLastCell:
        ;                          // already on the last cell we may use

      ebWrapToStart:
        MoveColRow(FirstSelectableCol(FirstDataRow), FirstDataRow, True, True);

      ebAddRow:
        begin
          RowCount := RowCount + 1;
          MoveColRow(FirstSelectableCol(Row + 1), Row + 1, True, True);
        end;

      ebMoveFocusNext:
        begin
          // PostMessage defers focus change until current event handling is done;
          // WM_NEXTDLGCTL moves focus forward (Tab) or backward (Shift+Tab)
          PostMessage(GetParentForm(Self).Handle, WM_NEXTDLGCTL, Ord(ssShift in Shift), 0);
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
