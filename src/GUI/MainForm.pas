unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Point, Vcl.StdCtrls,
  AddPoint,
  Vcl.Grids, Vcl.Mask, Vcl.Menus, Vcl.ToolWin, Vcl.ComCtrls,
  PointsManagement,   GeoAlgorithmBase,
  GeoAlgorithmTransformBase,
  GeoAlgorithmTransformSimilarity,
  System.Generics.Collections,
  GeoAlgorithmTransformCongruent,
  GeoAlgorithmTransformAffine, MyStringGrid, MyPointsStringGrid;

type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    Vytvoitseznam1: TMenuItem;
    Vypocty: TMenuItem;
    Open2: TMenuItem;
    Polrnmetoda1: TMenuItem;
    Ortogonlnmetoda1: TMenuItem;
    ransformace1: TMenuItem;
    Pokus1: TMenuItem;
    Polrnmetodanov1: TMenuItem;
    procedure Open2Click(Sender: TObject);
    procedure Polrnmetoda1Click(Sender: TObject);
    procedure Ortogonlnmetoda1Click(Sender: TObject);
    procedure TransformationClick(Sender: TObject);
    procedure PokusClick(Sender: TObject);
    procedure Polrnmetodanov1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses polarMethod, OrthogonalMethod, Transformation, Pokus, PolarMethodNew;

procedure TForm1.Open2Click(Sender: TObject);
begin
Form2.Show;
end;

procedure TForm1.Polrnmetoda1Click(Sender: TObject);
begin
Form3.Show;
end;

procedure TForm1.Polrnmetodanov1Click(Sender: TObject);
begin
Form9.Show;
end;

procedure TForm1.Ortogonlnmetoda1Click(Sender: TObject);
begin
Form4.Show;
end;

procedure TForm1.TransformationClick(Sender: TObject);
begin
Form5.Show;
end;

procedure TForm1.PokusClick(Sender: TObject);
begin
Form7.Show;
end;

end.
