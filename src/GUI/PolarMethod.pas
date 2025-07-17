unit PolarMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  PointsUtilsSingleton, Point,
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
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.FormCreate(Sender: TObject);
begin
  // Základní nastavení gridu
  StringGrid1.ColCount := 9;    // sloupce 0..8
  StringGrid1.RowCount := 4;    // øádky 0..3
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Hlavièka
  StringGrid1.Cells[1, 0] := 'èíslo bodu';
  StringGrid1.Cells[2, 0] := 'Vodorovný úhel';
  StringGrid1.Cells[3, 0] := 'Vodorovná vzdálenost';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';
  StringGrid1.Cells[6, 0] := 'Z';
  StringGrid1.Cells[7, 0] := 'Kvalita';
  StringGrid1.Cells[8, 0] := 'Popis';

  // Popisky prvních dvou speciálních øádkù
  StringGrid1.Cells[0, 1] := 'Stanoviso';
  StringGrid1.Cells[0, 2] := 'Orientace';

  // Èíselný první datový øádek
  StringGrid1.Cells[0, 3] := '1';

  // Události
  StringGrid1.OnKeyDown  := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Zobraz aktuální adresáø
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
  P: Point.TPoint;  // explicitnì z tvé jednotky Point
begin
  if Key = VK_RETURN then
  begin
    Key := 0;  // potlaèí default chování

    // Naèti èíslo bodu z prvního sloupce
    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
    if PointNumber = -1 then
    begin
      ShowMessage('Neplatné èíslo bodu.');
      Exit;
    end;

    // Pokud bod existuje ve slovníku, doplòme údaje
    if TPointDictionary.GetInstance.PointExists(PointNumber) then
    begin
      P := TPointDictionary.GetInstance.GetPoint(PointNumber);
      StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
      StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
      StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
      StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
      StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
    end
    else
      ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]));

    // Navigace: další buòka nebo nový øádek
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
      StringGrid1.Col := StringGrid1.Col + 1
    else
    begin
      // Pokud je to poslední øádek, pøidáme nový
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
        StringGrid1.RowCount := StringGrid1.RowCount + 1;
      // pøechod na další øádek, první datový sloupec
      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 1;
      // oèíslování nultého sloupce
      if StringGrid1.Row > 2 then
        StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
    end;
  end
  else if Key = VK_DELETE then
  begin
    // Vymaž obsah aktuální buòky
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
  end;
end;

//procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//begin
//  with StringGrid1.Canvas do
//  begin
//    // Barvy pozadí pro hlavièky vs. data
//    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
//      Brush.Color := clMenuBar
//    else
//      Brush.Color := clWhite;
//    FillRect(Rect);
//
//    // Rámeèek (volitelné, odkomentuj pokud chceš)
//    // Pen.Color := clNavy;
//    // Rectangle(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
//
//    // Vypsání textu
//    TextRect(Rect, Rect.Left + 4, Rect.Top + 2,
//      StringGrid1.Cells[ACol, ARow]);
//  end;
//end;
//
//end.


procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Text: string;
  TextW: Integer;
  X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    // pozadí
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
      Brush.Color := clMenuBar
    else
      Brush.Color := clWhite;
    FillRect(Rect);

    Text := StringGrid1.Cells[ACol, ARow];

    if ARow = 0 then
    begin
      // pro hlavièku: vycentruj vodorovnì
      TextW := TextWidth(Text);
      X := Rect.Left + (Rect.Right - Rect.Left - TextW) div 2;
      // vertikálnì nechám trochu odsazení odshora
      Y := Rect.Top + (Rect.Bottom - Rect.Top - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      // klasické psaní (nebo tu mùžeš pøidat další podmínky)
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;
end;

end.
