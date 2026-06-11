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

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    /// <summary>
    /// Validates the current cell. Returns True if navigation can proceed,
    /// False if the cell value is invalid and navigation is blocked.
    /// </summary>
    function CommitCurrentCell: Boolean;

  published
    /// <summary>What happens when Enter or Tab is pressed on the last cell.</summary>
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior
      default ebStayOnLastCell;

    /// <summary>Column header captions.</summary>
    property ColumnHeaders: TStrings
      read FColumnHeaders write SetColumnHeaders;

    /// <summary>Row header captions.</summary>
    property RowHeaders: TStrings
      read FRowHeaders write SetRowHeaders;

    /// <summary>
    /// Fired after the user leaves a cell and its value is committed.
    /// ACol/ARow identify the cell that was just committed.
    /// </summary>
    property OnCellCommitted: TCellCommittedEvent
      read FOnCellCommitted write FOnCellCommitted;

  end;

implementation

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
  end
  else
    inherited DrawCell(ACol, ARow, Rect, State);
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

// Navigation logic
procedure TGeoGrid.MoveToNextCell(PressedKey: Word; Shift: TShiftState);
var
  FirstDataCol, FirstDataRow: Integer;
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

  // Move to the next column in current row
  if Col < ColCount - 1 then
    Col := Col + 1

  // Move to the first data column of next row
  else if Row < RowCount - 1 then
  begin
    Row := Row + 1;
    Col := FirstDataCol;
  end

  // Handle movement at the last cell
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

function TGeoGrid.SelectCell(ACol, ARow: Integer): Boolean;
begin
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
