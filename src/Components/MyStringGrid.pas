unit MyStringGrid;

interface

uses
  System.Classes, System.Types,   // TShiftState, TRect
  Vcl.Grids;

type
  TMyStringGrid = class(TStringGrid)
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  Winapi.Windows, Vcl.Graphics;

constructor TMyStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // obecn� �p��jemn� defaulty � m��e� si kdykoliv p�epsat ve formu
  FixedRows := 1;
  Options := Options + [goEditing, goFixedHorzLine, goFixedVertLine, goHorzLine, goVertLine];
end;

procedure TMyStringGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;                 // potla�� default Enteru
    if Col < ColCount - 1 then
      Col := Col + 1;         // jako Tab � jen doprava v r�mci ��dku
    Exit;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TMyStringGrid.DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  S: string;
  X, Y: Integer;
begin
  // Hlavi�ka (ARow < FixedRows) a p��padn� �fixed� sloupec (ACol < FixedCols)
  if (ARow < FixedRows) or (ACol < FixedCols) then
  begin
    Canvas.Brush.Color := clBtnFace;
    Canvas.Font.Style := [fsBold];
    Canvas.FillRect(Rect);

    S := Cells[ACol, ARow];
    X := Rect.Left + (Rect.Width  - Canvas.TextWidth(S))  div 2;
    Y := Rect.Top  + (Rect.Height - Canvas.TextHeight(S)) div 2;
    Canvas.TextRect(Rect, X, Y, S);
  end
  else
    inherited DrawCell(ACol, ARow, Rect, State);
end;

end.

