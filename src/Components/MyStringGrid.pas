//unit MyStringGrid;
//
//interface
//
//uses
//  System.Classes,
//  //Winapi.Windows,   // Pro zprávu v outputu
//  System.Types,     // TRect
//  System.Math,      // max()
//  Vcl.Controls,     // TShiftState
//  Vcl.Grids;
//
//type
//  TEnterEndBehavior = (ebWrapToStart, ebAddRow); // Co dělat při Enteru v posledním řádku a sloupci
//  TMyStringGrid = class(TStringGrid)
//  private
//    FEnterEndBehavior: TEnterEndBehavior;
//    FColumnHeaders: TStrings; // texty horní hlavičky (row 0)
//    FRowHeaders: TStrings;    // texty levé hlavičky (col 0)
//    procedure SetColumnHeaders(const Value: TStrings);
//    procedure SetRowHeaders(const Value: TStrings);
//    procedure UpdateHeaders; // propíše texty do buněk
//    procedure AutoSizeDataColumns; // automatická šířka sloupců
//  protected
//    procedure Loaded; override; // Po načtení z DFM aplikuje hlavičky
//    procedure Resize; override; // Pro změnu šířky sloupců
//    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
//    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;
//  public
//    constructor Create(AOwner: TComponent); override;
//    destructor Destroy; override;
//  published
//    // Výchozí chování Enteru – vrátit se na začátek
//    property EnterEndBehavior: TEnterEndBehavior
//      read FEnterEndBehavior write FEnterEndBehavior default ebWrapToStart;
//
//    // Popisky horní hlavičky (fixed row)
//    property ColumnHeaders: TStrings
//      read FColumnHeaders write SetColumnHeaders;
//
//    // Popisky levé hlavičky (fixed column)
//    property RowHeaders: TStrings
//      read FRowHeaders write SetRowHeaders;
//  end;
//
//implementation
//
//uses
//  Winapi.Windows,  // VK_RETURN
//  Vcl.Graphics;
//
//{ TMyStringGrid }
//
//constructor TMyStringGrid.Create(AOwner: TComponent);
//begin
//  inherited Create(AOwner);
//  Options := Options + [goEditing, goTabs];
//  FEnterEndBehavior := ebWrapToStart;
//  FColumnHeaders := TStringList.Create;
//  FRowHeaders    := TStringList.Create;
//end;
//
//destructor TMyStringGrid.Destroy;
//begin
//  FColumnHeaders.Free;
//  FRowHeaders.Free;
//  inherited Destroy;
//end;
//
////procedure TMyStringGrid.KeyDown(var Key: Word; Shift: TShiftState);
////var
////  FirstDataCol, FirstDataRow: Integer;
////begin
////  if Key = VK_RETURN then
////  begin
////      // OnKeyDown udělá svoje věci, Když to "sežere" (Key := 0), tak už my nepřeskakuje
////    if Assigned(OnKeyDown) then
////      OnKeyDown(Self, Key, Shift);
////
////    if Key = 0 then
////      Exit;
////
////    // Jeden Enter = potvrdit editaci (pokud editujeme) + hned přesun
////    if EditorMode then
////      HideEditor;   // commit hodnoty z inplace editoru do Cells[Col,Row]
////
////    Key := 0;
////    Key := 0;
////
////    FirstDataCol := FixedCols;   // Pro přepínání vždy na první datový sloupec
////    FirstDataRow := FixedRows;   // Pro přepínání vždy na první datový řádek
////
////    // bezpečnost: nepřeskakuj v pevné části
////    if (Row < FirstDataRow) then Row := FirstDataRow;
////    if (Col < FirstDataCol) then Col := FirstDataCol;
////
////    // Není konec řádku -> doprava
////    if Col < ColCount - 1 then
////    begin
////      Col := Col + 1;
////      Exit;
////    end;
////
////    // Je konec řádku a není to poslední řádek -> skoč dolů na první datový sloupec
////    if Row < RowCount - 1 then
////    begin
////      Row := Row + 1;
////      Col := FirstDataCol;
////      Exit;
////    end;
////
////    // Poslední řádek a poslední sloupec -> podle režimu
////    case FEnterEndBehavior of
////      ebWrapToStart:
////        begin
////          Row := FirstDataRow;
////          Col := FirstDataCol;
////        end;
////      ebAddRow:
////        begin
////          RowCount := RowCount + 1; // přidej nový řádek
////          Row := Row + 1;           // skoč na něj
////          Col := FirstDataCol;      // a na 1. datový sloupec
////        end;
////    end;
////
////    // Volitelně rovnou otevřít editor v nové buňce
////    if goEditing in Options then
////      EditorMode := True;
////
////    Exit;
////  end;
////
////  inherited KeyDown(Key, Shift);
////end;
//
//procedure TMyStringGrid.KeyDown(var Key: Word; Shift: TShiftState);
//var
//  FirstDataCol, FirstDataRow: Integer;
//begin
//  if (Key = VK_RETURN) or (Key = VK_TAB) then
//  begin
//    Key := 0;
//
//    FirstDataCol := FixedCols;
//    FirstDataRow := FixedRows;
//
//    // bezpečnost: ať to neskáče do hlaviček
//    if Row < FirstDataRow then Row := FirstDataRow;
//    if Col < FirstDataCol then Col := FirstDataCol;
//
//    // POSUN – tahle změna buňky sama commitne to, co je rozepsané v editoru
//    if Col < ColCount - 1 then
//      Col := Col + 1
//    else if Row < RowCount - 1 then
//    begin
//      Row := Row + 1;
//      Col := FirstDataCol;
//    end
//    else
//    begin
//      case FEnterEndBehavior of
//        ebWrapToStart:
//          begin
//            Row := FirstDataRow;
//            Col := FirstDataCol;
//          end;
//        ebAddRow:
//          begin
//            RowCount := RowCount + 1;
//            Row := Row + 1;
//            Col := FirstDataCol;
//          end;
//      end;
//    end;
//
//    // hned začít psát v nové buňce
//    if goEditing in Options then
//      EditorMode := True;
//
//    Exit;
//  end;
//
//  inherited KeyDown(Key, Shift);
//end;
//
//procedure TMyStringGrid.DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
//var
//  S: string;
//  X, Y: Integer;
//  SavedDC: Integer;
//begin
//  // Vlastní hlavička (fixed buňky)
//  if (ARow < FixedRows) or (ACol < FixedCols) then
//  begin
//    SavedDC := SaveDC(Canvas.Handle);
//    try
//      Canvas.Brush.Color := clBtnFace;
//      Canvas.Font.Style := [fsBold];
//      Canvas.FillRect(Rect);
//
//      S := Cells[ACol, ARow];
//      X := Rect.Left + (Rect.Width  - Canvas.TextWidth(S))  div 2;
//      Y := Rect.Top  + (Rect.Height - Canvas.TextHeight(S)) div 2;
//      Canvas.TextRect(Rect, X, Y, S);
//    finally
//      RestoreDC(Canvas.Handle, SavedDC);
//    end;
//  end
//  else
//    inherited DrawCell(ACol, ARow, Rect, State);
//end;
//
//procedure TMyStringGrid.Loaded;
//begin
//  inherited;
//  // po načtení z DFM propíšeme hlavičky do buněk
//  UpdateHeaders;
//  // po načtení nastaví šířky
//  AutoSizeDataColumns;
//end;
//
//procedure TMyStringGrid.SetColumnHeaders(const Value: TStrings);
//begin
//  // zkopíruj obsah (OI pošle dočasný TStrings)
//  FColumnHeaders.Assign(Value);
//  UpdateHeaders;
//end;
//
//procedure TMyStringGrid.SetRowHeaders(const Value: TStrings);
//begin
//  FRowHeaders.Assign(Value);
//  UpdateHeaders;
//end;
//
//procedure TMyStringGrid.UpdateHeaders;
//var
//  c, r: Integer;
//begin
//  // Když je něco vyplněno, zajistíme fixed řádek/sloupec
//  if (FColumnHeaders.Count > 0) and (FixedRows = 0) then
//    FixedRows := 1;
//  if (FRowHeaders.Count > 0) and (FixedCols = 0) then
//    FixedCols := 1;
//
//  // Horní hlavička (row 0)
//  if FixedRows > 0 then
//    for c := 0 to ColCount - 1 do
//      if c < FColumnHeaders.Count then
//        Cells[c, 0] := FColumnHeaders[c];
//
//  // Levá hlavička (col 0)
//  if FixedCols > 0 then
//    for r := 0 to RowCount - 1 do
//      if r < FRowHeaders.Count then
//        Cells[0, r] := FRowHeaders[r];
//
//  Invalidate; // překresli
//end;
//
//procedure TMyStringGrid.Resize;
//begin
//  inherited;
//  // AutoSizeDataColumns; // Měnění šířky okna
//end;
//
//
////procedure TMyStringGrid.AutoSizeDataColumns;
////var
////  c, DataCols, Avail, FixedW, Base, Extra, MinW: Integer;
////begin
////  if ColCount = 0 then Exit;
////
////  // šířka pevných (left) sloupců
////  FixedW := 0;
////  for c := 0 to FixedCols - 1 do
////    Inc(FixedW, ColWidths[c]);
////
////  // dostupná šířka pro datové sloupce
////  Avail := ClientWidth - FixedW - (BorderWidth * 2);
////  if Avail <= 0 then Exit;
////
////  DataCols := ColCount - FixedCols;
////  if DataCols <= 0 then Exit;
////
////  // minimální šířka pro čitelnost
////  MinW := 40;
////
////  // základ a zbytek rozdělíme po pixlu zleva doprava
////  Base  := Avail div DataCols;
////  Extra := Avail mod DataCols;
////
////  for c := FixedCols to ColCount - 1 do
////    ColWidths[c] := Max(Base + Ord((c - FixedCols) < Extra), MinW);
////end;
//
//procedure TMyStringGrid.AutoSizeDataColumns;
//var
//  c, DataCols, Avail, FixedW, Base, Extra, MinW, Used, Last: Integer;
//begin
//  if ColCount = 0 then Exit;
//
//  // šířka pevných (left) sloupců
//  FixedW := 0;
//  for c := 0 to FixedCols - 1 do
//    Inc(FixedW, ColWidths[c]);
//
//  DataCols := ColCount - FixedCols;
//  if DataCols <= 0 then Exit;
//
//  // dostupná šířka pro datové sloupce (odečteme i svislé čáry mřížky mezi sloupci)
//  // mezi datovými sloupci je (DataCols-1) čar + 1 čára mezi fixed a data částí
//  Avail := ClientWidth - FixedW - GridLineWidth * (DataCols);
//  if Avail <= 0 then Exit;
//
//  MinW := 40;
//  Base  := Avail div DataCols;
//  Extra := Avail mod DataCols;
//
//  Used := 0;
//  Last := ColCount - 1;
//
//  // nastavíme všechny datové sloupce kromě posledního
//  for c := FixedCols to Last - 1 do
//  begin
//    ColWidths[c] := Max(Base + Ord((c - FixedCols) < Extra), MinW);
//    Inc(Used, ColWidths[c]);
//  end;
//
//  // poslední sloupec přesně na zbytek (bez přesahu → žádný H-scrollbar)
//  ColWidths[Last] := Max(Avail - Used, MinW);
//end;
//
//end.

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
  // drž pole validátorů stejně dlouhé jako ColCount
  if Length(FValidators) <> ColCount then
    SetLength(FValidators, ColCount);
end;

procedure TMyStringGrid.SetColumnValidator(ACol: Integer; AValidator: TMyGridKeyValidator);
begin
  EnsureValidatorSize;
  if (ACol >= 0) and (ACol < Length(FValidators)) then
    FValidators[ACol] := AValidator;
end;

procedure TMyStringGrid.ClearColumnValidator(ACol: Integer);
begin
  EnsureValidatorSize;
  if (ACol >= 0) and (ACol < Length(FValidators)) then
    FValidators[ACol] := nil;
end;

procedure TMyStringGrid.SetColumnValidatorNames(const Value: TStrings);
begin
  FColumnValidatorNames.Assign(Value);
  ApplyValidatorNames;
end;

procedure TMyStringGrid.ApplyValidatorNames;
var
  i, eqPos, col: Integer;
  line, colStr, methName: string;
  addr: Pointer;
  m: TMethod;
  v: TMyGridKeyValidator;
begin
  EnsureValidatorSize;

  // nejdřív vyčistit
  for i := 0 to High(FValidators) do
    FValidators[i] := nil;

  // naparsovat "col=MethodName"
  for i := 0 to FColumnValidatorNames.Count - 1 do
  begin
    line := Trim(FColumnValidatorNames[i]);
    if line = '' then
      Continue;

    eqPos := line.IndexOf('=');
    if eqPos < 0 then
      Continue;

    colStr   := Trim(Copy(line, 1, eqPos));
    methName := Trim(Copy(line, eqPos + 2, MaxInt));

    col := StrToIntDef(colStr, -1);
    if (col < 0) or (col >= ColCount) then
      Continue;

    // Metodu hledáme na Ownerovi (typicky Form)
    if (Owner = nil) or (methName = '') then
      Continue;

    addr := Owner.MethodAddress(methName);
    if addr = nil then
      Continue;

    m.Code := addr;
    m.Data := Owner;

    v := TMyGridKeyValidator(m);

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

