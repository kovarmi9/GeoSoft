unit GeoGrid;

interface

uses
  System.Classes,
  System.Types,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Grids,
  Vcl.Graphics,
  Vcl.Controls;

type

  TEnterEndBehavior = (
    ebStayOnLastCell, // zůstat na poslední buňce
    ebWrapToStart,    // skočit zpět na první datovou buňku
    ebAddRow,         // přidat řádek a přejít na něj
    ebMoveFocusNext   // přesunout focus na další komponentu
  );

  TGeoInplaceEdit = class(TInplaceEdit)
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  end;

  TGeoGrid = class(TStringGrid)
  private
    FEnterEndBehavior: TEnterEndBehavior;

  protected
    function CreateEditor: TInplaceEdit; override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

  public
    constructor Create(AOwner: TComponent); override;

  published
    property EnterEndBehavior: TEnterEndBehavior
      read FEnterEndBehavior write FEnterEndBehavior
      default ebStayOnLastCell;
  end;

implementation

{ TGeoInplaceEdit }

procedure TGeoInplaceEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := VK_TAB
  end;
  inherited KeyDown(Key, Shift);
end;

{ TGeoGrid }

function TGeoGrid.CreateEditor: TInplaceEdit;
begin
  Result := TGeoInplaceEdit.Create(Self);
end;

constructor TGeoGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Options := Options + [goEditing, goTabs];
  FEnterEndBehavior := ebStayOnLastCell;
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

procedure TGeoGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := VK_TAB;
  end;
  inherited KeyDown(Key, Shift);
end;

end.
