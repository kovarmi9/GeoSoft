unit PolarMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  PointsUtilsSingleton, Point, AddPoint,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Types;

type
  TForm3 = class(TForm)
    ToolBar2: TToolBar;
    ComboBox4: TComboBox;
    ToolButton3: TToolButton;
    ComboBox5: TComboBox;
    ToolButton2: TToolButton;
    ComboBox6: TComboBox;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    StringGrid1: TStringGrid;
    ToolBar1: TToolBar;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure UpdateCurrentDirectoryPath;
    procedure AutoSizeColumns(const CustomWidths: array of Integer);
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.FormCreate(Sender: TObject);
begin
  // Základní nastavení gridu
  StringGrid1.ColCount := 9;    // sloupce 0..8
  StringGrid1.RowCount := 4;    // řádky 0..3
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Hlavička
  StringGrid1.Cells[1, 0] := 'číslo bodu';
  StringGrid1.Cells[2, 0] := 'Vod. úhel';
  StringGrid1.Cells[3, 0] := 'Vod. vzdál.';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';
  StringGrid1.Cells[6, 0] := 'Z';
  StringGrid1.Cells[7, 0] := 'Kvalita';
  StringGrid1.Cells[8, 0] := 'Popis';

  // Popisky prvních dvou speciálních řádků
  StringGrid1.Cells[0, 1] := 'Stanoviso';
  StringGrid1.Cells[0, 2] := 'Orientace';

  // Číselný první datový řádek
  StringGrid1.Cells[0, 3] := '1';

  // Události
  StringGrid1.OnKeyDown  := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Zobraz aktuální adresář
  UpdateCurrentDirectoryPath;

  StringGrid1.Repaint;
end;

procedure TForm3.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  P: Point.TPoint; //
  dlg: TForm6;
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;  // potlačí defaultní Enter

  // 1) Načteme číslo bodu z gridu
  PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
  if PointNumber = -1 then
  begin
    ShowMessage('Neplatné číslo bodu.');
    Exit;
  end;

  // 2) Pokud bod existuje → načti ho přímo
  if TPointDictionary.GetInstance.PointExists(PointNumber) then
    P := TPointDictionary.GetInstance.GetPoint(PointNumber)
  else
  begin
    // 3) Pokud neexistuje → otevři náš formulář pro přidání bodu
    dlg := TForm6.Create(Self);
    try
      if not dlg.Execute(PointNumber, P) then
        Exit; // uživatel zrušil

      // Přidáme nový bod do slovníku
      //TPointDictionary.GetInstance.AddPoint(P);
    finally
      dlg.Free;
    end;
  end;

  // 4) Vyplníme buňky z bodu
  StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
  StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
  StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
  StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
  StringGrid1.Cells[8, StringGrid1.Row] := P.Description;

  // 5) Posun na další buňku / řádek
  if StringGrid1.Col < StringGrid1.ColCount - 1 then
    StringGrid1.Col := StringGrid1.Col + 1
  else
  begin
    if StringGrid1.Row = StringGrid1.RowCount - 1 then
      StringGrid1.RowCount := StringGrid1.RowCount + 1;
    StringGrid1.Row := StringGrid1.Row + 1;
    StringGrid1.Col := 1;

    if StringGrid1.Row > 2 then
      StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
  end;
end;

procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Text: string;
  TextW: Integer;
  X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    // Pevné buňky = hlavičky řádků i sloupců
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace; // šedé pozadí pro hlavičky
      Font.Style := [fsBold];
      FillRect(Rect);

      // Ruční centrování textu (větší přesnost než DT_CENTER)
      Text := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(Text);
      X := Rect.Left + (Rect.Width - TextW) div 2;
      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      Brush.Color := clWindow; // bílé pozadí pro data
      Font.Style := [];
      FillRect(Rect);

      // Odsazení textu od levého okraje
      Text := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;

  // Po vykreslení přizpůsobí šířky sloupců
  AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);
end;

procedure TForm3.AutoSizeColumns(const CustomWidths: array of Integer);
var
  i, w: Integer;
begin
  // Pro všechny datové sloupce 1..ColCount-1
  for i := 1 to StringGrid1.ColCount - 1 do
  begin
    // Pokud mám v CustomWidths prvek pro tento sloupec a je >0, vezmu ho
    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
      w := CustomWidths[i-1]
    else
      // jinak auto podle šířky nadpisu + 16px odsazení
      w := StringGrid1.Canvas.TextWidth(StringGrid1.Cells[i,0]) + 16;

    StringGrid1.ColWidths[i] := w;
  end;
end;

end.
