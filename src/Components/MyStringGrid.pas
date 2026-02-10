unit MyStringGrid;

interface

uses
  System.Classes,  // TComponent, TStrings, TStringList
  System.Types,    // TRect
  System.Math,     // Max()
  System.SysUtils, // CharInSet, StrToIntDef, Trim...
  Vcl.Controls,    // TShiftState...
  Vcl.Grids;       // TStringGrid...

type
  // Co má grid udělat, když uživatel stiskne Enter/Tab v poslední datové buňce
  TEnterEndBehavior = (ebWrapToStart, ebAddRow);

  // Validátor buněk (normální procedura, NE metoda objektu)
  TMyGridKeyValidator = procedure(AGrid: TObject; ACol, ARow: Integer; var Key: Char);

  TMyStringGrid = class(TStringGrid)
  private
	// Jak se zachovat, když Enter/Tab na konci tabulky
    FEnterEndBehavior: TEnterEndBehavior;

    FColumnHeaders: TStrings;
    FRowHeaders: TStrings;

    // Pole validátorů pro sloupce
    FValidators: array of TMyGridKeyValidator;

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);
    procedure UpdateHeaders;
    procedure AutoSizeDataColumns;

    procedure EnsureValidatorSize;

  protected
    procedure Loaded; override;
    procedure Resize; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

	// Nastavení validátoru sloupce
    procedure SetColumnValidator(ACol: Integer; AValidator: TMyGridKeyValidator);
    procedure ClearColumnValidator(ACol: Integer);
    procedure ClearAllValidators;

  published
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior default ebWrapToStart;

    property ColumnHeaders: TStrings
      read FColumnHeaders write SetColumnHeaders;

    property RowHeaders: TStrings
      read FRowHeaders write SetRowHeaders;
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Graphics;

{ TMyStringGrid }

constructor TMyStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Options := Options + [goEditing, goTabs];
  FEnterEndBehavior := ebWrapToStart;

  FColumnHeaders := TStringList.Create;
  FRowHeaders    := TStringList.Create;

  EnsureValidatorSize;
end;

destructor TMyStringGrid.Destroy;
begin
  FColumnHeaders.Free;
  FRowHeaders.Free;
  inherited Destroy;
end;

procedure TMyStringGrid.EnsureValidatorSize;
begin
  // drží pole validátorů stejně dlouhé jako ColCount
  if Length(FValidators) <> ColCount then
    SetLength(FValidators, ColCount);
end;

procedure TMyStringGrid.ClearAllValidators;
var
  i: Integer;
begin
  EnsureValidatorSize;
  for i := 0 to High(FValidators) do
    FValidators[i] := nil;
end;

procedure TMyStringGrid.SetColumnValidator(ACol: Integer; AValidator: TMyGridKeyValidator);
begin
  EnsureValidatorSize;
  // pokud je index sloupce platný, přiřadí tomuto sloupci konkrétní validační metodu
  if (ACol >= 0) and (ACol < Length(FValidators)) then
    FValidators[ACol] := AValidator;
end;

procedure TMyStringGrid.ClearColumnValidator(ACol: Integer);
begin
  EnsureValidatorSize;
  // pokud je index sloupce platný, zruší validaci pro daný sloupec
  if (ACol >= 0) and (ACol < Length(FValidators)) then
    FValidators[ACol] := nil;
end;

procedure TMyStringGrid.KeyPress(var Key: Char);
var
  V: TMyGridKeyValidator;
  VK: Word;
begin
  // Enter/Tab řešíme jako navigaci (KeyDown), ne jako psaní znaku
  if Key = #13 then
  begin
    Key := #0;
    VK := VK_RETURN;
    KeyDown(VK, []);
    Exit;
  end;

  if Key = #9 then
  begin
    Key := #0;
    VK := VK_TAB;
    KeyDown(VK, []);
    Exit;
  end;

  // validujeme jen v datové části (ne hlavičky)
  if (Key <> #0) and (Row >= FixedRows) and (Col >= FixedCols) then
  begin
    EnsureValidatorSize;

    if (Col >= 0) and (Col < Length(FValidators)) then
    begin
      V := FValidators[Col];
      if Assigned(V) then
        V(Self, Col, Row, Key); // validátor může Key "sežrat" => Key := #0
    end;
  end;

  if Key = #0 then
    Exit;

  inherited KeyPress(Key);
end;

procedure TMyStringGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  FirstDataCol, FirstDataRow: Integer;
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    Key := 0;

    FirstDataCol := FixedCols;
    FirstDataRow := FixedRows;

    if Row < FirstDataRow then Row := FirstDataRow;
    if Col < FirstDataCol then Col := FirstDataCol;

    if Col < ColCount - 1 then
      Col := Col + 1
    else if Row < RowCount - 1 then
    begin
      Row := Row + 1;
      Col := FirstDataCol;
    end
    else
    begin
      case FEnterEndBehavior of
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
      end;
    end;

    if goEditing in Options then
      EditorMode := True;

    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

procedure TMyStringGrid.DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  S: string;
  X, Y: Integer;
  SavedDC: Integer;
begin
  if (ARow < FixedRows) or (ACol < FixedCols) then
  begin
    SavedDC := SaveDC(Canvas.Handle);
    try
      Canvas.Brush.Color := clBtnFace;
      Canvas.Font.Style := [fsBold];
      Canvas.FillRect(Rect);

      S := Cells[ACol, ARow];
      X := Rect.Left + (Rect.Width  - Canvas.TextWidth(S))  div 2;
      Y := Rect.Top  + (Rect.Height - Canvas.TextHeight(S)) div 2;
      Canvas.TextRect(Rect, X, Y, S);
    finally
      RestoreDC(Canvas.Handle, SavedDC);
    end;
  end
  else
    inherited DrawCell(ACol, ARow, Rect, State);
end;

procedure TMyStringGrid.Loaded;
begin
  inherited;
  UpdateHeaders;
  AutoSizeDataColumns;
end;

procedure TMyStringGrid.SetColumnHeaders(const Value: TStrings);
begin
  FColumnHeaders.Assign(Value);
  UpdateHeaders;
end;

procedure TMyStringGrid.SetRowHeaders(const Value: TStrings);
begin
  FRowHeaders.Assign(Value);
  UpdateHeaders;
end;

procedure TMyStringGrid.UpdateHeaders;
// Promítnutí názvů do hlaviček gridů
var
  c, r: Integer;
begin
  if (FColumnHeaders.Count > 0) and (FixedRows = 0) then
    FixedRows := 1;
  if (FRowHeaders.Count > 0) and (FixedCols = 0) then
    FixedCols := 1;

  if FixedRows > 0 then
    for c := 0 to ColCount - 1 do
      if c < FColumnHeaders.Count then
        Cells[c, 0] := FColumnHeaders[c];

  if FixedCols > 0 then
    for r := 0 to RowCount - 1 do
      if r < FRowHeaders.Count then
        Cells[0, r] := FRowHeaders[r];

  Invalidate;
end;

procedure TMyStringGrid.Resize;
begin
  inherited;
  // AutoSizeDataColumns;
end;

procedure TMyStringGrid.AutoSizeDataColumns;
// dynamické nastavení šířky tabulky podle okna... nepoužívám
var
  c, DataCols, Avail, FixedW, Base, Extra, MinW, Used, Last: Integer;
begin
  if ColCount = 0 then Exit;

  FixedW := 0;
  for c := 0 to FixedCols - 1 do
    Inc(FixedW, ColWidths[c]);

  DataCols := ColCount - FixedCols;
  if DataCols <= 0 then Exit;

  Avail := ClientWidth - FixedW - GridLineWidth * (DataCols);
  if Avail <= 0 then Exit;

  MinW := 40;
  Base  := Avail div DataCols;
  Extra := Avail mod DataCols;

  Used := 0;
  Last := ColCount - 1;

  for c := FixedCols to Last - 1 do
  begin
    ColWidths[c] := Max(Base + Ord((c - FixedCols) < Extra), MinW);
    Inc(Used, ColWidths[c]);
  end;

  ColWidths[Last] := Max(Avail - Used, MinW);
end;

end.

