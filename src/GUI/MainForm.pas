unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.Grids, Vcl.Mask, Vcl.Menus, Vcl.ToolWin, Vcl.ComCtrls,
  GeoGrid, GeoPointsGrid, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    MenuFileNew: TMenuItem;
    Vypocty: TMenuItem;
    MenuFileOpen: TMenuItem;
    MenuView: TMenuItem;
    MenuShowList: TMenuItem;
    MenuSep1: TMenuItem;
    MenuSaveList: TMenuItem;
    MenuSaveListAs: TMenuItem;
    MenuNastaveni: TMenuItem;
    MenuLevelling: TMenuItem;
    MenuOrthogonalMethod: TMenuItem;
    MenuPolarMethod: TMenuItem;
    MenuLineAdjustment: TMenuItem;
    MenuLineIntersection: TMenuItem;
    MenuRectangularMeasurements: TMenuItem;
    MenuDistanceIntersection: TMenuItem;
    MenuForwardIntersection: TMenuItem;
    MenuRectangularAdjustment: TMenuItem;
    MenuResection: TMenuItem;
    MenuCheckMeasurements: TMenuItem;
    MenuTransformation: TMenuItem;
    MenuParcelArea: TMenuItem;
    MenuTechnicalLevelling: TMenuItem;
    procedure MenuFileOpenClick(Sender: TObject);
    procedure MenuFileNewClick(Sender: TObject);
    procedure MenuShowListClick(Sender: TObject);
    procedure MenuSaveListClick(Sender: TObject);
    procedure MenuSaveListAsClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure MenuNastaveniClick(Sender: TObject);
    procedure MenuOrthogonalMethodClick(Sender: TObject);
    procedure MenuPolarMethodClick(Sender: TObject);
    procedure MenuLineAdjustmentClick(Sender: TObject);
    procedure MenuLineIntersectionClick(Sender: TObject);
    procedure MenuRectangularMeasurementsClick(Sender: TObject);
    procedure MenuDistanceIntersectionClick(Sender: TObject);
    procedure MenuForwardIntersectionClick(Sender: TObject);
    procedure MenuRectangularAdjustmentClick(Sender: TObject);
    procedure MenuResectionClick(Sender: TObject);
    procedure MenuCheckMeasurementsClick(Sender: TObject);
    procedure MenuTransformationClick(Sender: TObject);
    procedure MenuParcelAreaClick(Sender: TObject);
    procedure MenuTechnicalLevellingClick(Sender: TObject);
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
  CheckMeasurements, PolarMethod, PointsManagement,
  SettingsDialog, LineAdjustment, LineIntersection, DistanceIntersection,
  ForwardIntersection, RectangularAdjustment, Resection, Levelling;

// File menu: picks a list file and shows it
procedure TForm1.MenuFileOpenClick(Sender: TObject);
begin
  if PointsManagementForm.OpenList then
    PointsManagementForm.Show;
end;

// The calculation forms and the list take the settings over when they are
// shown again
procedure TForm1.MenuNastaveniClick(Sender: TObject);
begin
  TSettingsForm.Execute;
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

procedure TForm1.MenuFileNewClick(Sender: TObject);
begin
  if PointsManagementForm.CreateNewList then
    PointsManagementForm.Show;
end;

// Calculations menu, in the order of the task codes
procedure TForm1.MenuOrthogonalMethodClick(Sender: TObject);
begin
  OrthogonalMethodForm.Show;
end;

procedure TForm1.MenuPolarMethodClick(Sender: TObject);
begin
  PolarMethodForm.Show;
end;

procedure TForm1.MenuLineAdjustmentClick(Sender: TObject);
begin
  LineAdjustmentForm.Show;
end;

procedure TForm1.MenuLineIntersectionClick(Sender: TObject);
begin
  LineIntersectionForm.Show;
end;

procedure TForm1.MenuRectangularMeasurementsClick(Sender: TObject);
begin
  RectangularMeasurementsForm.Show;
end;

procedure TForm1.MenuDistanceIntersectionClick(Sender: TObject);
begin
  DistanceIntersectionForm.Show;
end;

procedure TForm1.MenuForwardIntersectionClick(Sender: TObject);
begin
  ForwardIntersectionForm.Show;
end;

procedure TForm1.MenuRectangularAdjustmentClick(Sender: TObject);
begin
  RectangularAdjustmentForm.Show;
end;

procedure TForm1.MenuResectionClick(Sender: TObject);
begin
  ResectionForm.Show;
end;

procedure TForm1.MenuCheckMeasurementsClick(Sender: TObject);
begin
  CheckMeasurementsForm.Show;
end;

procedure TForm1.MenuTransformationClick(Sender: TObject);
begin
  TransformationForm.Show;
end;

procedure TForm1.MenuTechnicalLevellingClick(Sender: TObject);
begin
  LevellingForm.Show;
end;

procedure TForm1.MenuParcelAreaClick(Sender: TObject);
begin
  ParcelAreaForm.Show;
end;

end.
