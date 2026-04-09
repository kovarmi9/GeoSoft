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
    // Set to True inside KeyDown so KeyPress knows navigation already happened
    // and does not trigger a second move (double-skip prevention).
    FNavigating: Boolean;

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);
    procedure UpdateHeaders;

  protected
    /// <summary>
    ///   Called whenever the cursor is about to leave a cell.
    ///   Base: writes InplaceEditor.Text into Cells[Col, Row] (the commit).
    ///   Override in descendants to add validation or formatting.
    /// </summary>
    procedure CommitCell; virtual;

    function  SelectCell(ACol, ARow: Integer): Boolean; override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState); override;
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
  // Write whatever is currently in the in-place editor into the cell.
  // InplaceEditor.Text holds the live text while editing; Cells[Col,Row]
  // is only updated when the editor closes — so we do it explicitly here.
  if EditorMode and Assigned(InplaceEditor) then
    Cells[Col, Row] := InplaceEditor.Text;
end;

function TMyGrid.SelectCell(ACol, ARow: Integer): Boolean;
begin
  // Commit the current cell before moving to a new one.
  // This fires for every selection change: Enter, Tab, arrows, mouse click.
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

  for C := 0 to FColumnHeaders.Count - 1 do
    if C < ColCount then
      Cells[C, 0] := FColumnHeaders[C];

  for R := 0 to FRowHeaders.Count - 1 do
    if R < RowCount then
      Cells[0, R] := FRowHeaders[R];

  Invalidate;
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

    // If KeyDown already handled this key press (called via TInplaceEdit's
    // forwarded WM_KEYDOWN), just reset the flag and exit — no second move.
    // If KeyDown was NOT called (some Delphi versions do not forward VK_RETURN
    // from TInplaceEdit to Grid.KeyDown), call it now from this WM_CHAR path,
    // which runs outside the TInplaceEdit editor-lock — navigation works here.
    if FNavigating then
      FNavigating := False
    else
    begin
      VK := VK_RETURN;
      KeyDown(VK, []);
      FNavigating := False; // reset after KeyDown sets it
    end;

    Exit;
  end;

  inherited KeyPress(Key);
end;

procedure TMyGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    Key := 0;

    // Guard: if we are already navigating (called a second time for the same
    // key press), do nothing. KeyPress will reset FNavigating afterwards.
    if FNavigating then
      Exit;

    FNavigating := True;

    if Col < ColCount - 1 then
      Col := Col + 1

    else if Row < RowCount - 1 then
    begin
      Row := Row + 1;
      Col := FixedCols;
    end

    else
    begin
      case FEnterEndBehavior of
        ebStayOnLastCell:
          ;

        ebWrapToStart:
        begin
          Row := FixedRows;
          Col := FixedCols;
        end;

        ebAddRow:
        begin
          RowCount := RowCount + 1;
          Row      := Row + 1;
          Col      := FixedCols;
        end;

        ebMoveFocusNext:
        begin
          EditorMode := False;
          SelectNext(Self, True, True);
          FNavigating := False;
          Exit;
        end;
      end;
    end;

    // Reopen the editor in the new cell so the user can keep typing.
    if goEditing in Options then
      EditorMode := True;

    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

end.
