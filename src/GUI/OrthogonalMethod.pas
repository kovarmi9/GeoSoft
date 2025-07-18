//unit OrthogonalMethod;
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
//  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
//  PointsUtilsSingleton, Point, GeoAlgorithmBase, Vcl.StdCtrls, Vcl.ActnMan,
//  Vcl.ActnCtrls, Vcl.ToolWin, Vcl.ComCtrls, Vcl.ExtCtrls;
//
//type
//  TForm4 = class(TForm)
//    StringGrid1: TStringGrid;
//    ToolBar1: TToolBar;
//    ToolBar2: TToolBar;
//    ComboBox1: TComboBox;
//    ComboBox2: TComboBox;
//    ComboBox3: TComboBox;
//    ToolButton3: TToolButton;
//    ToolButton2: TToolButton;
//    Panel1: TPanel;
//    StatusBar1: TStatusBar;
//    procedure FormCreate(Sender: TObject); // Inicializace formul��e a nastaven� gridu
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
//  Form4: TForm4;
//
//implementation
//
//{$R *.dfm}
//
//procedure TForm4.FormCreate(Sender: TObject);
//begin
//  // Nastaven� z�kladn�ch vlastnost� StringGridu
//  StringGrid1.FixedRows := 1;  // Prvn� ��dek je vyhrazen pro hlavi�ku
//  StringGrid1.FixedCols := 1;  // Prvn� sloupec bude slou�it k ��slov�n� ��dk�
//
//  // Nastaven� n�zv� sloupc� (hlavi�ka)
//  StringGrid1.Cells[1, 0] := '��slo bodu';  // Sloupec 1 � ��slo bodu
//  StringGrid1.Cells[2, 0] := 'stani�en�';    // Sloupec 2 � lze pou��t pro dal�� �daje
//  StringGrid1.Cells[3, 0] := 'kolmice';      // Sloupec 3 � rovn� dle po�adavku
//  StringGrid1.Cells[4, 0] := 'X';            // Sloupec 4 � sou�adnice X
//  StringGrid1.Cells[5, 0] := 'Y';            // Sloupec 5 � sou�adnice Y
//  StringGrid1.Cells[6, 0] := 'Z';
//  StringGrid1.Cells[7, 0] := 'Kvalita';
//  StringGrid1.Cells[8, 0] := 'Popis';
//
//  // P��klad pojmenov�n� ��dk� (dle vlastn�ho zad�n� � nap�. po��te�n� a koncov� bod)
//  StringGrid1.Cells[0, 1] := 'P';  // ��dek 1
//  StringGrid1.Cells[0, 2] := 'K';  // ��dek 2
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
//procedure TForm4.UpdateCurrentDirectoryPath;
//begin
//  if StatusBar1.Panels.Count > 0 then
//    StatusBar1.Panels[0].Text := GetCurrentDir;
//end;
//
//procedure TForm4.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
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
//procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  Pt: TPoint;
//begin
//  if Key = VK_RETURN then
//  begin
//    Key := 0; // Zamezen� v�choz�ho chov�n� Enteru
//
//    // Na�ten� ��sla bodu ze sloupce 1 aktu�ln�ho ��dku
//    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
//    if PointNumber = -1 then
//    begin
//      ShowMessage('Neplatn� ��slo bodu.');
//      Exit;
//    end;
//
//    // Automatick� vypln�n� sou�adnic, pokud bod existuje ve slovn�ku
//    if TPointDictionary.GetInstance.PointExists(PointNumber) then
//    begin
//      Pt := TPointDictionary.GetInstance.GetPoint(PointNumber);
//      StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(Pt.X);
//      StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(Pt.Y);
//    end
//    else if (StringGrid1.Row = 1) or (StringGrid1.Row = 2) then
//      ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]));
//
//    // Logika navigov�n�
//    if StringGrid1.Col < StringGrid1.ColCount - 1 then
//    begin
//      // Pokud nen� aktu�ln� bu�ka posledn� v ��dku, posun na dal�� sloupec
//      StringGrid1.Col := StringGrid1.Col + 1;
//    end
//    else
//    begin
//      // Pokud posledn� sloupec, p�id� se nov� ��dek, pokud je aktu�ln� ��dek posledn�
//      if StringGrid1.Row = StringGrid1.RowCount - 1 then
//        StringGrid1.RowCount := StringGrid1.RowCount + 1; // p�id�n� nov�ho ��dku
//
//      // P�esuneme se na n�sleduj�c� ��dek a prvn� sloupec
//      StringGrid1.Row := StringGrid1.Row + 1;
//      StringGrid1.Col := 1;
//
//      // Automatick� ��slov�n� nult�ho sloupce
//      if StringGrid1.Row > 2 then
//        StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
//    end;
//  end
//  else if Key = VK_DELETE then
//  begin
//    // P�i stisku Delete vyma�eme obsah aktu�ln� bu�ky
//    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
//  end;
//end;
//
//end.

unit OrthogonalMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  PointsUtilsSingleton, AddPoint,
  Point, GeoAlgorithmBase, Vcl.StdCtrls, Vcl.ActnMan,
  Vcl.ActnCtrls, Vcl.ToolWin, Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TForm4 = class(TForm)
    StringGrid1: TStringGrid;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    ToolButton3: TToolButton;
    ToolButton2: TToolButton;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure UpdateCurrentDirectoryPath;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.FormCreate(Sender: TObject);
begin
  // Nastaven� z�kladn�ch vlastnost� StringGridu
  StringGrid1.ColCount := 9;    // sloupce 0..8
  StringGrid1.RowCount := 4;    // ��dky 0..3
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Hlavi�ka
  StringGrid1.Cells[1, 0] := '��slo bodu';
  StringGrid1.Cells[2, 0] := 'stani�en�';
  StringGrid1.Cells[3, 0] := 'kolmice';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';
  StringGrid1.Cells[6, 0] := 'Z';
  StringGrid1.Cells[7, 0] := 'Kvalita';
  StringGrid1.Cells[8, 0] := 'Popis';

  // Popisky ��dk�
  StringGrid1.Cells[0, 1] := 'P';
  StringGrid1.Cells[0, 2] := 'K';
  StringGrid1.Cells[0, 3] := '1';

  // Ud�losti
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Stavov� ��dek
  UpdateCurrentDirectoryPath;
end;

procedure TForm4.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm4.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  with StringGrid1.Canvas do
  begin
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
      Brush.Color := clMenuBar
    else
      Brush.Color := clWhite;
    FillRect(Rect);
    TextRect(Rect, Rect.Left + 4, Rect.Top + 2, StringGrid1.Cells[ACol, ARow]);
  end;
end;

procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  P: TPoint;
  UserChoice: Integer;
  dlg: TForm6;
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
    if PointNumber = -1 then
    begin
      ShowMessage('Neplatn� ��slo bodu.');
      Exit;
    end;

//    // Pokud bod existuje, na�ti; jinak nab�dni p�id�n�
//    if TPointDictionary.GetInstance.PointExists(PointNumber) then
//      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
//    else
//    begin
//      UserChoice := MessageDlg(
//        Format('Bod %d nebyl nalezen. P�ejete si jej p�idat?', [PointNumber]),
//        mtConfirmation, [mbYes, mbNo], 0);
//      if UserChoice = mrYes then
//      begin
//        Form6.ShowModal;
//        // Vytvo�� nov� record TPoint s v�choz�mi hodnotami
//        P.PointNumber := PointNumber;
//        P.X := 0;
//        P.Y := 0;
//        P.Z := 0;
//        P.Quality := 0;
//        P.Description := '';
//        // P�id� ho do slovn�ku
//        TPointDictionary.GetInstance.AddPoint(P);
//      end
//      else
//        Exit;
//    end;

   // Pokud bod existuje, na�ti; jinak otev�i dialog pro vlo�en� nov�ho
    if TPointDictionary.GetInstance.PointExists(PointNumber) then
      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
    else
    begin
      dlg := TForm6.Create(Self);
      try
        // Execute automaticky vy�ist� ��dek, dopln� ��slo bodu a �ek� na OK/Cancel
        if not dlg.Execute(PointNumber, P) then
          Exit; // u�ivatel zru�il
        // nov� bod P je validov�n konstrukc� TPoint.Create uvnit� Execute
        TPointDictionary.GetInstance.AddPoint(P);
      finally
        dlg.Free;
      end;
    end;

    // Vypl� bu�ky
    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;

    // Navigace
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
  end
  else if Key = VK_DELETE then
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
end;

//procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  P: TPoint;
//  dlg: TForm6;
//begin
//  if Key <> VK_RETURN then
//    Exit;
//  Key := 0;
//
//  PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
//  if PointNumber = -1 then
//  begin
//    ShowMessage('Neplatn� ��slo bodu.');
//    Exit;
//  end;
//
//  // pokud bod existuje, jen ho na�t�te
//  if TPointDictionary.GetInstance.PointExists(PointNumber) then
//  begin
//    P := TPointDictionary.GetInstance.GetPoint(PointNumber);
//  end
//  else
//  begin
//    // jinak otev�ete dialog pro zad�n� jednoho bodu
//    dlg := TForm6.Create(Self);
//    try
//      if not dlg.Execute(PointNumber, P) then
//        Exit; // u�ivatel zru�il
//      // do slovn�ku p�idejte validovan� bod
//      TPointDictionary.GetInstance.AddPoint(P);
//    finally
//      dlg.Free;
//    end;
//  end;
//
//  // vypln�n� bun�k v gridu
//  StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
//  StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
//  StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
//  StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
//  StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
//
//  // navigace na dal�� bu�ku/��dek
//  if StringGrid1.Col < StringGrid1.ColCount - 1 then
//    StringGrid1.Col := StringGrid1.Col + 1
//  else
//  begin
//    if StringGrid1.Row = StringGrid1.RowCount - 1 then
//      StringGrid1.RowCount := StringGrid1.RowCount + 1;
//    StringGrid1.Row := StringGrid1.Row + 1;
//    StringGrid1.Col := 1;
//    if StringGrid1.Row > 2 then
//      StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
//  end;
//end;


end.

