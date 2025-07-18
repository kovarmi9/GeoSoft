//unit AddPoint;
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics, System.Generics.Collections,
//  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus, System.Math, ComObj,
//  StringGridValidationUtils, PointsUtilsSingleton, ValidationUtils, System.Classes, Point,
//  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, Vcl.ActnMenus,
//  Vcl.ExtCtrls, System.IOUtils, Vcl.StdCtrls;
//
//type
//  TForm6 = class(TForm)
//    StringGrid1: TStringGrid;
//    StatusBar1: TStatusBar;
//    ControlBar1: TControlBar;
//    MainMenu1: TMainMenu;
//    File1: TMenuItem;
//    File2: TMenuItem;
//    SaveAs1: TMenuItem;
//    SaveAs2: TMenuItem;
//    Import1: TMenuItem;
//    FromTXT1: TMenuItem;
//    FromTXT2: TMenuItem;
//    FromBinary1: TMenuItem;
//    Import2: TMenuItem;
//    oTXT1: TMenuItem;
//    oTXT2: TMenuItem;
//    oBinary1: TMenuItem;
//    OpenDialog1: TOpenDialog;
//    SaveDialog1: TSaveDialog;
//    Button1: TButton;
//    Button2: TButton;
//    procedure FormCreate(Sender: TObject); // Procedura volaná pøi inicializaci formuláøe
//    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracování stisknutí klávesy
//    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
//    procedure UpdateCurrentDirectoryPath;
//    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
//  private
//    { Private declarations }
//  public
//    { Public declarations }
//  end;
//
//var
//  Form6: TForm6;
//
//implementation
//
//{$R *.dfm}
//
//procedure TForm6.FormCreate(Sender: TObject); // Zmìnìno z TForm2 na TForm3
//var
//  P: TPoint;
//  i: Integer;
//begin
//// Nastavení sloupcù a øádkù pro StringGrid1 (tabulka pro zadávání souøadnic)
//  StringGrid1.ColCount := 6; // Poèet sloupcù: Èíslo bodu, X, Y, Z, Popis
//  StringGrid1.RowCount := 2; // Minimálnì 2 øádky (hlavièka + 1 prázdný øádek pro vstup)
//  StringGrid1.FixedRows := 1; // První øádek bude pevný (nemìnný)
//
//  // Nastavení popiskù sloupcù (hlavièky) pro StringGrid1
//  StringGrid1.Cells[0, 0] := 'Èíslo bodu'; // Název sloupce 0
//  StringGrid1.Cells[1, 0] := 'X';          // Název sloupce 1
//  StringGrid1.Cells[2, 0] := 'Y';          // Název sloupce 2
//  StringGrid1.Cells[3, 0] := 'Z';          // Název sloupce 3
//  StringGrid1.Cells[4, 0] := 'Kvalita';    // Název sloupce 4
//  StringGrid1.Cells[5, 0] := 'Popis';      // Název sloupce 4
//
//  // Nastavení výchozích hodnot v prvním øádku pro zadávání bodù
//  StringGrid1.Cells[0, 1] := ''; // Èíslo bodu (prázdná)
//  StringGrid1.Cells[1, 1] := '';  // X souøadnice (prázdná)
//  StringGrid1.Cells[2, 1] := '';  // Y souøadnice (prázdná)
//  StringGrid1.Cells[3, 1] := '';  // Z souøadnice (prázdná)
//  StringGrid1.Cells[4, 1] := '';  // Kvalita (prázdná)
//  StringGrid1.Cells[5, 1] := '';  // Popis (prázdný)
//
//  // --- NOVO: naplníme grid existujícími body ze slovníku ---
//  i := 1;  // zaèínáme na prvním datovém øádku
//  for P in TPointDictionary.GetInstance.Values do
//  begin
//    // zajistíme dostatek øádkù
//    StringGrid1.RowCount := i + 1;
//    // vyplníme sloupce 0..5
//    StringGrid1.Cells[0, i] := IntToStr(P.PointNumber);
//    StringGrid1.Cells[1, i] := FloatToStr(P.X);
//    StringGrid1.Cells[2, i] := FloatToStr(P.Y);
//    StringGrid1.Cells[3, i] := FloatToStr(P.Z);
//    StringGrid1.Cells[4, i] := IntToStr(P.Quality);
//    StringGrid1.Cells[5, i] := P.Description;
//    Inc(i);
//  end;
//
//  StringGrid1.Repaint;
//
//  // Pøiøazení obslužných procedur pro události
//  StringGrid1.OnKeyPress := StringGrid1KeyPress;
//  StringGrid1.OnKeyDown := StringGrid1KeyDown;
//  StringGrid1.OnDrawCell := StringGrid1DrawCell;
//  StringGrid1.OnSelectCell := StringGrid1SelectCell;
//
//  // Aktualizace cesty
//  UpdateCurrentDirectoryPath;
//
//end;
//procedure TForm6.UpdateCurrentDirectoryPath;
//begin
//  if StatusBar1.Panels.Count > 0 then
//    StatusBar1.Panels[0].Text := GetCurrentDir;
//end;
//
//procedure TForm6.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  X, Y, Z: Double;
//  Quality: Integer;
//  Description: string;
//  NewPoint: TPoint;
//begin
//  if (Key = VK_RETURN) or (Key = VK_TAB) then
//  begin
//    Key := 0; // Zamezí dalšímu zpracování Enteru
//
//    // Vyhodnocení výrazu a pøevedení na èíslo
//    if StringGrid1.Col in [1, 2, 3] then
//    begin
//      try
//        StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FloatToStr(EvaluateExpression(StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row]));
//      except
//        on E: Exception do
//          ShowMessage('Chyba ve výrazu: ' + E.Message);
//      end;
//    end;
//
//    // Pøechod na další buòku
//    if StringGrid1.Col < StringGrid1.ColCount - 1 then
//    begin
//      StringGrid1.Col := StringGrid1.Col + 1;
//    end
//    else
//    begin
//      // Pokud poslední sloupec, pøechod na první sloupec dalšího øádku
//      if StringGrid1.Row = StringGrid1.RowCount - 1 then
//
//      StringGrid1.Row := StringGrid1.Row;
//      StringGrid1.Col := 0;
//
//      // Naètení hodnot
//      PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row - 1], -1);
//      X := StrToFloatDef(StringGrid1.Cells[1, StringGrid1.Row - 1], NaN);
//      Y := StrToFloatDef(StringGrid1.Cells[2, StringGrid1.Row - 1], NaN);
//      Z := StrToFloatDef(StringGrid1.Cells[3, StringGrid1.Row - 1], NaN);
//      Quality := StrToIntDef(StringGrid1.Cells[4, StringGrid1.Row - 1], -1);
//      Description := StringGrid1.Cells[5, StringGrid1.Row - 1];
//
//      // Uložení do slovníku pomocí singletonu
//      if (PointNumber <> -1) and (not IsNan(X)) and (not IsNan(Y)) and (not IsNan(Z)) then
//      begin
//        // Použití singletonu pro získání instance TPointDictionary
//        TPointDictionary.GetInstance.AddPoint(TPoint.Create(PointNumber, X, Y, Z, Quality, Description));
//
//        // Kontrola, zda byl bod vložen a uložení do nového bodu
//        if TPointDictionary.GetInstance.PointExists(PointNumber) then
//        begin
//          NewPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
//          ShowMessage(Format('Bod %d byl vložen do ss: X=%.2f, Y=%.2f, Z=%.2f, Kvalita=%d, Popis=%s',
//            [NewPoint.PointNumber, NewPoint.X, NewPoint.Y, NewPoint.Z, NewPoint.Quality, NewPoint.Description]));
//        end
//        else
//          ShowMessage(Format('Bod %d nebyl vložen.', [PointNumber]));
//      end
//      else
//        ShowMessage('Neplatná data, bod nebyl uložen.');
//    end;
//  end
//  else if Key = VK_DELETE then
//  begin
//    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Mazání obsahu buòky
//  end;
//end;
//
//procedure TForm6.StringGrid1KeyPress(Sender: TObject; var Key: Char);
//begin
//  HandleBackspace(StringGrid1, Key);
//  ValidatePointNumber(StringGrid1, Key);
//  ValidateCoordinates(StringGrid1, Key);
//  ValidateQualityCode(StringGrid1, Key);
//end;
//
//procedure TForm6.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//begin
//  with TStringGrid(Sender).Canvas do
//  begin
//    // hlavièka = vždy šedá
//    if ARow < TStringGrid(Sender).FixedRows then
//      Brush.Color := clMenuBar
//    else
//      Brush.Color := clWindow;
//
//    FillRect(Rect);
//
//    // text
//    TextRect(Rect, Rect.Left + 4, Rect.Top + 2,
//      TStringGrid(Sender).Cells[ACol, ARow]);
//  end;
//end;
//
//procedure TForm6.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
//begin
//  // Zablokuj výbìr (a tedy i úpravu) hlavièky
//  CanSelect := ARow <> 0;
//end;
//
//end.

//unit AddPoint;
//
//interface
//
//uses
//  Vcl.Forms,
//  Vcl.Grids,
//  Vcl.StdCtrls,
//  System.SysUtils,
//  Point, Vcl.Dialogs, Vcl.Menus, Vcl.ExtCtrls, Vcl.ComCtrls, System.Classes,
//  Vcl.Controls;  // vaše jednotka, kde je TPoint.Create(validace)
//
//type
//  TForm6 = class(TForm)
//    StringGrid1: TStringGrid;
//    btnOK: TButton;
//    btnCancel: TButton;
//    procedure FormCreate(Sender: TObject);
//  private
//    { Private declarations }
//  public
//    /// <summary>
//    /// Zobrazí dialog pro jedno zadání bodu.
//    /// Vrátí True, pokud uživatel klikne OK,
//    /// a out NewP vrátí validovaný bod.
//    /// </summary>
//    function Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
//  end;
//
//var
//  Form6: TForm6;
//
//implementation
//
//{$R *.dfm}
//
//procedure TForm6.FormCreate(Sender: TObject);
//begin
//  // grid nastavíme na 6 sloupcù (0=èíslo, 1=X,2=Y,3=Z,4=Quality,5=Popis)
//  StringGrid1.ColCount := 6;
//  StringGrid1.RowCount := 2;
//  StringGrid1.FixedRows := 1;
//
//  // hlavièka
//  StringGrid1.Cells[0,0] := 'Èíslo bodu';
//  StringGrid1.Cells[1,0] := 'X';
//  StringGrid1.Cells[2,0] := 'Y';
//  StringGrid1.Cells[3,0] := 'Z';
//  StringGrid1.Cells[4,0] := 'Kvalita';
//  StringGrid1.Cells[5,0] := 'Popis';
//
//  // tlaèítka
//  btnOK.ModalResult := mrOk;
//  btnCancel.ModalResult := mrCancel;
//end;
//
//function TForm6.Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
//begin
//  // pøedešlete èíslo bodu do první buòky
//  StringGrid1.Cells[0,1] := IntToStr(PointNumber);
//
//  // ukažte formu
//  Result := (ShowModal = mrOk);
//  if not Result then
//    Exit;
//
//  // sestavte TPoint (validace v konstruktoru)
//  NewP := TPoint.Create(
//    PointNumber,
//    StrToFloatDef(StringGrid1.Cells[1,1], 0),
//    StrToFloatDef(StringGrid1.Cells[2,1], 0),
//    StrToFloatDef(StringGrid1.Cells[3,1], 0),
//    StrToIntDef(  StringGrid1.Cells[4,1], 0),
//    StringGrid1.Cells[5,1]
//  );
//end;
//
//end.

unit AddPoint;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, Vcl.Controls,
  Point, System.Classes;  // sem dej jednotku, kde je deklarováno TPoint.Create(...)

type
  TForm6 = class(TForm)
    StringGrid1: TStringGrid;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    /// <summary>
    ///  Zobrazí dialog pro zadání jednoho bodu.
    ///  Vrátí True, pokud uživatel potvrdí OK.
    ///  Out NewP je validovaný bod (pomocí konstruktoru TPoint.Create).
    /// </summary>
    function Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

procedure TForm6.FormCreate(Sender: TObject);
var
  c: Integer;
begin
  // Nastavíme grid: 6 sloupcù, 2 øádky, 1 pevný
  StringGrid1.ColCount := 6;
  StringGrid1.RowCount := 2;
  StringGrid1.FixedRows := 1;

  // Hlavièka
  StringGrid1.Cells[0,0] := 'Èíslo bodu';
  StringGrid1.Cells[1,0] := 'X';
  StringGrid1.Cells[2,0] := 'Y';
  StringGrid1.Cells[3,0] := 'Z';
  StringGrid1.Cells[4,0] := 'Kvalita';
  StringGrid1.Cells[5,0] := 'Popis';

  // Tlaèítka jako modální
  btnOK.ModalResult := mrOk;
  btnCancel.ModalResult := mrCancel;

  //Pøepínaní pomocí enteru
  StringGrid1.OnKeyDown := StringGrid1KeyDown;

end;

function TForm6.Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
begin
  // Pøedešleme èíslo bodu do gridu
  StringGrid1.Cells[0,1] := IntToStr(PointNumber);

  // Zobrazíme modálnì
  Result := (ShowModal = mrOk);
  if not Result then
    Exit;

  // Vytvoøíme validovaný bod (validace probíhá v konstruktoru TPoint.Create)
  NewP := TPoint.Create(
    PointNumber,
    StrToFloatDef(StringGrid1.Cells[1,1], 0.0),
    StrToFloatDef(StringGrid1.Cells[2,1], 0.0),
    StrToFloatDef(StringGrid1.Cells[3,1], 0.0),
    StrToIntDef(  StringGrid1.Cells[4,1], 0),
    StringGrid1.Cells[5,1]
  );
end;

procedure TForm6.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;                        // zamezíme defaultnímu „beep“ èi jinému zpracování
    with StringGrid1 do
    begin
      // pokud nejsem v posledním sloupci -> posuò se doprava
      if Col < ColCount - 1 then
        Col := Col + 1
      else
      begin
        // jinak pøejdi na další øádek, první sloupec
        if Row < RowCount - 1 then
          Row := Row + 1;
        Col := 0;
      end;
      // spustíme režim editace v buòce
      EditorMode := True;
    end;
  end;
end;

//procedure TForm6.FormShow(Sender: TObject);
//var
//  c: Integer;
//begin
//  // Vymažeme celý datový øádek (index 1) pøed každým zobrazením
//  for c := 0 to StringGrid1.ColCount - 1 do
//    StringGrid1.Cells[c,1] := '';
//
//  // Nastavíme kurzor do první datové buòky
//  StringGrid1.Row := 1;
//  StringGrid1.Col := 1;
//  StringGrid1.EditorMode := True;
//end;

procedure TForm6.FormShow(Sender: TObject);
var
  c: Integer;
begin
  // Vymažeme jen sloupce 1..n, sloupec 0 (PointNumber) necháme
  for c := 1 to StringGrid1.ColCount - 1 do
    StringGrid1.Cells[c,1] := '';

  // Nastavíme kurzor do první datové buòky pro X
  StringGrid1.Row := 1;
  StringGrid1.Col := 1;
  StringGrid1.EditorMode := True;
end;


end.

