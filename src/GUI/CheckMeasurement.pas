unit CheckMeasurement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Point, AddPoint, Vcl.Grids, MyStringGrid, GeoRow,
  TestFieldGrid, MyFieldsStringGrid;

type
  TCheckMeasurementForm = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Button2: TButton;
    MyFieldsStringGrid1: TMyFieldsStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CheckMeasurementForm: TCheckMeasurementForm;
  NewPoint: Point.TPoint;

implementation

{$R *.dfm}

procedure TCheckMeasurementForm.FormCreate(Sender: TObject);
begin
  // Vyber sloupce které chceš zobrazit:
  MyFieldsStringGrid1.GeoFields := [CB, X, Y, Z, HZ, SS, Poznamka];
end;

procedure TCheckMeasurementForm.Button1Click(Sender: TObject);
var
  F: TAddPointForm;
  PointNumber: Integer;
  NewPoint: TPoint;
begin
  if not TryStrToInt(Edit1.Text, PointNumber) then
  begin
    ShowMessage('Enter a valid point number!');
    Exit;
  end;
  F := TAddPointForm.Create(Self);
  try
    if F.Execute(PointNumber, NewPoint) then
    begin
      ShowMessage(Format('Point %d added successfully!', [NewPoint.PointNumber]));
      // You can use NewPoint here or pass it elsewhere.
    end
    else
    begin
      ShowMessage('Point entry cancelled.');
    end;
  finally
    F.Free;
  end;
end;

procedure TCheckMeasurementForm.Button2Click(Sender: TObject);
begin
  Form2.Show;
end;

end.
