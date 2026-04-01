program TestFieldGrid;

uses
  Vcl.Forms,
  Test_FieldGrid in 'Test_FieldGrid.pas' {Form1},
  GeoFieldColumn in 'GeoFieldColumn.pas',
  GeoFieldsStringGrid in 'GeoFieldsStringGrid.pas',
  GeoRow in '..\Test_gdf\GeoRow.pas',
  GeoDataFrame in '..\Test_gdf\GeoDataFrame.pas',
  MyStringGrid in '..\src\Components\MyStringGrid.pas',
  ColumnValidation in '..\src\Components\ColumnValidation.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
