unit PolarMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, PointsUtilsSingleton, Point;

type
  TForm3 = class(TForm)
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.FormCreate(Sender: TObject);
begin
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
end;

procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  Point: TPoint;
begin
  if Key = VK_RETURN then
  begin
    Key := 0; // Zamezí dalšímu zpracování Enteru

    // Naètení èísla bodu z nultého sloupce
    PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row], -1);
    ShowMessage(Format('Zadané èíslo bodu: %d', [PointNumber]));

    // Kontrola, zda bod existuje v seznamu
    if PointNumber <> -1 then
    begin
      if TPointDictionary.GetInstance.PointExists(PointNumber) then
      begin
        Point := TPointDictionary.GetInstance.GetPoint(PointNumber);
        ShowMessage(Format('Bod %d nalezen: X=%.2f, Y=%.2f, Z=%.2f, Kvalita=%d, Popis=%s',
          [Point.PointNumber, Point.X, Point.Y, Point.Z, Point.Quality, Point.Description]));

        // Doplnìní údajù do dalších sloupcù
        StringGrid1.Cells[1, StringGrid1.Row] := FloatToStr(Point.X);
        StringGrid1.Cells[2, StringGrid1.Row] := FloatToStr(Point.Y);
        StringGrid1.Cells[3, StringGrid1.Row] := FloatToStr(Point.Z);
        StringGrid1.Cells[4, StringGrid1.Row] := IntToStr(Point.Quality);
        StringGrid1.Cells[5, StringGrid1.Row] := Point.Description;
      end
      else
      begin
        ShowMessage(Format('Bod %d nebyl nalezen.', [PointNumber]));
      end;
    end
    else
    begin
      ShowMessage('Neplatné èíslo bodu.');
    end;
  end;
end;

end.
