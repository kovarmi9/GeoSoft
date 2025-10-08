unit MyPointsStringGrid;

interface

uses
  System.Classes,
  System.Types,     // TRect
  Vcl.Controls,     // TShiftState
  Vcl.Grids;

type
  TMyPointsStringGrid = class(TStringGrid)
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  Winapi.Windows, Vcl.Graphics;

constructor TMyPointsStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TMyPointsStringGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // když Enter → jen doprava (bez přeskoku na další řádek a bez přidávání řádků)
  if Key = VK_RETURN then
  begin
    Key := 0; // potlačí defaultní akci Enteru
    if Col < ColCount - 1 then
      Col := Col + 1; // posun jen v rámci řádku
    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

procedure TMyPointsStringGrid.DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  S: string;
  X, Y: Integer;
  SavedDC: Integer;
begin
  // Pro "fixed" buňky (hlavičky/sloupce) malujeme vlastní vzhled
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
    inherited DrawCell(ACol, ARow, Rect, State); // běžné buňky necháme vykreslit defaultně
end;


end.

