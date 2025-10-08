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
  GeoAlgorithmOrthogonal in '..\Utils\GeoAlgorithmOrthogonal.pas',
  GeoAlgorithmTransformBase in '..\GeoAlgorithms\GeoAlgorithmTransformBase.pas',
  GeoAlgorithmTransformCongruent in '..\GeoAlgorithms\GeoAlgorithmTransformCongruent.pas',
  GeoAlgorithmTransformSimilarity in '..\GeoAlgorithms\GeoAlgorithmTransformSimilarity.pas',
  GeoAlgorithmTransformAffine in '..\GeoAlgorithms\GeoAlgorithmTransformAffine.pas',
  AddPoint in 'AddPoint.pas' {Form6},
  Pokus in 'Pokus.pas' {Form7},
  CalcFormBase in 'CalcFormBase.pas' {Form8},
  PolarMethodNew in 'PolarMethodNew.pas' {Form9},
  PointsGrid in '..\Components\PointsGrid.pas' {Frame1: TFrame},
  BootcampPanel in 'BootcampPanel.pas',
  MyPointsStringGrid in 'MyPointsStringGrid.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TForm4, Form4);
  Application.CreateForm(TForm5, Form5);
  Application.CreateForm(TForm6, Form6);
  Application.CreateForm(TForm7, Form7);
  Application.CreateForm(TForm8, Form8);
  Application.CreateForm(TForm9, Form9);
  Application.Run;
end.
