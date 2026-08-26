unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.Grids, Vcl.Mask, Vcl.Menus, Vcl.ToolWin, Vcl.ComCtrls;

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
    Konstruknomrn1: TMenuItem;
    procedure Open2Click(Sender: TObject);
    procedure Vytvoitseznam1Click(Sender: TObject);
    procedure Polrnmetoda1Click(Sender: TObject);
    procedure Ortogonlnmetoda1Click(Sender: TObject);
    procedure TransformationClick(Sender: TObject);
    procedure RectangularMeasurementsClick(Sender: TObject);
    procedure CheckMeasurementsClick(Sender: TObject);
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

uses ParcelArea, OrthogonalMethod, Transformation, RectangularMeasurements,
  CheckMeasurements, PolarMethod, PointsManagement;

procedure TForm1.Open2Click(Sender: TObject);
begin
  if not PointsManagementForm.HasActiveList then
  begin
    if Application.MessageBox(
      'Seznam souřadnic neexistuje. Chcete vytvořit nový?',
      'GeoSoft',
      MB_YESNO or MB_ICONQUESTION) <> IDYES then
      Exit;
    if not PointsManagementForm.CreateNewList then
      Exit;
  end;
  PointsManagementForm.Show;
end;

procedure TForm1.Vytvoitseznam1Click(Sender: TObject);
begin
  if PointsManagementForm.CreateNewList then
    PointsManagementForm.Show;
end;

procedure TForm1.Polrnmetoda1Click(Sender: TObject);
begin
ParcelAreaForm.Show;
end;

procedure TForm1.Polrnmetodanov1Click(Sender: TObject);
begin
PolarMethodForm.Show;
end;

procedure TForm1.Ortogonlnmetoda1Click(Sender: TObject);
begin
OrthogonalMethodForm.Show;
end;

procedure TForm1.TransformationClick(Sender: TObject);
begin
TransformationForm.Show;
end;

procedure TForm1.RectangularMeasurementsClick(Sender: TObject);
begin
  RectangularMeasurementsForm.Show;
end;

procedure TForm1.CheckMeasurementsClick(Sender: TObject);
begin
  CheckMeasurementsForm.Show;
end;

end.
