unit MyStringGrid;

interface

uses
  System.Classes,  // TComponent, TStrings, TStringList
  System.Types,    // TRect
  System.Math,     // Max()
  System.SysUtils, // CharInSet, StrToIntDef, Trim, FormatSettings...
  Vcl.Controls,    // TShiftState...
  Vcl.Grids;       // TStringGrid...

type
  // Co má grid udělat, když uživatel stiskne Enter/Tab v poslední datové buňce
  TEnterEndBehavior = (ebWrapToStart, ebAddRow);// skočí zpět/přidá řádek

  // Validátor buněk (of object aby šla metoda instance)
  TMyGridKeyValidator = procedure(AGrid: TObject; ACol, ARow: Integer; var Key: Char) of object;

  TMyStringGrid = class(TStringGrid)
  private
    // Jak se zachovat, když Enter/Tab na konci tabulky
    FEnterEndBehavior: TEnterEndBehavior;

    FColumnHeaders: TStrings;
    FRowHeaders: TStrings;

    // Pole validátorů
    FValidators: array of TMyGridKeyValidator;

    // Uložení nastavení validací
    FColumnValidatorNames: TStrings;

    procedure SetColumnHeaders(const Value: TStrings);
    procedure SetRowHeaders(const Value: TStrings);
    procedure UpdateHeaders;
    procedure AutoSizeDataColumns;

    procedure EnsureValidatorSize;
    procedure ApplyValidatorNames;
    procedure SetColumnValidatorNames(const Value: TStrings);

  protected
    procedure Loaded; override;
    procedure Resize; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override; // <<< tady se validuje psaní
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Programové nastavení validátoru sloupce
    procedure SetColumnValidator(ACol: Integer; AValidator: TMyGridKeyValidator);
    procedure ClearColumnValidator(ACol: Integer);

  published
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior default ebWrapToStart;

    property ColumnHeaders: TStrings
      read FColumnHeaders write SetColumnHeaders;

    property RowHeaders: TStrings
      read FRowHeaders write SetRowHeaders;

    // V Object Inspectoru můžeš napsat např.:
    // 0=StationPointNoKey
    // 2=OnlyNumberWithCommaKey
    property ColumnValidatorNames: TStrings
      read FColumnValidatorNames write SetColumnValidatorNames;
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

  FColumnValidatorNames := TStringList.Create;

  EnsureValidatorSize;
end;

destructor TMyStringGrid.Destroy;
begin
  FColumnHeaders.Free;
  FRowHeaders.Free;
  FColumnValidatorNames.Free;
  inherited Destroy;
end;

procedure TMyStringGrid.EnsureValidatorSize;
begin
  // drží pole validátorů stejně dlouhé jako ColCount
  if Length(FValidators) <> ColCount then
    SetLength(FValidators, ColCount);
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

procedure TMyStringGrid.SetColumnValidatorNames(const Value: TStrings);
begin
  // zkopíruje seznam z Object Inspectoru do interního seznamu komponenty
  FColumnValidatorNames.Assign(Value);

  // pokusí se najít odpovídající metody a napojit je jako validátory pro konkrétní sloupce
  ApplyValidatorNames;
end;

procedure TMyStringGrid.ApplyValidatorNames;
var
  i, eqPos, col: Integer;
  line, colStr, methName: string;

  addr: Pointer;        // adresa metody (Code pointer)
  m: TMethod;           // Delphi struktura: (Code, Data) = metoda objektu
  v: TMyGridKeyValidator;
begin
  EnsureValidatorSize;  // ať pole FValidators odpovídá ColCount

  // Všechny validátory vynuluje
  for i := 0 to High(FValidators) do
    FValidators[i] := nil;

  // Projede seznam z Object Inspectoru
  for i := 0 to FColumnValidatorNames.Count - 1 do
  begin
    line := Trim(FColumnValidatorNames[i]);
    if line = '' then
      Continue; // prázdný řádek ignoruje

    // najde znak '='
    eqPos := line.IndexOf('=');
    if eqPos < 0 then
      Continue; // pokud tam '=' není, je to špatný formát -> ignoruje

    // Rozdělí text na číslo sloupce a název metody
    colStr   := Trim(Copy(line, 1, eqPos));            // část před '='
    methName := Trim(Copy(line, eqPos + 2, MaxInt));   // část za '='

    // Sloupec převede na číslo a ověří rozsah
    col := StrToIntDef(colStr, -1);
    if (col < 0) or (col >= ColCount) then
      Continue; // mimo rozsah -> ignoruje

    // Metodu hledá na Ownerovi komponenty (Form)
    if (Owner = nil) or (methName = '') then
      Continue;

    // Najde adresu metody podle jejího jména
    addr := Owner.MethodAddress(methName);
    if addr = nil then
      Continue; // metoda toho jména neexistuje -> ignoruje

    // Složí "metodu objektu" ve formátu (Code, Data):
    //    - Code = adresa kódu metody
    //    - Data = instance objektu, na které se má metoda volat (Owner)
    m.Code := addr;
    m.Data := Owner;

    // Přetypujeme to na náš typ validátoru
    v := TMyGridKeyValidator(m);

    // Uloží validátor do pole pro daný sloupec
    FValidators[col] := v;
  end;
end;

procedure TMyStringGrid.KeyPress(var Key: Char);
var
  v: TMyGridKeyValidator;
begin
  // validujeme jen v datové části (ne hlavičky)
  if (Key <> #0) and (Row >= FixedRows) and (Col >= FixedCols) then
  begin
    EnsureValidatorSize;

    if (Col >= 0) and (Col < Length(FValidators)) then
    begin
      v := FValidators[Col];
      if Assigned(v) then
        v(Self, Col, Row, Key); // validátor může Key "sežrat" => Key := #0
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

  // až po načtení DFM (Owner existuje) můžeme mapovat názvy metod na validátory
  ApplyValidatorNames;
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

