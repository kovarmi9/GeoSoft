unit MyGrid;

interface

uses
  System.Classes,
  System.Types,
  Vcl.Grids,
  Vcl.Graphics,
  Vcl.Controls;

const
  /// <summary> Default grid options for TMyGrid </summary>
  MyGridDefaultOptions = [
    goFixedVertLine, goFixedHorzLine,
    goVertLine, goHorzLine,
    goRangeSelect,
    goEditing, goTabs,
    goColSizing, goRowSizing
  ];

type
  /// <summary> What to do when Enter/Tab is pressed on the last cell </summary>
  TEnterEndBehavior = (
    ebStayOnLastCell, // stay on cell
    ebWrapToStart,    // jump back to the first data cell
    ebAddRow,         // add a new row and go there
    ebMoveFocusNext   // move focus to the next component on the form
  );

  TMyGrid = class(TStringGrid)
  private
    FColumnHeaders: TStrings;
    FRowHeaders: TStrings;
    FEnterEndBehavior: TEnterEndBehavior;
    FNavigating: Boolean;

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);
    procedure UpdateHeaders;
    procedure MoveToNextCell(APressedKey: Word; AShift: TShiftState);

  protected
    /// <summary>
    ///   Called before the cursor leaves a cell.
    ///   Base: writes InplaceEditor.Text into Cells[Col, Row].
    ///   Override in descendants to add validation or formatting.
    /// </summary>
    procedure CommitCell; virtual;

    function  SelectCell(ACol, ARow: Integer): Boolean; override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    /// <summary> Column header labels (row 0) </summary>
    property ColumnHeaders: TStrings
      read FColumnHeaders write SetColumnHeaders;

    /// <summary> Row header labels (column 0) </summary>
    property RowHeaders: TStrings
      read FRowHeaders write SetRowHeaders;

    /// <summary> What happens when Enter or Tab is pressed on the last cell </summary>
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior
      default ebStayOnLastCell;

    /// <summary> Grid options — editing and sizing enabled by default </summary>
    property Options default MyGridDefaultOptions;
  end;

implementation

uses
  Winapi.Windows;

{ TMyGrid }

constructor TMyGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Options           := MyGridDefaultOptions;
  FColumnHeaders    := TStringList.Create;
  FRowHeaders       := TStringList.Create;
  FEnterEndBehavior := ebStayOnLastCell;
end;

destructor TMyGrid.Destroy;
begin
  FColumnHeaders.Free;
  FRowHeaders.Free;
  inherited Destroy;
end;

procedure TMyGrid.CommitCell;
begin
  // Explicitly save the editor text into the cell before moving away.
  // (SelectCell also calls this, but the explicit call here in KeyDown
  //  ensures the value is committed before navigation changes Col/Row.)
  if EditorMode and Assigned(InplaceEditor) then
    Cells[Col, Row] := InplaceEditor.Text;
end;

function TMyGrid.SelectCell(ACol, ARow: Integer): Boolean;
begin
  // Safety-net commit: fires for every selection change — Enter, Tab,
  // arrow keys, mouse click — so the value is never lost.
  if (ACol <> Col) or (ARow <> Row) then
    CommitCell;

  Result := inherited SelectCell(ACol, ARow);
end;

procedure TMyGrid.SetColumnHeaders(const Value: TStrings);
begin
  FColumnHeaders.Assign(Value);
  UpdateHeaders;
end;

procedure TMyGrid.SetRowHeaders(const Value: TStrings);
begin
  FRowHeaders.Assign(Value);
  UpdateHeaders;
end;

procedure TMyGrid.UpdateHeaders;
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

procedure TMyGrid.MoveToNextCell(APressedKey: Word; AShift: TShiftState);
var
  FirstDataCol, FirstDataRow: Integer;
  GoForward: Boolean;
begin
  FirstDataCol := FixedCols;
  FirstDataRow := FixedRows;

  // Stay inside the data area
  if Row < FirstDataRow then Row := FirstDataRow;
  if Col < FirstDataCol then Col := FirstDataCol;

  if Col < ColCount - 1 then
    Col := Col + 1

  else if Row < RowCount - 1 then
  begin
    Row := Row + 1;
    Col := FirstDataCol;
  end

  else // last cell — apply EnterEndBehavior
  begin
    case FEnterEndBehavior of
      ebStayOnLastCell:
        ;

      ebWrapToStart:
      begin
        Row := FirstDataRow;
        Col := FirstDataCol;
      end;

      ebAddRow:
      begin
        RowCount := RowCount + 1;
        Row      := Row + 1;
        Col      := FirstDataCol;
      end;

      ebMoveFocusNext:
      begin
        EditorMode := False;
        GoForward  := not ((APressedKey = VK_TAB) and (ssShift in AShift));
        SelectNext(Self, GoForward, True);
        Exit; // focus left the grid — skip EditorMode := True below
      end;
    end;
  end;

  // Open the editor at the new cell so the user can type immediately.
  if goEditing in Options then
    EditorMode := True;
end;

procedure TMyGrid.DrawCell(ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
var
  S: string;
  TextX, TextY: Integer;
begin
  if (ARow < FixedRows) or (ACol < FixedCols) then
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

procedure TMyGrid.KeyPress(var Key: Char);
var
  VK: Word;
begin
  if (Key = #13) or (Key = #9) then
  begin
    Key := #0;

    if FNavigating then
      // KeyDown already handled this key press — just reset and exit.
      FNavigating := False
    else
    begin
      // KeyDown was not called (TInplaceEdit did not forward VK_RETURN/VK_TAB).
      // Navigate from this WM_CHAR path, which runs outside the editor lock.
      VK := VK_RETURN;
      KeyDown(VK, []);
      FNavigating := False;
    end;

    Exit;
  end;

  inherited KeyPress(Key);
end;

procedure TMyGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  PressedKey: Word;
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    PressedKey := Key;
    Key        := 0;

    // If FNavigating is already True, this is a duplicate call for the same
    // key press — KeyPress will reset the flag; just exit here.
    if FNavigating then
      Exit;

    FNavigating := True;

    CommitCell;
    MoveToNextCell(PressedKey, Shift);

    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

end.
