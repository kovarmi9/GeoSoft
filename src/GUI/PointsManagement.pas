unit PointsManagement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus, System.Math, ComObj,
  StringGridValidationUtils, PointsUtils, ValidationUtils, System.Classes, Point;// in '..\Utils\ValidationUtils.pas';

type
  TForm3 = class(TForm) // Změněno z TForm2 na TForm3
    StringGrid1: TStringGrid;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    File2: TMenuItem;
    SaveAs1: TMenuItem;
    SaveAs2: TMenuItem;
    OpenDialog1: TOpenDialog;
    procedure FormCreate(Sender: TObject); // Procedura volaná při inicializaci formuláře
    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracování stisknutí klávesy
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure File2Click(Sender: TObject);
    procedure SaveAs1Click(Sender: TObject); // Procedura pro zpracování stisknutí klávesy
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;
  PointDict: TPointDictionary;
  Point_: TPoint;

implementation

{$R *.dfm}

procedure TForm3.File2Click(Sender: TObject);
begin
  // otevřít
end;

procedure TForm3.FormCreate(Sender: TObject); // Změněno z TForm2 na TForm3
begin
  // Nastavení sloupců a řádků pro StringGrid1 (tabulka pro zadávání souřadnic)
  StringGrid1.ColCount := 6; // Počet sloupců: Číslo bodu, X, Y, Z, Popis
  StringGrid1.RowCount := 2; // Minimálně 2 řádky (hlavička + 1 prázdný řádek pro vstup)
  StringGrid1.FixedRows := 1; // První řádek bude pevný (neměnný)

  // Nastavení popisků sloupců (hlavičky) pro StringGrid1
  StringGrid1.Cells[0, 0] := 'Číslo bodu'; // Název sloupce 0
  StringGrid1.Cells[1, 0] := 'X';          // Název sloupce 1
  StringGrid1.Cells[2, 0] := 'Y';          // Název sloupce 2
  StringGrid1.Cells[3, 0] := 'Z';          // Název sloupce 3
  StringGrid1.Cells[4, 0] := 'Kvalita';    // Název sloupce 4
  StringGrid1.Cells[5, 0] := 'Popis';      // Název sloupce 4

  // Nastavení výchozích hodnot v prvním řádku pro zadávání bodů
  StringGrid1.Cells[0, 1] := ''; // Číslo bodu (prázdná)
  StringGrid1.Cells[1, 1] := '';  // X souřadnice (prázdná)
  StringGrid1.Cells[2, 1] := '';  // Y souřadnice (prázdná)
  StringGrid1.Cells[3, 1] := '';  // Z souřadnice (prázdná)
  StringGrid1.Cells[4, 1] := '';  // Kvalita (prázdná)
  StringGrid1.Cells[5, 1] := '';  // Popis (prázdný)

  StringGrid1.Repaint;

  // Přiřazení obslužných procedur pro události
  StringGrid1.OnKeyPress := StringGrid1KeyPress;
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
end;

procedure TForm3.StringGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  HandleBackspace(StringGrid1, Key);
  ValidatePointNumber(StringGrid1, Key);
  ValidateCoordinates(StringGrid1, Key);
  ValidateQualityCode(StringGrid1, Key);
end;

procedure TForm3.SaveAs1Click(Sender: TObject);
begin
  // uložit
end;

procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  X, Y, Z: Double;
  Quality: Integer;
  Description: string;
  NewPoint: TPoint;
  Expr: string;
  Result: Double;
begin
  if Key = VK_RETURN then
  begin
    Key := 0; // Zamezí dalšímu zpracování Enteru

    // Vyhodnocení výrazu a vyplnění výsledků
    if StringGrid1.Col in [1, 2, 3] then
    begin
      Expr := StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row];
      try
        Result := EvaluateExpression(Expr);
        StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FloatToStr(Result);
      except
        on E: Exception do
          ShowMessage('Chyba při vyhodnocování výrazu: ' + E.Message);
      end;
    end;

    // Přechod na další buňku
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
    begin
      StringGrid1.Col := StringGrid1.Col + 1;
    end
    else
    begin
      // Pokud poslední sloupec, přechod na první sloupec dalšího řádku
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
      begin
        // Pokud poslední řádek, přidat nový řádek
        StringGrid1.RowCount := StringGrid1.RowCount + 1;
      end;
      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 0;
      // Získání hodnot z předchozí řádky
      PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row], 0);
      X := StrToFloatDef(StringGrid1.Cells[1, StringGrid1.Row], 0.0);
      Y := StrToFloatDef(StringGrid1.Cells[2, StringGrid1.Row], 0.0);
      Z := StrToFloatDef(StringGrid1.Cells[3, StringGrid1.Row], 0.0);
      Quality := StrToIntDef(StringGrid1.Cells[4, StringGrid1.Row], 0);
      Description := StringGrid1.Cells[5, StringGrid1.Row];
    end;
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Mazání obsahu buněk
  end;
end;

//procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  X, Y, Z: Double;
//  Quality: Integer;
//  Description: string;
//  NewPoint: TPoint;
//  Expr: string;
//  Result: Double;
//begin
//  if Key = VK_RETURN then
//  begin
//    Key := 0; // Zamezí dalšímu zpracování Enteru
//
//    // Pokud je v aktuálním řádku vyplněn alespoň jeden sloupec (např. X, Y, Z)
//    if StringGrid1.Cells[1, StringGrid1.Row] <> '' then
//    begin
//      // Získáme hodnoty z mřížky
//      PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row], 0);
//      X := StrToFloatDef(StringGrid1.Cells[1, StringGrid1.Row], 0.0);
//      Y := StrToFloatDef(StringGrid1.Cells[2, StringGrid1.Row], 0.0);
//      Z := StrToFloatDef(StringGrid1.Cells[3, StringGrid1.Row], 0.0);
//      Quality := StrToIntDef(StringGrid1.Cells[4, StringGrid1.Row], 0);
//      Description := StringGrid1.Cells[5, StringGrid1.Row];
//
//      // Validace - kontrola, zda jsou všechny hodnoty vyplněny
//      if (PointNumber = 0) or (X = 0) or (Y = 0) or (Z = 0) then
//      begin
//        ShowMessage('Chybí některé údaje! Zkontrolujte všechny hodnoty.');
//        Exit;  // Ukončení procedury, pokud nejsou všechna data platná
//      end;
//
//      // Vytvoření nového bodu
//      NewPoint := TPoint.Create(PointNumber, X, Y, Z, Quality, Description);
//
//      // Kontrola, zda bod již existuje v slovníku
//      if PointDict.PointExists(PointNumber) then
//      begin
//        // Pokud bod existuje, aktualizujeme ho
//        PointDict.UpdatePoint(NewPoint);
//        ShowMessage('Bod byl úspěšně aktualizován.');
//      end
//      else
//      begin
//        // Pokud bod neexistuje, přidáme ho do slovníku
//        PointDict.AddPoint(NewPoint);
//        ShowMessage('Bod byl úspěšně přidán.');
//      end;
//    end;
//
//    // Přechod na další buňku
//    if StringGrid1.Col < StringGrid1.ColCount - 1 then
//    begin
//      StringGrid1.Col := StringGrid1.Col + 1;
//    end
//    else
//    begin
//      // Pokud je poslední sloupec, přechod na první sloupec dalšího řádku
//      if StringGrid1.Row = StringGrid1.RowCount - 1 then
//      begin
//        // Pokud poslední řádek, přidat nový řádek
//        StringGrid1.RowCount := StringGrid1.RowCount + 1;
//      end;
//      StringGrid1.Row := StringGrid1.Row + 1;
//      StringGrid1.Col := 0;
//    end;
//  end
//  else if Key = VK_DELETE then
//  begin
//    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Mazání obsahu buněk
//  end;
//end;

end.
