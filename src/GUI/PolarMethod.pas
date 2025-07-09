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
//  // Nastaven� z�kladn�ch vlastnost� StringGridu
//  StringGrid1.FixedRows := 1;  // Prvn� ��dek je vyhrazen pro hlavi�ku
//  StringGrid1.FixedCols := 1;  // Prvn� sloupec bude slou�it k ��slov�n� ��dk�
//
//  // Nastaven� n�zv� sloupc� (hlavi�ka)
//  StringGrid1.Cells[1, 0] := '��slo bodu';  // Sloupec 1 � ��slo bodu
//  StringGrid1.Cells[2, 0] := 'Vodorovn� �hel';    // Sloupec 2 � lze pou��t pro dal�� �daje
//  StringGrid1.Cells[3, 0] := 'Vodorovn� vzd�lenost';      // Sloupec 3 � rovn� dle po�adavku
//  StringGrid1.Cells[4, 0] := 'X';            // Sloupec 4 � sou�adnice X
//  StringGrid1.Cells[5, 0] := 'Y';            // Sloupec 5 � sou�adnice Y
//
//  // P��klad pojmenov�n� ��dk� (dle vlastn�ho zad�n� � nap�. po��te�n� a koncov� bod)
//  StringGrid1.Cells[0, 1] := 'Stanoviso';  // ��dek 1
//  StringGrid1.Cells[0, 2] := 'Orientace';  // ��dek 2
//
//  // Nastaven� po��te�n�ho datov�ho ��dku � nap�. prvn� ��dek dat (mimo hlavi�ku a fixovan� ��dky)
//  StringGrid1.Cells[0, 3] := '1';
//
//  // Vykreslen� zm�n
//  StringGrid1.Repaint;
//
//  // P�i�azen� ud�losti pro stisk kl�vesy (Enter, Delete apod.)
//  StringGrid1.OnKeyDown := StringGrid1KeyDown;
//
//  // P�i�azen� ud�losti pro vykreslen� fixn�ch bun�k
//  StringGrid1.OnDrawCell := StringGrid1DrawCell;
//
//  // Zobraz aktu�ln� adres�� ve stavov�m ��dku
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
//    Key := 0; // Zamez� dal��mu zpracov�n� Enteru
//
//    // Na�ten� ��sla bodu z nult�ho sloupce
//    PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row], -1);
//    ShowMessage(Format('Zadan� ��slo bodu: %d', [PointNumber]));
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
//        // Dopln�n� �daj� do dal��ch sloupc�
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
//      ShowMessage('Neplatn� ��slo bodu.');
//    end;
//  end;
//end;
//
//procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//begin
//  with StringGrid1.Canvas do
//  begin
//    // Pokud je bu�ka "fixed" (z�hlav�), nastav�me �ed� pozad�
//    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
//      Brush.Color := clMenuBar
//    else
//      Brush.Color := clWhite;
//
//    FillRect(Rect);
//
//    // Zobraz�me text v bu�ce
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
  // Z�kladn� nastaven� gridu
  StringGrid1.ColCount := 6;    // sloupce 0..5
  StringGrid1.RowCount := 4;    // ��dky 0..3
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Hlavi�ka
  StringGrid1.Cells[1, 0] := '��slo bodu';
  StringGrid1.Cells[2, 0] := 'Vodorovn� �hel';
  StringGrid1.Cells[3, 0] := 'Vodorovn� vzd�lenost';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';

  // Popisky prvn�ch dvou speci�ln�ch ��dk�
  StringGrid1.Cells[0, 1] := 'Stanoviso';
  StringGrid1.Cells[0, 2] := 'Orientace';

  // ��seln� prvn� datov� ��dek
  StringGrid1.Cells[0, 3] := '1';

  // Ud�losti
  StringGrid1.OnKeyDown  := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Zobraz aktu�ln� adres��
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
  P: Point.TPoint;  // explicitn� z tv� jednotky Point
begin
  if Key = VK_RETURN then
  begin
    Key := 0;  // potla�� default chov�n�

    // Na�ti ��slo bodu z prvn�ho sloupce
    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
    if PointNumber = -1 then
    begin
      ShowMessage('Neplatn� ��slo bodu.');
      Exit;
    end;

    // Pokud bod existuje ve slovn�ku, dopl�me �daje
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

    // Navigace: dal�� bu�ka nebo nov� ��dek
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
      StringGrid1.Col := StringGrid1.Col + 1
    else
    begin
      // Pokud je to posledn� ��dek, p�id�me nov�
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
        StringGrid1.RowCount := StringGrid1.RowCount + 1;
      // p�echod na dal�� ��dek, prvn� datov� sloupec
      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 1;
      // o��slov�n� nult�ho sloupce
      if StringGrid1.Row > 2 then
        StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
    end;
  end
  else if Key = VK_DELETE then
  begin
    // Vyma� obsah aktu�ln� bu�ky
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
  end;
end;

procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  with StringGrid1.Canvas do
  begin
    // Barvy pozad� pro hlavi�ky vs. data
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
      Brush.Color := clMenuBar
    else
      Brush.Color := clWhite;
    FillRect(Rect);

    // R�me�ek (voliteln�, odkomentuj pokud chce�)
    // Pen.Color := clNavy;
    // Rectangle(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);

    // Vyps�n� textu
    TextRect(Rect, Rect.Left + 4, Rect.Top + 2,
      StringGrid1.Cells[ACol, ARow]);
  end;
end;

end.

