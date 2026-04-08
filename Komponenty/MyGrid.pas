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

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);
    procedure UpdateHeaders;

  protected
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
  if Key = #13 then
  begin
    Key := #0;
    VK  := VK_RETURN;
    KeyDown(VK, []);
    Exit;
  end;

  if Key = #9 then
  begin
    Key := #0;
    VK  := VK_TAB;
    KeyDown(VK, []);
    Exit;
  end;

  inherited KeyPress(Key);
end;

procedure TMyGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    Key := 0;

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
        end;
      end;
    end;

    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

end.
