unit GeoGrid;

interface

uses
  System.Classes,
  System.Types,
  Vcl.Grids,
  Vcl.Graphics,
  Vcl.Controls;

type
  TGeoGrid = class(TStringGrid)
  private
    FNavigating: Boolean;

  protected
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

  public
    constructor Create(AOwner: TComponent); override;

  published
    // future geo-specific published properties go here
  end;

implementation

uses
  Winapi.Windows;

{ TGeoGrid }

constructor TGeoGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Options := Options + [goEditing, goTabs];
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

procedure TGeoGrid.KeyPress(var Key: Char);
var
  VK: Word;
begin
  if (Key = #13) or (Key = #9) then
  begin
    Key := #0;

    if FNavigating then
      FNavigating := False   // KeyDown already navigated — just reset
    else
    begin
      VK := VK_RETURN;
      KeyDown(VK, []);       // navigate from the WM_CHAR path (no editor lock)
      FNavigating := False;
    end;

    Exit;
  end;

  inherited KeyPress(Key);
end;

procedure TGeoGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    Key := 0;

    if FNavigating then
      Exit;  // duplicate call — KeyPress will reset the flag

    FNavigating := True;

    // Commit the current editor value before moving
    if EditorMode and Assigned(InplaceEditor) then
      Cells[Col, Row] := InplaceEditor.Text;

    // Navigate to the next cell
    if Col < ColCount - 1 then
      Col := Col + 1
    else if Row < RowCount - 1 then
    begin
      Row := Row + 1;
      Col := FixedCols;
    end;

    // Reopen the editor at the new cell
    if goEditing in Options then
      EditorMode := True;

    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

end.
