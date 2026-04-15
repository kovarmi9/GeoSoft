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
  /// Custom inplace editor handling Enter/Tab navigation.
  /// </summary>
  TGeoInplaceEdit = class(TInplaceEdit)
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  end;

  /// <summary>
  /// Custom grid with custom navigation and header support.
  /// </summary>
  TGeoGrid = class(TStringGrid)
  private
    FEnterEndBehavior: TEnterEndBehavior;
    FColumnHeaders: TStrings;
    FRowHeaders: TStrings;

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);

  protected
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

    /// <summary>Apply header texts to grid.</summary>
    procedure UpdateHeaders; virtual;

    /// <summary>Called after component is loaded (DFM).</summary>
    procedure Loaded; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

  published
    /// <summary>Custom grid with custom navigation and header support.</summary>
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior
      default ebStayOnLastCell;

    /// <summary>Column header captions.</summary>
    property ColumnHeaders: TStrings
      read FColumnHeaders write SetColumnHeaders;

    /// <summary>Row header captions.</summary>
    property RowHeaders: TStrings
      read FRowHeaders write SetRowHeaders;

  end;

implementation

{ TGeoInplaceEdit }

// Handle Enter/Tab inside inplace editor
procedure TGeoInplaceEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    if Owner is TGeoGrid then
      TGeoGrid(Owner).MoveToNextCell(Key, Shift);

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

// Destructor
destructor TGeoGrid.Destroy;
begin
  FColumnHeaders.Free;
  FRowHeaders.Free;
  inherited Destroy;
end;

// True for fixed/header cells
function TGeoGrid.IsHeaderCell(ACol, ARow: Integer): Boolean;
begin
  Result := (ACol < FixedCols) or (ARow < FixedRows);
end;

// True for normal data cells
function TGeoGrid.IsDataCell(ACol, ARow: Integer): Boolean;
begin
  Result := not IsHeaderCell(ACol, ARow);
end;

// Create custom editor with enter switch in inplace editor
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

    S     := Cells[ACol, ARow];
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
          // Keep selection on last cell
          Row := RowCount - 1;
          Col := ColCount - 1;
        end;

      ebWrapToStart:
        begin
          // Jump back to first data cell
          Row := FirstDataRow;
          Col := FirstDataCol;
        end;

      ebAddRow:
        begin
          // Add one row and move to its first data cell
          RowCount := RowCount + 1;
          Row := Row + 1;
          Col := FirstDataCol;
        end;

      ebMoveFocusNext:
        begin
          // Leave grid and move focus by tab order
          //
          // Unlike SendMessage PostMesage wait until other actions are done
          //
          // GetParentForm(Self).Handle -> message must be sent to the parent form
          //
          // WM_NEXTDLGCTL = standard Windows message for Tab navigation
          //
          // Ord(ssShift in Shift) -> direction:
          //   move forward  like Tab
          //   move backward Shift+Tab
          //
          // 0 -> use tab order navigation
          //
          PostMessage(GetParentForm(Self).Handle, WM_NEXTDLGCTL, Ord(ssShift in Shift), 0);
          Exit;
        end;
    end;
  end;

  // Close editor after Enter
  if (PressedKey = VK_RETURN) and (goEditing in Options) then
    EditorMode := True;
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
