unit PolarMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Math,
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

////procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
////var
////  PointNumber: Integer;
////  P: Point.TPoint;  // explicitně z tvé jednotky Point
////begin
////  if Key = VK_RETURN then
////  begin
////    Key := 0;  // potlačí default chování
////
////    // Načti číslo bodu z prvního sloupce
////    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
////    if PointNumber = -1 then
////    begin
////      ShowMessage('Neplatné číslo bodu.');
////      Exit;
////    end;
////
////    // Pokud bod existuje ve slovníku, doplňme údaje
////    if TPointDictionary.GetInstance.PointExists(PointNumber) then
////    begin
////      P := TPointDictionary.GetInstance.GetPoint(PointNumber);
////      StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
////      StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
////      StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
////      StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
////      StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
////    end
////    else
////      ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]));
////
////    // Navigace: další buňka nebo nový řádek
////    if StringGrid1.Col < StringGrid1.ColCount - 1 then
////      StringGrid1.Col := StringGrid1.Col + 1
////    else
////    begin
////      // Pokud je to poslední řádek, přidáme nový
////      if StringGrid1.Row = StringGrid1.RowCount - 1 then
////        StringGrid1.RowCount := StringGrid1.RowCount + 1;
////      // přechod na další řádek, první datový sloupec
////      StringGrid1.Row := StringGrid1.Row + 1;
////      StringGrid1.Col := 1;
////      // očíslování nultého sloupce
////      if StringGrid1.Row > 2 then
////        StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
////    end;
////  end
////  else if Key = VK_DELETE then
////  begin
////    // Vymaž obsah aktuální buňky
////    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
////  end;
////end;
//
//procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  P: Point.TPoint;
//  UserChoice: Integer;
//  S: string;
//  Valid: Boolean;
//begin
//  if Key = VK_RETURN then
//  begin
//    Key := 0;  // zruší default Enter
//
//    // Načti číslo bodu
//    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
//    if PointNumber = -1 then
//    begin
//      ShowMessage('Neplatné číslo bodu.');
//      Exit;
//    end;
//
//    // Buď bod existuje, nebo se zeptáme, jestli ho chceme přidat
//    if TPointDictionary.GetInstance.PointExists(PointNumber) then
//    begin
//      P := TPointDictionary.GetInstance.GetPoint(PointNumber);
//    end
//    else
////    begin
////      UserChoice := MessageDlg(
////        Format('Bod %d nebyl nalezen. Přejete si jej přidat?', [PointNumber]),
////        mtConfirmation, [mbYes, mbNo], 0
////      );
////      if UserChoice = mrYes then
////      begin
////        // Vytvořím nový record TPoint s výchozími hodnotami
////        P.PointNumber := PointNumber;
////        P.X := 0;
////        P.Y := 0;
////        P.Z := 0;
////        P.Quality := 0;
////        P.Description := '';
////        // Přidám ho do slovníku
////        TPointDictionary.GetInstance.AddPoint(P);
////      end
////      else
////        Exit; // uživatel zvolil No → neděláme nic
////    end;
////
////    // Doplň buňky (stejně pro existující i nově přidaný bod)
////    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
////    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
////    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
////    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
////    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
////
////    // Navigace: další buňka nebo nový řádek
////    if StringGrid1.Col < StringGrid1.ColCount - 1 then
////      StringGrid1.Col := StringGrid1.Col + 1
////    else
////    begin
////      if StringGrid1.Row = StringGrid1.RowCount - 1 then
////        StringGrid1.RowCount := StringGrid1.RowCount + 1;
////      StringGrid1.Row := StringGrid1.Row + 1;
////      StringGrid1.Col := 1;
////      if StringGrid1.Row > 2 then
////        StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
////    end;
////  end
////  else if Key = VK_DELETE then
////  begin
////    // Smaž obsah buňky
////    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
////  end;
////end;
//  begin
//      UserChoice := MessageDlg(
//        Format('Bod %d nebyl nalezen. Přejete si jej přidat?', [PointNumber]),
//        mtConfirmation, [mbYes, mbNo], 0);
//      if UserChoice <> mrYes then
//        Exit;
//
//      // 1) Zeptejme se uživatele na X
//      if not InputQuery('Nový bod', 'Zadejte X souřadnici:', S) then Exit;
//      P.X := StrToFloatDef(S, 0);
//
//      // 2) Načti Y
//      if not InputQuery('Nový bod', 'Zadejte Y souřadnici:', S) then Exit;
//      P.Y := StrToFloatDef(S, 0);
//
//      // 3) Načti Z
//      if not InputQuery('Nový bod', 'Zadejte Z souřadnici:', S) then Exit;
//      P.Z := StrToFloatDef(S, 0);
//
//      // 4) Načti kvalitu (integer)
//      if not InputQuery('Nový bod', 'Zadejte kód kvality (integer):', S) then Exit;
//      P.Quality := StrToIntDef(S, 0);
//
//      // 5) Načti popis
//      if not InputQuery('Nový bod', 'Zadejte popis bodu:', P.Description) then Exit;
//
//      P.PointNumber := PointNumber;
//
//      // 6) Přidej do slovníku
//      TPointDictionary.GetInstance.AddPoint(P);
//    end;
//
//    // Vyplnění buněk (stejně pro existující i nově přidaný bod)
//    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
//    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
//    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
//    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
//    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
//
//    // Navigace
//    if StringGrid1.Col < StringGrid1.ColCount - 1 then
//      StringGrid1.Col := StringGrid1.Col + 1
//    else
//    begin
//      if StringGrid1.Row = StringGrid1.RowCount - 1 then
//        StringGrid1.RowCount := StringGrid1.RowCount + 1;
//      StringGrid1.Row := StringGrid1.Row + 1;
//      StringGrid1.Col := 1;
//      if StringGrid1.Row > 2 then
//        StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
//    end;
//  end
//  else if Key = VK_DELETE then
//    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
//end;

procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  P: Point.TPoint;
  Prompts: array[0..4] of string;
  Values: array[0..4] of string;
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  // Načtení čísla bodu...
  PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
  if PointNumber = -1 then
    Exit;  // konec

  // Získání existujícího nebo nového TPoint
  if TPointDictionary.GetInstance.PointExists(PointNumber) then
    P := TPointDictionary.GetInstance.GetPoint(PointNumber)
  else
    P.PointNumber := PointNumber;

  // Příprava polí promptů a defaultních hodnot
  Prompts[0] := 'X souřadnice';    Values[0] := FloatToStr(P.X);
  Prompts[1] := 'Y souřadnice';    Values[1] := FloatToStr(P.Y);
  Prompts[2] := 'Z souřadnice';    Values[2] := FloatToStr(P.Z);
  Prompts[3] := 'Kód kvality';     Values[3] := IntToStr(P.Quality);
  Prompts[4] := 'Popis';           Values[4] := P.Description;

  // Jedno volání InputQuery na všech pět polí
  if not InputQuery(
       Format('Bod %d – doplňte hodnoty', [PointNumber]),
       Prompts,
       Values
     ) then
    Exit;  // uživatel zrušil

  // Načtení zpět do P
  P.X := StrToFloatDef(Values[0], 0);
  P.Y := StrToFloatDef(Values[1], 0);
  P.Z := StrToFloatDef(Values[2], 0);
  P.Quality := StrToIntDef(Values[3], 0);
  P.Description := Values[4];

  // Uložení do singletonu
  TPointDictionary.GetInstance.AddPoint(P);

  // Vyplnění buněk gridu
  StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
  StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
  StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
  StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
  StringGrid1.Cells[8, StringGrid1.Row] := P.Description;

  // Navigace na další buňku nebo řádek...
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
    // pozadí
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
      Brush.Color := clMenuBar
    else
      Brush.Color := clWhite;
    FillRect(Rect);

    Text := StringGrid1.Cells[ACol, ARow];

    if ARow = 0 then
    begin
      // pro hlavičku: vycentruj vodorovně
      TextW := TextWidth(Text);
      X := Rect.Left + (Rect.Right - Rect.Left - TextW) div 2;
      // vertikálně nechám trochu odsazení odshora
      Y := Rect.Top + (Rect.Bottom - Rect.Top - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      // klasické psaní (nebo tu můžeš přidat další podmínky)
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;

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
