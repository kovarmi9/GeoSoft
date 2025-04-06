unit OrthogonalMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids;

type
  TForm4 = class(TForm)
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject); // Procedura volaná pøi inicializaci formuláøe
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
  StringGrid1.FixedRows := 1; // První øádek jako hlavièka
  StringGrid1.FixedCols := 1; // První sloupec jako èíslování
  StringGrid1.Cells[1, 0] := 'èíslo bodu';       // Název sloupce 1
  StringGrid1.Cells[2, 0] := 'stanièení';        // Název sloupce 2
  StringGrid1.Cells[3, 0] := 'kolmice';          // Název sloupce 3
  StringGrid1.Cells[4, 0] := 'X';                // Název sloupce 4
  StringGrid1.Cells[5, 0] := 'Y';                // Název sloupce 4
  StringGrid1.Cells[0, 1] := 'P';                // Název øádku 1
  StringGrid1.Cells[0, 2] := 'K';                // Název øádku 2

  StringGrid1.Repaint;
end;


procedure TForm4.StringGrid1Click(Sender: TObject);
begin
//
end;

end.
