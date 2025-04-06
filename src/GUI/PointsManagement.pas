﻿unit PointsManagement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus, System.Math, ComObj,
  StringGridValidationUtils, PointsUtilsSingleton, ValidationUtils, System.Classes, Point;// in '..\Utils\ValidationUtils.pas';

type
  TForm2 = class(TForm)
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
  Form2: TForm2;
  PointDict: TPointDictionary;
  Point: TPoint;

implementation

{$R *.dfm}

procedure TForm2.File2Click(Sender: TObject);
begin
  // otevřít
end;

procedure TForm2.FormCreate(Sender: TObject); // Změněno z TForm2 na TForm3
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

procedure TForm2.StringGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  HandleBackspace(StringGrid1, Key);
  ValidatePointNumber(StringGrid1, Key);
  ValidateCoordinates(StringGrid1, Key);
  ValidateQualityCode(StringGrid1, Key);
end;

procedure TForm2.SaveAs1Click(Sender: TObject);
begin
  // uložit
end;

procedure TForm2.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  X, Y, Z: Double;
  Quality: Integer;
  Description: string;
  NewPoint: TPoint;
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    Key := 0; // Zamezí dalšímu zpracování Enteru

    // Vyhodnocení výrazu a převedení na číslo
    if StringGrid1.Col in [1, 2, 3] then
    begin
      try
        StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FloatToStr(EvaluateExpression(StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row]));
      except
        on E: Exception do
          ShowMessage('Chyba ve výrazu: ' + E.Message);
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

      // Načtení hodnot
      PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row - 1], -1);
      X := StrToFloatDef(StringGrid1.Cells[1, StringGrid1.Row - 1], NaN);
      Y := StrToFloatDef(StringGrid1.Cells[2, StringGrid1.Row - 1], NaN);
      Z := StrToFloatDef(StringGrid1.Cells[3, StringGrid1.Row - 1], NaN);
      Quality := StrToIntDef(StringGrid1.Cells[4, StringGrid1.Row - 1], -1);
      Description := StringGrid1.Cells[5, StringGrid1.Row - 1];

      // Uložení do slovníku pomocí singletonu
      if (PointNumber <> -1) and (not IsNan(X)) and (not IsNan(Y)) and (not IsNan(Z)) then
      begin
        // Použití singletonu pro získání instance TPointDictionary
        TPointDictionary.GetInstance.AddPoint(TPoint.Create(PointNumber, X, Y, Z, Quality, Description));

        // Kontrola, zda byl bod vložen a uložení do nového bodu
        if TPointDictionary.GetInstance.PointExists(PointNumber) then
        begin
          NewPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
          ShowMessage(Format('Bod %d byl vložen do ss: X=%.2f, Y=%.2f, Z=%.2f, Kvalita=%d, Popis=%s',
            [NewPoint.PointNumber, NewPoint.X, NewPoint.Y, NewPoint.Z, NewPoint.Quality, NewPoint.Description]));
        end
        else
          ShowMessage(Format('Bod %d nebyl vložen.', [PointNumber]));
      end
      else
        ShowMessage('Neplatná data, bod nebyl uložen.');
    end;
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Mazání obsahu buňky
  end;
end;

end.
