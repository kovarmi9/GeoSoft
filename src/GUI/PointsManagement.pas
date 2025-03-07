unit PointsManagement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  StringGridValidationUtils;

type
  TForm2 = class(TForm)
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject); // Procedura volaná pøi inicializaci formuláøe
    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracování stisknutí klávesy
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); // Procedura pro zpracování stisknutí klávesy
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.FormCreate(Sender: TObject);
begin
  // Nastavení sloupcù a øádkù pro StringGrid1 (tabulka pro zadávání souøadnic)
  StringGrid1.ColCount := 6; // Poèet sloupcù: Èíslo bodu, X, Y, Z, Popis
  StringGrid1.RowCount := 2; // Minimálnì 2 øádky (hlavièka + 1 prázdný øádek pro vstup)
  StringGrid1.FixedRows := 1; // První øádek bude pevný (nemìnný)

  // Nastavení popiskù sloupcù (hlavièky) pro StringGrid1
  StringGrid1.Cells[0, 0] := 'Èíslo bodu'; // Název sloupce 0
  StringGrid1.Cells[1, 0] := 'X';          // Název sloupce 1
  StringGrid1.Cells[2, 0] := 'Y';          // Název sloupce 2
  StringGrid1.Cells[3, 0] := 'Z';          // Název sloupce 3
  StringGrid1.Cells[4, 0] := 'Kvalita';    // Název sloupce 4
  StringGrid1.Cells[5, 0] := 'Popis';      // Název sloupce 4

  // Nastavení výchozích hodnot v prvním øádku pro zadávání bodù
  StringGrid1.Cells[0, 1] := '1'; // Èíslo bodu (výchozí hodnota = 1)
  StringGrid1.Cells[1, 1] := '';  // X souøadnice (prázdná)
  StringGrid1.Cells[2, 1] := '';  // Y souøadnice (prázdná)
  StringGrid1.Cells[3, 1] := '';  // Z souøadnice (prázdná)
  StringGrid1.Cells[4, 1] := '';  // Kvalita (prázdná)
  StringGrid1.Cells[5, 1] := '';  // Popis (prázdný)

  StringGrid1.Repaint;

  // Pøiøazení obslužných procedur pro události
  StringGrid1.OnKeyPress := StringGrid1KeyPress;
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
end;

procedure TForm2.StringGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  ValidatePointNumber(StringGrid1, Key);
  ValidateCoordinates(StringGrid1, Key);
  ValidateQualityCode(StringGrid1, Key);
end;

procedure TForm2.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0; // Zamezit dalšímu zpracování Enteru

    // Pøechod na další buòku
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
    begin
      StringGrid1.Col := StringGrid1.Col + 1;
    end
    else
    begin
      // Pokud jsme na posledním sloupci, pøejdeme na první sloupec dalšího øádku
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
      begin
        // Pokud jsme na posledním øádku, pøidáme nový øádek
        StringGrid1.RowCount := StringGrid1.RowCount + 1;
      end;
      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 0;
    end;
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Povolit mazání obsahu bunìk
  end;
end;

end.
