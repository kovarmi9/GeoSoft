unit MyStringGrid;

interface

uses
  System.Classes,
  System.Types,     // TRect
  Vcl.Controls,     // TShiftState
  Vcl.Grids;

type
  TEnterEndBehavior = (ebWrapToStart, ebAddRow); // Co dělat při Enteru v posledním řádku a sloupci
  TMyStringGrid = class(TStringGrid)
  private
    FEnterEndBehavior: TEnterEndBehavior;
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    // výchozí: wrap zpět na první datovou buňku [FixedCols, FixedRows]
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior default ebWrapToStart;
  end;

implementation

uses
  Winapi.Windows,  // VK_RETURN
  Vcl.Graphics;

{ TMyStringGrid }

constructor TMyStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Options := Options + [goEditing, goTabs];
end;

procedure TMyStringGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  FirstDataCol, FirstDataRow: Integer;
begin
  if Key = VK_RETURN then
  begin
    Key := 0;

    FirstDataCol := FixedCols;   // Pro přepínání vždy na první datový sloupec
    FirstDataRow := FixedRows;   // Pro přepínání vždy na první datový řádek

    // Není konec řádku -> doprava
    if Col < ColCount - 1 then
    begin
      Col := Col + 1;
      Exit;
    end;

    // Je konec řádku a není to poslední řádek -> skoč dolů na první datový sloupec
    if Row < RowCount - 1 then
    begin
      Row := Row + 1;
      Col := FirstDataCol;
      Exit;
    end;

    // Poslední řádek a poslední sloupec -> podle režimu
    case FEnterEndBehavior of
      ebWrapToStart:
        begin
          Row := FirstDataRow;
          Col := FirstDataCol;
        end;
      ebAddRow:
        begin
          RowCount := RowCount + 1; // přidej nový řádek
          Row := Row + 1;           // skoč na něj
          Col := FirstDataCol;      // a na 1. datový sloupec
        end;
    end;
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
  // Vlastní hlavička (fixed buňky)
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

end.

//unit MyStringGrid;
//
//interface
//
//uses
//  System.Classes,
//  System.Types,     // TRect
//  Vcl.Controls,     // TShiftState
//  Vcl.Grids;
//
//type
//  // co dělat při Enteru na poslední buňce posledního řádku
//  TEnterEndBehavior = (ebWrapToStart, ebAddRow);
//
//  TMyStringGrid = class(TStringGrid)
//  private
//    FEnterEndBehavior: TEnterEndBehavior;
//  protected
//    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
//    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;
//  public
//    constructor Create(AOwner: TComponent); override;
//  published
//    // výchozí: wrap zpět na první datovou buňku [FixedCols, FixedRows]
//    property EnterEndBehavior: TEnterEndBehavior
//      read FEnterEndBehavior write FEnterEndBehavior default ebWrapToStart;
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
//  FEnterEndBehavior := ebWrapToStart; // default
//end;
//
//procedure TMyStringGrid.KeyDown(var Key: Word; Shift: TShiftState);
//var
//  FirstDataCol, FirstDataRow: Integer;
//begin
//  if Key = VK_RETURN then
//  begin
//    Key := 0;
//
//    FirstDataCol := FixedCols;  // pokud chceš vždy sl.1, dej FirstDataCol := 1;
//    FirstDataRow := FixedRows;
//
//    // 1) nejsme na konci řádku -> doprava
//    if Col < ColCount - 1 then
//    begin
//      Col := Col + 1;
//      Exit;
//    end;
//
//    // 2) jsme na konci řádku, ale ne na poslední řádce -> o řádek níž, na 1. datový sloupec
//    if Row < RowCount - 1 then
//    begin
//      Row := Row + 1;
//      Col := FirstDataCol;
//      Exit;
//    end;
//
//    // 3) úplně poslední buňka -> podle režimu
//    case FEnterEndBehavior of
//      ebWrapToStart:
//        begin
//          Row := FirstDataRow;
//          Col := FirstDataCol;
//        end;
//      ebAddRow:
//        begin
//          RowCount := RowCount + 1; // přidej nový řádek
//          Row := Row + 1;           // skoč na něj
//          Col := FirstDataCol;      // a na 1. datový sloupec
//        end;
//    end;
//    Exit;
//  end;
//
//  inherited KeyDown(Key, Shift);
//end;
//
//procedure TMyStringGrid.DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
//var
//  S: string;
//  X, Y, W, H: Integer;
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
//
//      // Bez Rect.Width/Height – ať to kompiluje všude
//      W := Rect.Right - Rect.Left;
//      H := Rect.Bottom - Rect.Top;
//
//      X := Rect.Left + (W - Canvas.TextWidth(S)) div 2;
//      Y := Rect.Top  + (H - Canvas.TextHeight(S)) div 2;
//      Canvas.TextRect(Rect, X, Y, S);
//    finally
//      RestoreDC(Canvas.Handle, SavedDC);
//    end;
//  end
//  else
//    inherited DrawCell(ACol, ARow, Rect, State);
//end;
//
//end.

