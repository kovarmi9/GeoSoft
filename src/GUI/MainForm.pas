unit MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Menus, Vcl.ToolWin,
  Vcl.ComCtrls, Vcl.StdCtrls;

type
  TGeoSoftForm = class(TForm)
    ToolBar: TToolBar;
    MainMenu: TMainMenu;
    MenuFile: TMenuItem;
    MenuFileNew: TMenuItem;
    MenuCalculations: TMenuItem;
    MenuFileOpen: TMenuItem;
    MenuView: TMenuItem;
    MenuShowList: TMenuItem;
    MenuSep1: TMenuItem;
    MenuSaveList: TMenuItem;
    MenuSaveListAs: TMenuItem;
    MenuSettings: TMenuItem;
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
    MenuProtocol: TMenuItem;
    Button1: TButton;
    procedure MenuFileOpenClick(Sender: TObject);
    procedure MenuFileNewClick(Sender: TObject);
    procedure MenuShowListClick(Sender: TObject);
    procedure MenuSaveListClick(Sender: TObject);
    procedure MenuSaveListAsClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure MenuSettingsClick(Sender: TObject);
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
    procedure MenuProtocolClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GeoSoftForm: TGeoSoftForm;

implementation

{$R *.dfm}

uses ParcelArea, OrthogonalMethod, Transformation, RectangularMeasurements,
  CheckMeasurements, PolarMethod, PointsManagement,
  SettingsDialog, LineAdjustment, LineIntersection, DistanceIntersection,
  ForwardIntersection, RectangularAdjustment, Resection, Levelling, dbtest;

// File menu: picks a list file and shows it
procedure TGeoSoftForm.MenuFileOpenClick(Sender: TObject);
begin
  if PointsManagementForm.OpenList then
    PointsManagementForm.Show;
end;

// The calculation forms and the list take the settings over when they are
// shown again
procedure TGeoSoftForm.MenuSettingsClick(Sender: TObject);
begin
  TSettingsForm.Execute;
end;

// The job protocol (.ptk) in Notepad
procedure TGeoSoftForm.MenuProtocolClick(Sender: TObject);
begin
  PointsManagementForm.ShowJobProtocol;
end;

// View menu: brings the list window up with whatever is loaded
procedure TGeoSoftForm.MenuShowListClick(Sender: TObject);
begin
  PointsManagementForm.Show;
end;

// The list is the document, so it is saved from the main menu too
procedure TGeoSoftForm.MenuSaveListClick(Sender: TObject);
begin
  PointsManagementForm.DoSave;
end;

procedure TGeoSoftForm.MenuSaveListAsClick(Sender: TObject);
begin
  PointsManagementForm.SaveListAs;
end;

procedure TGeoSoftForm.Button1Click(Sender: TObject);
begin
  dbtestForm.Show;
end;

procedure TGeoSoftForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := PointsManagementForm.AskSaveChanges;
end;

procedure TGeoSoftForm.MenuFileNewClick(Sender: TObject);
begin
  if PointsManagementForm.CreateNewList then
    PointsManagementForm.Show;
end;

// Calculations menu, in the order of the task codes
procedure TGeoSoftForm.MenuOrthogonalMethodClick(Sender: TObject);
begin
  OrthogonalMethodForm.Show;
end;

procedure TGeoSoftForm.MenuPolarMethodClick(Sender: TObject);
begin
  PolarMethodForm.Show;
end;

procedure TGeoSoftForm.MenuLineAdjustmentClick(Sender: TObject);
begin
  LineAdjustmentForm.Show;
end;

procedure TGeoSoftForm.MenuLineIntersectionClick(Sender: TObject);
begin
  LineIntersectionForm.Show;
end;

procedure TGeoSoftForm.MenuRectangularMeasurementsClick(Sender: TObject);
begin
  RectangularMeasurementsForm.Show;
end;

procedure TGeoSoftForm.MenuDistanceIntersectionClick(Sender: TObject);
begin
  DistanceIntersectionForm.Show;
end;

procedure TGeoSoftForm.MenuForwardIntersectionClick(Sender: TObject);
begin
  ForwardIntersectionForm.Show;
end;

procedure TGeoSoftForm.MenuRectangularAdjustmentClick(Sender: TObject);
begin
  RectangularAdjustmentForm.Show;
end;

procedure TGeoSoftForm.MenuResectionClick(Sender: TObject);
begin
  ResectionForm.Show;
end;

procedure TGeoSoftForm.MenuCheckMeasurementsClick(Sender: TObject);
begin
  CheckMeasurementsForm.Show;
end;

procedure TGeoSoftForm.MenuTransformationClick(Sender: TObject);
begin
  TransformationForm.Show;
end;

procedure TGeoSoftForm.MenuTechnicalLevellingClick(Sender: TObject);
begin
  LevellingForm.Show;
end;

procedure TGeoSoftForm.MenuParcelAreaClick(Sender: TObject);
begin
  ParcelAreaForm.Show;
end;

end.
