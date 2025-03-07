unit PointsManagement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  StringGridValidationUtils;

type
  TForm2 = class(TForm)
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject); // Procedura volan� p�i inicializaci formul��e
    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracov�n� stisknut� kl�vesy
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); // Procedura pro zpracov�n� stisknut� kl�vesy
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
  // Nastaven� sloupc� a ��dk� pro StringGrid1 (tabulka pro zad�v�n� sou�adnic)
  StringGrid1.ColCount := 6; // Po�et sloupc�: ��slo bodu, X, Y, Z, Popis
  StringGrid1.RowCount := 2; // Minim�ln� 2 ��dky (hlavi�ka + 1 pr�zdn� ��dek pro vstup)
  StringGrid1.FixedRows := 1; // Prvn� ��dek bude pevn� (nem�nn�)

  // Nastaven� popisk� sloupc� (hlavi�ky) pro StringGrid1
  StringGrid1.Cells[0, 0] := '��slo bodu'; // N�zev sloupce 0
  StringGrid1.Cells[1, 0] := 'X';          // N�zev sloupce 1
  StringGrid1.Cells[2, 0] := 'Y';          // N�zev sloupce 2
  StringGrid1.Cells[3, 0] := 'Z';          // N�zev sloupce 3
  StringGrid1.Cells[4, 0] := 'Kvalita';    // N�zev sloupce 4
  StringGrid1.Cells[5, 0] := 'Popis';      // N�zev sloupce 4

  // Nastaven� v�choz�ch hodnot v prvn�m ��dku pro zad�v�n� bod�
  StringGrid1.Cells[0, 1] := '1'; // ��slo bodu (v�choz� hodnota = 1)
  StringGrid1.Cells[1, 1] := '';  // X sou�adnice (pr�zdn�)
  StringGrid1.Cells[2, 1] := '';  // Y sou�adnice (pr�zdn�)
  StringGrid1.Cells[3, 1] := '';  // Z sou�adnice (pr�zdn�)
  StringGrid1.Cells[4, 1] := '';  // Kvalita (pr�zdn�)
  StringGrid1.Cells[5, 1] := '';  // Popis (pr�zdn�)

  StringGrid1.Repaint;

  // P�i�azen� obslu�n�ch procedur pro ud�losti
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
    Key := 0; // Zamezit dal��mu zpracov�n� Enteru

    // P�echod na dal�� bu�ku
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
    begin
      StringGrid1.Col := StringGrid1.Col + 1;
    end
    else
    begin
      // Pokud jsme na posledn�m sloupci, p�ejdeme na prvn� sloupec dal��ho ��dku
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
      begin
        // Pokud jsme na posledn�m ��dku, p�id�me nov� ��dek
        StringGrid1.RowCount := StringGrid1.RowCount + 1;
      end;
      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 0;
    end;
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Povolit maz�n� obsahu bun�k
  end;
end;

end.
