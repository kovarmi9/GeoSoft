//unit PolarMethod;
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
//  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, PointsUtilsSingleton, Point,
//  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls;
//
//type
//  TForm3 = class(TForm)
//    ToolBar2: TToolBar;
//    ComboBox4: TComboBox;
//    ToolButton3: TToolButton;
//    ComboBox5: TComboBox;
//    ToolButton2: TToolButton;
//    ComboBox6: TComboBox;
//    Panel1: TPanel;
//    StatusBar1: TStatusBar;
//    StringGrid1: TStringGrid;
//    ToolBar1: TToolBar;
//    procedure FormCreate(Sender: TObject);
//    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
//    procedure UpdateCurrentDirectoryPath;
//  private
//    { Private declarations }
//  public
//    { Public declarations }
//  end;
//
//var
//  Form3: TForm3;
//
//implementation
//
//{$R *.dfm}
//
//procedure TForm3.FormCreate(Sender: TObject);
//begin
//  // Nastavení základních vlastností StringGridu
//  StringGrid1.FixedRows := 1;  // První øádek je vyhrazen pro hlavièku
//  StringGrid1.FixedCols := 1;  // První sloupec bude sloužit k èíslování øádkù
//
//  // Nastavení názvù sloupcù (hlavièka)
//  StringGrid1.Cells[1, 0] := 'èíslo bodu';  // Sloupec 1 – èíslo bodu
//  StringGrid1.Cells[2, 0] := 'Vodorovný úhel';    // Sloupec 2 – lze použít pro další údaje
//  StringGrid1.Cells[3, 0] := 'Vodorovná vzdálenost';      // Sloupec 3 – rovnìž dle požadavku
//  StringGrid1.Cells[4, 0] := 'X';            // Sloupec 4 – souøadnice X
//  StringGrid1.Cells[5, 0] := 'Y';            // Sloupec 5 – souøadnice Y
//
//  // Pøíklad pojmenování øádkù (dle vlastního zadání – napø. poèáteèní a koncový bod)
//  StringGrid1.Cells[0, 1] := 'Stanoviso';  // Øádek 1
//  StringGrid1.Cells[0, 2] := 'Orientace';  // Øádek 2
//
//  // Nastavení poèáteèního datového øádku – napø. první øádek dat (mimo hlavièku a fixované øádky)
//  StringGrid1.Cells[0, 3] := '1';
//
//  // Vykreslení zmìn
//  StringGrid1.Repaint;
//
//  // Pøiøazení události pro stisk klávesy (Enter, Delete apod.)
//  StringGrid1.OnKeyDown := StringGrid1KeyDown;
//
//  // Pøiøazení události pro vykreslení fixních bunìk
//  StringGrid1.OnDrawCell := StringGrid1DrawCell;
//
//  // Zobraz aktuální adresáø ve stavovém øádku
//  UpdateCurrentDirectoryPath;
//end;
//
//procedure TForm3.UpdateCurrentDirectoryPath;
//begin
//  if StatusBar1.Panels.Count > 0 then
//    StatusBar1.Panels[0].Text := GetCurrentDir;
//end;
//
//procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  Point: TPoint;
//begin
//  if Key = VK_RETURN then
//  begin
//    Key := 0; // Zamezí dalšímu zpracování Enteru
//
//    // Naètení èísla bodu z nultého sloupce
//    PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row], -1);
//    ShowMessage(Format('Zadané èíslo bodu: %d', [PointNumber]));
//
//    // Kontrola, zda bod existuje v seznamu
//    if PointNumber <> -1 then
//    begin
//      if TPointDictionary.GetInstance.PointExists(PointNumber) then
//      begin
//        Point := TPointDictionary.GetInstance.GetPoint(PointNumber);
//        ShowMessage(Format('Bod %d nalezen: X=%.2f, Y=%.2f, Z=%.2f, Kvalita=%d, Popis=%s',
//          [Point.PointNumber, Point.X, Point.Y, Point.Z, Point.Quality, Point.Description]));
//
//        // Doplnìní údajù do dalších sloupcù
//        StringGrid1.Cells[1, StringGrid1.Row] := FloatToStr(Point.X);
//        StringGrid1.Cells[2, StringGrid1.Row] := FloatToStr(Point.Y);
//        StringGrid1.Cells[3, StringGrid1.Row] := FloatToStr(Point.Z);
//        StringGrid1.Cells[4, StringGrid1.Row] := IntToStr(Point.Quality);
//        StringGrid1.Cells[5, StringGrid1.Row] := Point.Description;
//      end
//      else
//      begin
//        ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]));
//      end;
//    end
//    else
//    begin
//      ShowMessage('Neplatné èíslo bodu.');
//    end;
//  end;
//end;
//
//procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//begin
//  with StringGrid1.Canvas do
//  begin
//    // Pokud je buòka "fixed" (záhlaví), nastavíme šedé pozadí
//    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
//      Brush.Color := clMenuBar
//    else
//      Brush.Color := clWhite;
//
//    FillRect(Rect);
//
//    // Zobrazíme text v buòce
//    TextRect(Rect, Rect.Left + 4, Rect.Top + 2, StringGrid1.Cells[ACol, ARow]);
//  end;
//end;
//
//end.

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
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure UpdateCurrentDirectoryPath;
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.FormCreate(Sender: TObject);
begin
  // Základní nastavení gridu
  StringGrid1.ColCount := 6;    // sloupce 0..5
  StringGrid1.RowCount := 4;    // øádky 0..3
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Hlavièka
  StringGrid1.Cells[1, 0] := 'èíslo bodu';
  StringGrid1.Cells[2, 0] := 'Vodorovný úhel';
  StringGrid1.Cells[3, 0] := 'Vodorovná vzdálenost';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';

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
      StringGrid1.Cells[1, StringGrid1.Row] := FloatToStr(P.X);
      StringGrid1.Cells[2, StringGrid1.Row] := FloatToStr(P.Y);
      StringGrid1.Cells[3, StringGrid1.Row] := FloatToStr(P.Z);
      StringGrid1.Cells[4, StringGrid1.Row] := IntToStr(P.Quality);
      StringGrid1.Cells[5, StringGrid1.Row] := P.Description;
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

procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  with StringGrid1.Canvas do
  begin
    // Barvy pozadí pro hlavièky vs. data
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
      Brush.Color := clMenuBar
    else
      Brush.Color := clWhite;
    FillRect(Rect);

    // Rámeèek (volitelné, odkomentuj pokud chceš)
    // Pen.Color := clNavy;
    // Rectangle(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);

    // Vypsání textu
    TextRect(Rect, Rect.Left + 4, Rect.Top + 2,
      StringGrid1.Cells[ACol, ARow]);
  end;
end;

end.

