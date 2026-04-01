program GeoSoft;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Form1},
  PointsManagement in 'PointsManagement.pas' {PointsManagementForm},
  ParcelArea in 'ParcelArea.pas' {Form3},
  OrthogonalMethod in 'OrthogonalMethod.pas' {Form4},
  Transformation in 'Transformation.pas' {TransformationForm},
  AddPoint in 'AddPoint.pas' {AddPointForm},
  CheckMeasurement in 'CheckMeasurement.pas' {CheckMeasurementForm},
  PolarMethod in 'PolarMethod.pas' {PolarMethodForm},
  StringGridValidationUtils in 'StringGridValidationUtils.pas',
  GeoAlgorithmBase in '..\Utils\GeoAlgorithmBase.pas',
  GeoAlgorithmOrthogonal in '..\Utils\GeoAlgorithmOrthogonal.pas',
  GeoAlgorithmTransformBase in '..\GeoAlgorithms\GeoAlgorithmTransformBase.pas',
  GeoAlgorithmTransformCongruent in '..\GeoAlgorithms\GeoAlgorithmTransformCongruent.pas',
  GeoAlgorithmTransformSimilarity in '..\GeoAlgorithms\GeoAlgorithmTransformSimilarity.pas',
  GeoAlgorithmTransformAffine in '..\GeoAlgorithms\GeoAlgorithmTransformAffine.pas',
  MyStringGrid in '..\Components\MyStringGrid.pas',
  MyPointsStringGrid in '..\Components\MyPointsStringGrid.pas' {/,},
  InputFilterUtils in '..\Utils\InputFilterUtils.pas',
  TestFieldGrid in 'TestFieldGrid.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TPointsManagementForm, PointsManagementForm);
  Application.CreateForm(TParcelAreaForm, ParcelAreaForm);
  Application.CreateForm(TOrthogonalMethodForm, OrthogonalMethodForm);
  Application.CreateForm(TTransformationForm, TransformationForm);
  Application.CreateForm(TAddPointForm, AddPointForm);
  Application.CreateForm(TCheckMeasurementForm, CheckMeasurementForm);
  Application.CreateForm(TPolarMethodForm, PolarMethodForm);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
