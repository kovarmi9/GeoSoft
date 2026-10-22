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
  GeoAlgorithmBase in '..\GeoAlgorithms\GeoAlgorithmBase.pas',
  GeoAlgorithmOrthogonal in '..\GeoAlgorithms\GeoAlgorithmOrthogonal.pas',
  GeoAlgorithmPolar in '..\GeoAlgorithms\GeoAlgorithmPolar.pas',
  GeoAlgorithmLHuilier in '..\GeoAlgorithms\GeoAlgorithmLHuilier.pas',
  GeoAlgorithmRectangularMeasurements in '..\GeoAlgorithms\GeoAlgorithmRectangularMeasurements.pas',
  GeoAlgorithmCheckMeasurements in '..\GeoAlgorithms\GeoAlgorithmCheckMeasurements.pas',
  GeoAlgorithmTransformBase in '..\GeoAlgorithms\GeoAlgorithmTransformBase.pas',
  GeoAlgorithmTransformCongruent in '..\GeoAlgorithms\GeoAlgorithmTransformCongruent.pas',
  GeoAlgorithmTransformSimilarity in '..\GeoAlgorithms\GeoAlgorithmTransformSimilarity.pas',
  GeoAlgorithmTransformAffine in '..\GeoAlgorithms\GeoAlgorithmTransformAffine.pas',
  GeoAlgorithmTransformation in '..\GeoAlgorithms\GeoAlgorithmTransformation.pas',
  SettingsDialog in 'SettingsDialog.pas' {SettingsForm},
  GeoDataFrame in '..\DataStructures\GeoDataFrame.pas',
  GeoRow in '..\DataStructures\GeoRow.pas',
  Point in '..\DataStructures\Point.pas',
  PointsUtilsSingleton in '..\DataStructures\PointsUtilsSingleton.pas',
  CoordOrderState in '..\Utils\CoordOrderState.pas',
  GeoGridBridge in '..\Utils\GeoGridBridge.pas',
  PointPrefixState in '..\Utils\PointPrefixState.pas',
  ProtocolArea in '..\Utils\ProtocolArea.pas',
  ProtocolPolar in '..\Utils\ProtocolPolar.pas',
  ProtocolTransformation in '..\Utils\ProtocolTransformation.pas',
  ProtocolTable in '..\Utils\ProtocolTable.pas',
  SettingsState in '..\Utils\SettingsState.pas',
  ValidationUtils in '..\Utils\ValidationUtils.pas',
  ExistingPoint in '..\Utils\ExistingPoint.pas',
  LineAdjustment in 'LineAdjustment.pas' {LineAdjustmentForm},
  LineIntersection in 'LineIntersection.pas' {LineIntersectionForm},
  DistanceIntersection in 'DistanceIntersection.pas' {DistanceIntersectionForm},
  ForwardIntersection in 'ForwardIntersection.pas' {ForwardIntersectionForm},
  RectangularAdjustment in 'RectangularAdjustment.pas' {RectangularAdjustmentForm},
  Resection in 'Resection.pas' {ResectionForm},
  Levelling in 'Levelling.pas' {LevellingForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TPointsManagementForm, PointsManagementForm);
  Application.CreateForm(TParcelAreaForm, ParcelAreaForm);
  Application.CreateForm(TOrthogonalMethodForm, OrthogonalMethodForm);
  Application.CreateForm(TTransformationForm, TransformationForm);
  Application.CreateForm(TRectangularMeasurementsForm, RectangularMeasurementsForm);
  Application.CreateForm(TCheckMeasurementsForm, CheckMeasurementsForm);
  Application.CreateForm(TPolarMethodForm, PolarMethodForm);
  Application.CreateForm(TLineAdjustmentForm, LineAdjustmentForm);
  Application.CreateForm(TLineIntersectionForm, LineIntersectionForm);
  Application.CreateForm(TDistanceIntersectionForm, DistanceIntersectionForm);
  Application.CreateForm(TForwardIntersectionForm, ForwardIntersectionForm);
  Application.CreateForm(TRectangularAdjustmentForm, RectangularAdjustmentForm);
  Application.CreateForm(TResectionForm, ResectionForm);
  Application.CreateForm(TLevellingForm, LevellingForm);
  Application.Run;
end.
