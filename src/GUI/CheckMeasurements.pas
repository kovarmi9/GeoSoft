unit CheckMeasurements;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Menus,
  CalcBase, Vcl.Dialogs, Vcl.Grids, GeoGrid, GeoFieldsGrid;

type
  TCheckMeasurementsForm = class(TCalcBaseForm)
    Memo1: TMemo;
    GridOrientation: TGeoFieldsGrid;
    Calculate: TButton;
  private
  public
  end;

var
  CheckMeasurementsForm: TCheckMeasurementsForm;

implementation

{$R *.dfm}

end.
