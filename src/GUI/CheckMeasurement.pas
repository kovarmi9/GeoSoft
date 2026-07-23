unit CheckMeasurement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Point, GeoRow,
  GeoGrid, GeoFieldsGrid, GeoFieldsDef,
  CalcBase, Vcl.Menus, Vcl.ComCtrls, Vcl.ToolWin;

type
  TCheckMeasurementForm = class(TCalcBaseForm)
    GridMeasurement: TGeoFieldsGrid;
    procedure FormCreate(Sender: TObject);
  private
  public
  end;

var
  CheckMeasurementForm: TCheckMeasurementForm;

implementation

{$R *.dfm}

procedure TCheckMeasurementForm.FormCreate(Sender: TObject);
begin
  GridMeasurement.GeoFields := [CB, X, Y, Z, HZ, SS, Poznamka];
end;

end.
