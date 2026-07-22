unit CheckMeasurement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Point, AddPoint, GeoRow,
  GeoGrid, GeoFieldsGrid, GeoFieldsDef;

type
  TCheckMeasurementForm = class(TForm)
    GridMeasurement: TGeoFieldsGrid;
    Edit1: TEdit;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
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

procedure TCheckMeasurementForm.Button1Click(Sender: TObject);
var
  F: TAddPointForm;
  PointNumber: Integer;
  NewPoint: TPoint;
begin
  if not TryStrToInt(Edit1.Text, PointNumber) then
  begin
    ShowMessage('Zadejte platné číslo bodu.');
    Exit;
  end;
  F := TAddPointForm.Create(Self);
  try
    if F.Execute(PointNumber, NewPoint) then
      ShowMessage(Format('Bod %d úspěšně přidán.', [NewPoint.PointNumber]))
    else
      ShowMessage('Přidání bodu zrušeno.');
  finally
    F.Free;
  end;
end;

end.
