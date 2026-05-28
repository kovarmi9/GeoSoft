unit test_project;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  GeoGrid;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    FGrid: TGeoGrid;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  FGrid := TGeoGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.SetBounds(10, 10, 600, 300);
  FGrid.ColCount := 4;
  FGrid.RowCount := 6;
  FGrid.ColumnHeaders.Add('»Ìslo bodu');
  FGrid.ColumnHeaders.Add('X');
  FGrid.ColumnHeaders.Add('Y');
  FGrid.ColumnHeaders.Add('Z');
end;

end.
