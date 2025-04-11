unit OrthogonalMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  PointsUtilsSingleton, Point, GeoAlgorithmBase;

type
  TForm4 = class(TForm)
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject); // Inicializace formul��e a nastaven� gridu
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
  // Nastaven� z�kladn�ch vlastnost� StringGridu
  StringGrid1.FixedRows := 1;  // Prvn� ��dek je vyhrazen pro hlavi�ku
  StringGrid1.FixedCols := 1;  // Prvn� sloupec bude slou�it k ��slov�n� ��dk�

  // Nastaven� n�zv� sloupc� (hlavi�ka)
  StringGrid1.Cells[1, 0] := '��slo bodu';  // Sloupec 1 � ��slo bodu
  StringGrid1.Cells[2, 0] := 'stani�en�';    // Sloupec 2 � lze pou��t pro dal�� �daje
  StringGrid1.Cells[3, 0] := 'kolmice';      // Sloupec 3 � rovn� dle po�adavku
  StringGrid1.Cells[4, 0] := 'X';            // Sloupec 4 � sou�adnice X
  StringGrid1.Cells[5, 0] := 'Y';            // Sloupec 5 � sou�adnice Y

  // P��klad pojmenov�n� ��dk� (dle vlastn�ho zad�n� � nap�. po��te�n� a koncov� bod)
  StringGrid1.Cells[0, 1] := 'P';  // ��dek 1
  StringGrid1.Cells[0, 2] := 'K';  // ��dek 2

  // Nastaven� po��te�n�ho datov�ho ��dku � nap�. prvn� ��dek dat (mimo hlavi�ku a fixovan� ��dky)
  StringGrid1.Cells[0, 3] := '1';

  // Vykreslen� zm�n
  StringGrid1.Repaint;

  // P�i�azen� ud�losti pro stisk kl�vesy (Enter, Delete apod.)
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
end;

procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  Pt: TPoint;
begin
  if Key = VK_RETURN then
  begin
    Key := 0; // Zamezen� v�choz�ho chov�n� Enteru

    // Na�ten� ��sla bodu ze sloupce 1 aktu�ln�ho ��dku
    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
    if PointNumber = -1 then
    begin
      ShowMessage('Neplatn� ��slo bodu.');
      Exit;
    end;

    // Automatick� vypln�n� sou�adnic, pokud bod existuje ve slovn�ku
    if TPointDictionary.GetInstance.PointExists(PointNumber) then
    begin
      Pt := TPointDictionary.GetInstance.GetPoint(PointNumber);
      StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(Pt.X);
      StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(Pt.Y);
    end
    else if (StringGrid1.Row = 1) or (StringGrid1.Row = 2) then
      ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]));

    // Logika navigov�n�
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
    begin
      // Pokud nen� aktu�ln� bu�ka posledn� v ��dku, posun na dal�� sloupec
      StringGrid1.Col := StringGrid1.Col + 1;
    end
    else
    begin
      // Pokud posledn� sloupec, p�id� se nov� ��dek, pokud je aktu�ln� ��dek posledn�
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
        StringGrid1.RowCount := StringGrid1.RowCount + 1; // p�id�n� nov�ho ��dku

      // P�esuneme se na n�sleduj�c� ��dek a prvn� sloupec
      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 1;

      // Automatick� ��slov�n� nult�ho sloupce
      if StringGrid1.Row > 2 then
        StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
    end;
  end
  else if Key = VK_DELETE then
  begin
    // P�i stisku Delete vyma�eme obsah aktu�ln� bu�ky
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
  end;
end;

end.

