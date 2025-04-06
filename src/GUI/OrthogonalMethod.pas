unit OrthogonalMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids;

type
  TForm4 = class(TForm)
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject); // Procedura volan� p�i inicializaci formul��e
    procedure StringGrid1Click(Sender: TObject);
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
  StringGrid1.FixedRows := 1; // Prvn� ��dek jako hlavi�ka
  StringGrid1.FixedCols := 1; // Prvn� sloupec jako ��slov�n�
  StringGrid1.Cells[1, 0] := '��slo bodu';       // N�zev sloupce 1
  StringGrid1.Cells[2, 0] := 'stani�en�';        // N�zev sloupce 2
  StringGrid1.Cells[3, 0] := 'kolmice';          // N�zev sloupce 3
  StringGrid1.Cells[4, 0] := 'X';                // N�zev sloupce 4
  StringGrid1.Cells[5, 0] := 'Y';                // N�zev sloupce 4
  StringGrid1.Cells[0, 1] := 'P';                // N�zev ��dku 1
  StringGrid1.Cells[0, 2] := 'K';                // N�zev ��dku 2

  StringGrid1.Repaint;
end;


procedure TForm4.StringGrid1Click(Sender: TObject);
begin
//
end;

end.
