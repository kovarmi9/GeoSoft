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
//    procedure FormCreate(Sender: TObject); // Inicializace formuláøe a nastavení gridu
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
//  // Nastavení základních vlastností StringGridu
//  StringGrid1.FixedRows := 1;  // První øádek je vyhrazen pro hlavièku
//  StringGrid1.FixedCols := 1;  // První sloupec bude sloužit k èíslování øádkù
//
//  // Nastavení názvù sloupcù (hlavièka)
//  StringGrid1.Cells[1, 0] := 'èíslo bodu';  // Sloupec 1 – èíslo bodu
//  StringGrid1.Cells[2, 0] := 'stanièení';    // Sloupec 2 – lze použít pro další údaje
//  StringGrid1.Cells[3, 0] := 'kolmice';      // Sloupec 3 – rovnìž dle požadavku
//  StringGrid1.Cells[4, 0] := 'X';            // Sloupec 4 – souøadnice X
//  StringGrid1.Cells[5, 0] := 'Y';            // Sloupec 5 – souøadnice Y
//  StringGrid1.Cells[6, 0] := 'Z';
//  StringGrid1.Cells[7, 0] := 'Kvalita';
//  StringGrid1.Cells[8, 0] := 'Popis';
//
//  // Pøíklad pojmenování øádkù (dle vlastního zadání – napø. poèáteèní a koncový bod)
//  StringGrid1.Cells[0, 1] := 'P';  // Øádek 1
//  StringGrid1.Cells[0, 2] := 'K';  // Øádek 2
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
//procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  Pt: TPoint;
//begin
//  if Key = VK_RETURN then
//  begin
//    Key := 0; // Zamezení výchozího chování Enteru
//
//    // Naètení èísla bodu ze sloupce 1 aktuálního øádku
//    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
//    if PointNumber = -1 then
//    begin
//      ShowMessage('Neplatné èíslo bodu.');
//      Exit;
//    end;
//
//    // Automatické vyplnìní souøadnic, pokud bod existuje ve slovníku
//    if TPointDictionary.GetInstance.PointExists(PointNumber) then
//    begin
//      Pt := TPointDictionary.GetInstance.GetPoint(PointNumber);
//      StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(Pt.X);
//      StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(Pt.Y);
//    end
//    else if (StringGrid1.Row = 1) or (StringGrid1.Row = 2) then
//      ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]));
//
//    // Logika navigování
//    if StringGrid1.Col < StringGrid1.ColCount - 1 then
//    begin
//      // Pokud není aktuální buòka poslední v øádku, posun na další sloupec
//      StringGrid1.Col := StringGrid1.Col + 1;
//    end
//    else
//    begin
//      // Pokud poslední sloupec, pøidá se nový øádek, pokud je aktuální øádek poslední
//      if StringGrid1.Row = StringGrid1.RowCount - 1 then
//        StringGrid1.RowCount := StringGrid1.RowCount + 1; // pøidání nového øádku
//
//      // Pøesuneme se na následující øádek a první sloupec
//      StringGrid1.Row := StringGrid1.Row + 1;
//      StringGrid1.Col := 1;
//
//      // Automatické èíslování nultého sloupce
//      if StringGrid1.Row > 2 then
//        StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
//    end;
//  end
//  else if Key = VK_DELETE then
//  begin
//    // Pøi stisku Delete vymažeme obsah aktuální buòky
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
  // Nastavení základních vlastností StringGridu
  StringGrid1.ColCount := 9;    // sloupce 0..8
  StringGrid1.RowCount := 4;    // øádky 0..3
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Hlavièka
  StringGrid1.Cells[1, 0] := 'èíslo bodu';
  StringGrid1.Cells[2, 0] := 'stanièení';
  StringGrid1.Cells[3, 0] := 'kolmice';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';
  StringGrid1.Cells[6, 0] := 'Z';
  StringGrid1.Cells[7, 0] := 'Kvalita';
  StringGrid1.Cells[8, 0] := 'Popis';

  // Popisky øádkù
  StringGrid1.Cells[0, 1] := 'P';
  StringGrid1.Cells[0, 2] := 'K';
  StringGrid1.Cells[0, 3] := '1';

  // Události
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Stavový øádek
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
      ShowMessage('Neplatné èíslo bodu.');
      Exit;
    end;

//    // Pokud bod existuje, naèti; jinak nabídni pøidání
//    if TPointDictionary.GetInstance.PointExists(PointNumber) then
//      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
//    else
//    begin
//      UserChoice := MessageDlg(
//        Format('Bod %d nebyl nalezen. Pøejete si jej pøidat?', [PointNumber]),
//        mtConfirmation, [mbYes, mbNo], 0);
//      if UserChoice = mrYes then
//      begin
//        Form6.ShowModal;
//        // Vytvoøí nový record TPoint s výchozími hodnotami
//        P.PointNumber := PointNumber;
//        P.X := 0;
//        P.Y := 0;
//        P.Z := 0;
//        P.Quality := 0;
//        P.Description := '';
//        // Pøidá ho do slovníku
//        TPointDictionary.GetInstance.AddPoint(P);
//      end
//      else
//        Exit;
//    end;

   // Pokud bod existuje, naèti; jinak otevøi dialog pro vložení nového
    if TPointDictionary.GetInstance.PointExists(PointNumber) then
      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
    else
    begin
      dlg := TForm6.Create(Self);
      try
        // Execute automaticky vyèistí øádek, doplní èíslo bodu a èeká na OK/Cancel
        if not dlg.Execute(PointNumber, P) then
          Exit; // uživatel zrušil
        // nový bod P je validován konstrukcí TPoint.Create uvnitø Execute
        TPointDictionary.GetInstance.AddPoint(P);
      finally
        dlg.Free;
      end;
    end;

    // Vyplò buòky
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
//    ShowMessage('Neplatné èíslo bodu.');
//    Exit;
//  end;
//
//  // pokud bod existuje, jen ho naètìte
//  if TPointDictionary.GetInstance.PointExists(PointNumber) then
//  begin
//    P := TPointDictionary.GetInstance.GetPoint(PointNumber);
//  end
//  else
//  begin
//    // jinak otevøete dialog pro zadání jednoho bodu
//    dlg := TForm6.Create(Self);
//    try
//      if not dlg.Execute(PointNumber, P) then
//        Exit; // uživatel zrušil
//      // do slovníku pøidejte validovaný bod
//      TPointDictionary.GetInstance.AddPoint(P);
//    finally
//      dlg.Free;
//    end;
//  end;
//
//  // vyplnìní bunìk v gridu
//  StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
//  StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
//  StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
//  StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
//  StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
//
//  // navigace na další buòku/øádek
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

