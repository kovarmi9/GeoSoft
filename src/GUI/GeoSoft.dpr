program GeoSoft;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Form1},
  PointsManagement in 'PointsManagement.pas' {Form2},
  PolarMethod in 'PolarMethod.pas' {Form3},
  OrthogonalMethod in 'OrthogonalMethod.pas' {Form4},
  Transformation in 'Transformation.pas' {Form5},
  StringGridValidationUtils in 'StringGridValidationUtils.pas' {$R *.res},
  GeoAlgorithmBase in '..\Utils\GeoAlgorithmBase.pas',
  GeoAlgorithmOrthogonal in '..\Utils\GeoAlgorithmOrthogonal.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TForm4, Form4);
  Application.CreateForm(TForm5, Form5);
  Application.Run;
end.
