unit PointsManagement2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  StringGridValidationUtils;

type
  TForm3 = class(TForm) // Změněno z TForm2 na TForm3
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject); // Procedura volaná při inicializaci formuláře
    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracování stisknutí klávesy
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); // Procedura pro zpracování stisknutí klávesy
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

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
  StringGrid1.Cells[0, 1] := '1'; // Číslo bodu (výchozí hodnota = 1)
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

procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0; // Zamezit dalšímu zpracování Enteru

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
    end;
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Povolit mazání obsahu buněk
  end;
end;

end.
