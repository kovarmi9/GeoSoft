unit MyGrid;

interface

uses
  System.Classes,
  System.Types,
  Vcl.Grids,
  Vcl.Graphics;

type
  TMyGrid = class(TStringGrid)
  private
    FColumnHeaders: TStrings;
    FRowHeaders: TStrings;

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);
    procedure UpdateHeaders;

  protected
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState); override;

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
  end;

implementation

constructor TMyGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColumnHeaders := TStringList.Create;
  FRowHeaders    := TStringList.Create;
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
  // If we have column headers, we need at least one fixed row
  if (FColumnHeaders.Count > 0) and (FixedRows = 0) then
    FixedRows := 1;

  // If we have row headers, we need at least one fixed column
  if (FRowHeaders.Count > 0) and (FixedCols = 0) then
    FixedCols := 1;

  // Write column headers into row 0
  for C := 0 to FColumnHeaders.Count - 1 do
    if C < ColCount then
      Cells[C, 0] := FColumnHeaders[C];

  // Write row headers into column 0
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
  // Header cells (fixed rows or fixed columns)
  if (ARow < FixedRows) or (ACol < FixedCols) then
  begin
    Canvas.Brush.Color := clBtnFace;  // grey background
    Canvas.Font.Style  := [fsBold];   // bold text
    Canvas.FillRect(Rect);

    // Center the text in the cell
    S     := Cells[ACol, ARow];
    TextX := Rect.Left + (Rect.Width  - Canvas.TextWidth(S))  div 2;
    TextY := Rect.Top  + (Rect.Height - Canvas.TextHeight(S)) div 2;
    Canvas.TextRect(Rect, TextX, TextY, S);
  end
  else
    inherited DrawCell(ACol, ARow, Rect, State); // data cells — default
end;

end.

