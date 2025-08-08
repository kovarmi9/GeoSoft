unit Transformation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin, Vcl.ExtCtrls,
  Vcl.Grids, PointsUtilsSingleton, Point, System.Types;

type
  TForm5 = class(TForm)
    ToolBar2: TToolBar;
    ComboBox4: TComboBox;
    ToolButton3: TToolButton;
    ToolButton2: TToolButton;
    ComboBox6: TComboBox;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    StringGrid1: TStringGrid;
    ToolBar1: TToolBar;
    StaticText1: TStaticText;
    ComboBox1: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure StringGrid1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure UpdateCurrentDirectoryPath;
    procedure AutoSizeColumns(const CustomWidths: array of Integer);
  private
    FChecked: TArray<Boolean>;
  public
  end;

var
  Form5: TForm5;

implementation

{$R *.dfm}

procedure TForm5.FormCreate(Sender: TObject);
begin
  // Základní nastavení
  StringGrid1.ColCount := 12;
  StringGrid1.RowCount := 3;
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Vypneme goEditing pro všechny buňky
  StringGrid1.Options := StringGrid1.Options - [goEditing];

  // Hlavičky sloupců
  StringGrid1.Cells[2,0] := 'ČB do které';
  StringGrid1.Cells[3,0] := 'Y cíl';
  StringGrid1.Cells[4,0] := 'X cíl';
  StringGrid1.Cells[5,0] := 'ČB z které';
  StringGrid1.Cells[6,0] := 'Y zdroj';
  StringGrid1.Cells[7,0] := 'X zdroj';
  StringGrid1.Cells[8,0] := 'dY';
  StringGrid1.Cells[9,0] := 'dX';
  StringGrid1.Cells[10,0] := 'uP';
  StringGrid1.Cells[11,0] := 'Popis';

  // Číslování prvních dvou datových řádků
  StringGrid1.Cells[0,1] := '1';
  StringGrid1.Cells[0,2] := '2';

  // Příprava pole stavů checkboxů
  SetLength(FChecked, StringGrid1.RowCount);

  // První checkbox v hlavičce permanentně zaškrtnutý
  FChecked[0] := True;

  // Zablokování editace ve sloupci s checkboxy
  StringGrid1.OnSelectCell := StringGrid1SelectCell;

  // Přiřaď události
  StringGrid1.OnDrawCell  := StringGrid1DrawCell;
  StringGrid1.OnMouseDown := StringGrid1MouseDown;
  StringGrid1.OnKeyDown   := StringGrid1KeyDown;

  // Zobraz cestu
  UpdateCurrentDirectoryPath;

  // Překreslení
  StringGrid1.Repaint;
end;

procedure TForm5.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm5.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Text: string;
  TextW, X, Y: Integer;
  CR: TRect;
  Flags: Integer;
begin
  with StringGrid1.Canvas do
  begin
    // Pokud jsme v buňce [1, 0] = checkbox v hlavičce
    if (ACol = 1) and (ARow = 0) then
    begin
      Brush.Color := clBtnFace;
      Font.Style := [fsBold];
      FillRect(Rect);

      // Vykreslení zaškrtnutého checkboxu
      CR := Rect;
      InflateRect(CR, -4, -4);
      Flags := DFCS_BUTTONCHECK or DFCS_CHECKED;
      DrawFrameControl(Handle, CR, DFC_BUTTON, Flags);
      Exit;
    end;

    // Běžné hlavičky (pevné buňky)
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace;
      Font.Style := [fsBold];
      FillRect(Rect);

      // Vycentrovaný text
      Text := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(Text);
      X := Rect.Left + (Rect.Width - TextW) div 2;
      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
      Exit;
    end;

    // Data buňky
    Brush.Color := clWindow;
    Font.Style := [];
    FillRect(Rect);

    // Checkbox ve sloupci 1 (datové řádky)
    if ACol = 1 then
    begin
      CR := Rect;
      InflateRect(CR, -4, -4);
      Flags := DFCS_BUTTONCHECK;
      if (ARow < Length(FChecked)) and FChecked[ARow] then
        Flags := Flags or DFCS_CHECKED;
      DrawFrameControl(Handle, CR, DFC_BUTTON, Flags);
      Exit;
    end;

    // Textová data
    Text := StringGrid1.Cells[ACol, ARow];
    TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
  end;

  // Automatické šířky
  AutoSizeColumns([30, 90, 80, 80, 90, 80, 80, 80, 80, 80, 80, 80]);
end;


procedure TForm5.AutoSizeColumns(const CustomWidths: array of Integer);
var
  i, w: Integer;
begin
  for i := 1 to StringGrid1.ColCount - 1 do
  begin
    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
      w := CustomWidths[i-1]
    else
      w := StringGrid1.Canvas.TextWidth(StringGrid1.Cells[i,0]) + 16;

    StringGrid1.ColWidths[i] := w;
  end;
end;

procedure TForm5.StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Integer;
  i: Integer;
  newValue: Boolean;
begin
  StringGrid1.MouseToCell(X, Y, ACol, ARow);

  // Kliknutí na checkbox v hlavičce – přepni všechny
  if (ACol = 1) and (ARow = 0) then
  begin
    newValue := not FChecked[0];
    for i := 1 to StringGrid1.RowCount - 1 do
      FChecked[i] := newValue;
    FChecked[0] := newValue;
    StringGrid1.Repaint;
    Exit;
  end;

  // Kliknutí na běžný checkbox
  if (ACol = 1) and (ARow >= StringGrid1.FixedRows) then
  begin
    FChecked[ARow] := not FChecked[ARow];
    StringGrid1.Repaint;
  end;
end;


procedure TForm5.StringGrid1SelectCell(Sender: TObject;
  ACol, ARow: Integer; var CanSelect: Boolean);
begin
  // Vždy povolíme výběr buňky, aby šla označit a kopírovat
  CanSelect := True;

  // Pokud je ve "editačních" sloupcích (2..7 a 11), povolí goEditing, jinak ho nechá vypnuté
  if ACol in [2..7, 11] then
    StringGrid1.Options := StringGrid1.Options + [goEditing]
  else
    StringGrid1.Options := StringGrid1.Options - [goEditing];
end;

procedure TForm5.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  P: Point.TPoint;
  OldCount: Integer;
begin
  if Key = VK_RETURN then
  begin
    Key := 0;

    // Horizontální úhel (sloupec 2)
    if StringGrid1.Col = 2 then
    begin
      PointNumber := StrToIntDef(StringGrid1.Cells[2, StringGrid1.Row], -1);
      if PointNumber < 0 then
        ShowMessage('Neplatné číslo bodu.')
      else if not TPointDictionary.GetInstance.PointExists(PointNumber) then
        ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]))
      else
      begin
        P := TPointDictionary.GetInstance.GetPoint(PointNumber);
        StringGrid1.Cells[3, StringGrid1.Row] := FloatToStr(P.Y);
        StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
      end;
    end
    // Zdrojový bod (sloupec 6)
    else if StringGrid1.Col = 5 then
    begin
      PointNumber := StrToIntDef(StringGrid1.Cells[5, StringGrid1.Row], -1);
      if PointNumber < 0 then
        ShowMessage('Neplatné číslo bodu.')
      else if not TPointDictionary.GetInstance.PointExists(PointNumber) then
        ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]))
      else
      begin
        P := TPointDictionary.GetInstance.GetPoint(PointNumber);
        StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Y);
        StringGrid1.Cells[7, StringGrid1.Row] := FloatToStr(P.X);
      end;
    end;

    // Navigace Enter -> další pole / nový řádek
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
      StringGrid1.Col := StringGrid1.Col + 1
    else
    begin
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
      begin
        OldCount := StringGrid1.RowCount;
        StringGrid1.RowCount := OldCount + 1;
        SetLength(FChecked, StringGrid1.RowCount);
        FChecked[OldCount] := False;
      end;
      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 1;
      StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row);
    end;
  end
  else if Key = VK_DELETE then
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
end;

end.
