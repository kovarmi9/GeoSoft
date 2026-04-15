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
//    procedure KeyPress(var Key: Char); override;
  end;

  TGeoGrid = class(TStringGrid)
  private
    FEnterEndBehavior: TEnterEndBehavior;

  protected
    function CreateEditor: TInplaceEdit; override;
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
//    procedure KeyPress(var Key: Char); override;
//    function SelectCell(ACol, ARow: Longint): Boolean; override;
    procedure MoveToNextCell(PressedKey: Word; Shift: TShiftState); virtual;

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

//procedure TGeoInplaceEdit.KeyPress(var Key: Char);
//begin
//  if Key = #13 then Key := #0;   // zabij CR, ať nedojde k re-aktivaci editoru
//  inherited KeyPress(Key);
//end;

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

//procedure TGeoGrid.KeyDown(var Key: Word; Shift: TShiftState);
//begin
//  if Key = VK_RETURN then
//  begin
//    Key := VK_TAB;
//  end;
//  inherited KeyDown(Key, Shift);
//end;

procedure TGeoGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    MoveToNextCell(Key, Shift);
    Key := 0;
    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

procedure TGeoGrid.MoveToNextCell(PressedKey: Word; Shift: TShiftState);
var
  FirstDataCol, FirstDataRow: Integer;
  GoForward: Boolean;
begin
  FirstDataCol := FixedCols;
  FirstDataRow := FixedRows;

  if Row < FirstDataRow then
    Row := FirstDataRow;
  if Col < FirstDataCol then
    Col := FirstDataCol;

  if EditorMode then
    EditorMode := False;

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
      ebStayOnLastCell:
        begin
          Row := RowCount - 1;
          Col := ColCount - 1;
        end;

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

      ebMoveFocusNext:
        begin
          GoForward := not ((PressedKey = VK_TAB) and (ssShift in Shift));
          SelectNext(Self, GoForward, True);
          Exit;
        end;
    end;
  end;

//  if goEditing in Options then
//    EditorMode := True;

if (PressedKey = VK_RETURN) and (goEditing in Options) then
  EditorMode := True;
end;

//procedure TGeoGrid.KeyPress(var Key: Char);
//begin
//  if Key = #13 then
//    Key := #9;
//  inherited KeyPress(Key);
//end;
//
//function TGeoGrid.SelectCell(ACol, ARow: Longint): Boolean;
//begin
//  //Result := inherited SelectCell(ACol, ARow);
//  if EditorMode then
//    EditorMode := False;
//end;

end.



//unit GeoGrid;
//
//interface
//
//uses
//  System.Classes, System.Types,
//  Winapi.Windows, Winapi.Messages,
//  Vcl.Grids, Vcl.Graphics, Vcl.Controls;
//
//type
//  TEnterEndBehavior = (
//    ebStayOnLastCell, ebWrapToStart, ebAddRow, ebMoveFocusNext
//  );
//
//  TGeoInplaceEdit = class(TInplaceEdit)
//  protected
//    procedure WndProc(var Message: TMessage); override;
//  end;
//
//  TGeoGrid = class(TStringGrid)
//  private
//    FEnterEndBehavior: TEnterEndBehavior;
//  protected
//    function CreateEditor: TInplaceEdit; override;
//    procedure DrawCell(ACol, ARow: Integer; Rect: TRect;
//      State: TGridDrawState); override;
//    procedure WndProc(var Message: TMessage); override;
//  public
//    constructor Create(AOwner: TComponent); override;
//  published
//    property EnterEndBehavior: TEnterEndBehavior
//      read FEnterEndBehavior write FEnterEndBehavior
//      default ebStayOnLastCell;
//  end;
//
//implementation
//
//// Přepíše Enter na Tab a zahodí znakovou zprávu #13
//procedure RewriteEnterAsTab(var Message: TMessage; out Drop: Boolean);
//begin
//  Drop := False;
//  case Message.Msg of
//    WM_KEYDOWN, WM_KEYUP:
//      if Message.WParam = VK_RETURN then
//        Message.WParam := VK_TAB;
//    WM_CHAR:
//      if Message.WParam = 13 then
//        Drop := True;  // neposílat dál, jinak by grid otevřel editor
//  end;
//end;
//
//{ TGeoInplaceEdit }
//
//procedure TGeoInplaceEdit.WndProc(var Message: TMessage);
//var Drop: Boolean;
//begin
//  RewriteEnterAsTab(Message, Drop);
//  if not Drop then inherited WndProc(Message);
//end;
//
//{ TGeoGrid }
//
//procedure TGeoGrid.WndProc(var Message: TMessage);
//var Drop: Boolean;
//begin
//  RewriteEnterAsTab(Message, Drop);
//  if not Drop then inherited WndProc(Message);
//end;
//
//function TGeoGrid.CreateEditor: TInplaceEdit;
//begin
//  Result := TGeoInplaceEdit.Create(Self);
//end;
//
//constructor TGeoGrid.Create(AOwner: TComponent);
//begin
//  inherited Create(AOwner);
//  Options := Options + [goEditing, goTabs];
//  FEnterEndBehavior := ebStayOnLastCell;
//end;
//
//procedure TGeoGrid.DrawCell(ACol, ARow: Integer; Rect: TRect;
//  State: TGridDrawState);
//var
//  S: string;
//  TextX, TextY: Integer;
//begin
//  if (ARow < FixedRows) or (ACol < FixedCols) then
//  begin
//    Canvas.Brush.Color := clBtnFace;
//    Canvas.Font.Style  := [fsBold];
//    Canvas.FillRect(Rect);
//    S     := Cells[ACol, ARow];
//    TextX := Rect.Left + (Rect.Width  - Canvas.TextWidth(S)) div 2;
//    TextY := Rect.Top  + (Rect.Height - Canvas.TextHeight(S)) div 2;
//    Canvas.TextRect(Rect, TextX, TextY, S);
//  end
//  else
//    inherited DrawCell(ACol, ARow, Rect, State);
//end;
//
//end.
