unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.Grids, Vcl.Mask, Vcl.Menus, Vcl.ToolWin, Vcl.ComCtrls, Vcl.WinXCtrls,
  GeoGrid, GeoPointsGrid;

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
    MenuView: TMenuItem;
    MenuShowList: TMenuItem;
    MenuSep1: TMenuItem;
    MenuSaveList: TMenuItem;
    MenuSaveListAs: TMenuItem;
    YX2XY: TToggleSwitch;
    procedure Open2Click(Sender: TObject);
    procedure Vytvoitseznam1Click(Sender: TObject);
    procedure Polrnmetoda1Click(Sender: TObject);
    procedure Ortogonlnmetoda1Click(Sender: TObject);
    procedure TransformationClick(Sender: TObject);
    procedure RectangularMeasurementsClick(Sender: TObject);
    procedure CheckMeasurementsClick(Sender: TObject);
    procedure Polrnmetodanov1Click(Sender: TObject);
    procedure YX2XYClick(Sender: TObject);
    procedure MenuShowListClick(Sender: TObject);
    procedure MenuSaveListClick(Sender: TObject);
    procedure MenuSaveListAsClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
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
  CheckMeasurements, PolarMethod, PointsManagement, CoordOrderState;

// File menu: picks a list file and shows it
procedure TForm1.Open2Click(Sender: TObject);
begin
  if PointsManagementForm.OpenList then
    PointsManagementForm.Show;
end;

// View menu: brings the list window up with whatever is loaded
procedure TForm1.MenuShowListClick(Sender: TObject);
begin
  PointsManagementForm.Show;
end;

// The list is the document, so it is saved from the main menu too
procedure TForm1.MenuSaveListClick(Sender: TObject);
begin
  PointsManagementForm.DoSave;
end;

procedure TForm1.MenuSaveListAsClick(Sender: TObject);
begin
  PointsManagementForm.SaveListAs;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := PointsManagementForm.AskSaveChanges;
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

// Switch off = Y, X (cadastre order, the default). Switch on = X, Y.
// Grids pick the new order up in their FormActivate.
procedure TForm1.YX2XYClick(Sender: TObject);
begin
  if YX2XY.State = tssOn then
    GCoordOrder := coXY
  else
    GCoordOrder := coYX;
end;

end.
