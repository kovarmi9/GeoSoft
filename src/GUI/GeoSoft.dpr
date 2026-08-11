program GeoSoft;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Form1},
  PointsManagement in 'PointsManagement.pas' {PointsManagementForm},
  AddPoint in 'AddPoint.pas' {AddPointForm},
  CalcBase in 'CalcBase.pas' {CalcBaseForm},
  ParcelArea in 'ParcelArea.pas' {ParcelAreaForm},
  OrthogonalMethod in 'OrthogonalMethod.pas' {OrthogonalMethodForm},
  Transformation in 'Transformation.pas' {TransformationForm},
  RectangularMeasurements in 'RectangularMeasurements.pas' {RectangularMeasurementsForm},
  CheckMeasurements in 'CheckMeasurements.pas' {CheckMeasurementsForm},
  PolarMethod in 'PolarMethod.pas' {PolarMethodForm},
  GeoAlgorithmBase in '..\Utils\GeoAlgorithmBase.pas',
  GeoAlgorithmOrthogonal in '..\Utils\GeoAlgorithmOrthogonal.pas',
  GeoAlgorithmLHuilier in '..\Utils\GeoAlgorithmLHuilier.pas',
  GeoAlgorithmRectangularMeasurements in '..\Utils\GeoAlgorithmRectangularMeasurements.pas',
  GeoAlgorithmTransformBase in '..\GeoAlgorithms\GeoAlgorithmTransformBase.pas',
  GeoAlgorithmTransformCongruent in '..\GeoAlgorithms\GeoAlgorithmTransformCongruent.pas',
  GeoAlgorithmTransformSimilarity in '..\GeoAlgorithms\GeoAlgorithmTransformSimilarity.pas',
  GeoAlgorithmTransformAffine in '..\GeoAlgorithms\GeoAlgorithmTransformAffine.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TPointsManagementForm, PointsManagementForm);
  Application.CreateForm(TAddPointForm, AddPointForm);
  Application.CreateForm(TParcelAreaForm, ParcelAreaForm);
  Application.CreateForm(TOrthogonalMethodForm, OrthogonalMethodForm);
  Application.CreateForm(TTransformationForm, TransformationForm);
  Application.CreateForm(TRectangularMeasurementsForm, RectangularMeasurementsForm);
  Application.CreateForm(TCheckMeasurementsForm, CheckMeasurementsForm);
  Application.CreateForm(TPolarMethodForm, PolarMethodForm);
  Application.Run;
end.
