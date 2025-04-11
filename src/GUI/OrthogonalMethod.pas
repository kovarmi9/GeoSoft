unit OrthogonalMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  PointsUtilsSingleton, Point, GeoAlgorithmBase;

type
  TForm4 = class(TForm)
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject); // Inicializace formuláøe a nastavení gridu
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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
  StringGrid1.FixedRows := 1;  // První øádek je vyhrazen pro hlavièku
  StringGrid1.FixedCols := 1;  // První sloupec bude sloužit k èíslování øádkù

  // Nastavení názvù sloupcù (hlavièka)
  StringGrid1.Cells[1, 0] := 'èíslo bodu';  // Sloupec 1 – èíslo bodu
  StringGrid1.Cells[2, 0] := 'stanièení';    // Sloupec 2 – lze použít pro další údaje
  StringGrid1.Cells[3, 0] := 'kolmice';      // Sloupec 3 – rovnìž dle požadavku
  StringGrid1.Cells[4, 0] := 'X';            // Sloupec 4 – souøadnice X
  StringGrid1.Cells[5, 0] := 'Y';            // Sloupec 5 – souøadnice Y

  // Pøíklad pojmenování øádkù (dle vlastního zadání – napø. poèáteèní a koncový bod)
  StringGrid1.Cells[0, 1] := 'P';  // Øádek 1
  StringGrid1.Cells[0, 2] := 'K';  // Øádek 2

  // Nastavení poèáteèního datového øádku – napø. první øádek dat (mimo hlavièku a fixované øádky)
  StringGrid1.Cells[0, 3] := '1';

  // Vykreslení zmìn
  StringGrid1.Repaint;

  // Pøiøazení události pro stisk klávesy (Enter, Delete apod.)
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
end;

procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  Pt: TPoint;
begin
  if Key = VK_RETURN then
  begin
    Key := 0; // Zamezení výchozího chování Enteru

    // Naètení èísla bodu ze sloupce 1 aktuálního øádku
    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
    if PointNumber = -1 then
    begin
      ShowMessage('Neplatné èíslo bodu.');
      Exit;
    end;

    // Automatické vyplnìní souøadnic, pokud bod existuje ve slovníku
    if TPointDictionary.GetInstance.PointExists(PointNumber) then
    begin
      Pt := TPointDictionary.GetInstance.GetPoint(PointNumber);
      StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(Pt.X);
      StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(Pt.Y);
    end
    else if (StringGrid1.Row = 1) or (StringGrid1.Row = 2) then
      ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]));

    // Logika navigování
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
    begin
      // Pokud není aktuální buòka poslední v øádku, posun na další sloupec
      StringGrid1.Col := StringGrid1.Col + 1;
    end
    else
    begin
      // Pokud poslední sloupec, pøidá se nový øádek, pokud je aktuální øádek poslední
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
        StringGrid1.RowCount := StringGrid1.RowCount + 1; // pøidání nového øádku

      // Pøesuneme se na následující øádek a první sloupec
      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 1;

      // Automatické èíslování nultého sloupce
      if StringGrid1.Row > 2 then
        StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
    end;
  end
  else if Key = VK_DELETE then
  begin
    // Pøi stisku Delete vymažeme obsah aktuální buòky
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
  end;
end;

end.

