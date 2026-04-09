unit GeoGrid;

interface

uses
  System.Classes, System.Types,
  Vcl.Grids, Vcl.Graphics;

type
  TGeoGrid = class(TStringGrid)
  protected
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState); override;

  public
    constructor Create(AOwner: TComponent); override;

  published
    // future geo-specific published properties go here
  end;

implementation

{ TGeoGrid }

constructor TGeoGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // future geo-specific defaults go here
end;

procedure TGeoGrid.DrawCell(ACol, ARow: Integer; Rect: TRect;
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

end.
