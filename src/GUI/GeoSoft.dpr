program GeoSoft;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {GeoSoftForm},
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
  GeoAlgorithmScale in '..\GeoAlgorithms\GeoAlgorithmScale.pas',
  GeoAlgorithmLineAdjustment in '..\GeoAlgorithms\GeoAlgorithmLineAdjustment.pas',
  GeoAlgorithmLevelling in '..\GeoAlgorithms\GeoAlgorithmLevelling.pas',
  GeoAlgorithmLineIntersection in '..\GeoAlgorithms\GeoAlgorithmLineIntersection.pas',
  GeoAlgorithmDistanceIntersection in '..\GeoAlgorithms\GeoAlgorithmDistanceIntersection.pas',
  GeoAlgorithmForwardIntersection in '..\GeoAlgorithms\GeoAlgorithmForwardIntersection.pas',
  GeoAlgorithmResection in '..\GeoAlgorithms\GeoAlgorithmResection.pas',
  GeoAlgorithmRectangularAdjustment in '..\GeoAlgorithms\GeoAlgorithmRectangularAdjustment.pas',
  SettingsDialog in 'SettingsDialog.pas' {SettingsForm},
  GeoDataFrame in '..\DataStructures\GeoDataFrame.pas',
  GeoRow in '..\DataStructures\GeoRow.pas',
  Point in '..\DataStructures\Point.pas',
  PointDictionary in '..\DataStructures\PointDictionary.pas',
  PointDatabase in '..\DataStructures\PointDatabase.pas',
  CoordOrderState in '..\Utils\CoordOrderState.pas',
  GeoGridBridge in '..\Utils\GeoGridBridge.pas',
  PointPrefixState in '..\Utils\PointPrefixState.pas',
  ProtocolTable in '..\Utils\ProtocolTable.pas',
  SettingsState in '..\Utils\SettingsState.pas',
  Validation in '..\DataStructures\Validation.pas',
  PointNumber in '..\DataStructures\PointNumber.pas',
  Accuracy in '..\GeoAlgorithms\Accuracy.pas',
  ExistingPoint in '..\Utils\ExistingPoint.pas',
  LineAdjustment in 'LineAdjustment.pas' {LineAdjustmentForm},
  LineIntersection in 'LineIntersection.pas' {LineIntersectionForm},
  DistanceIntersection in 'DistanceIntersection.pas' {DistanceIntersectionForm},
  ForwardIntersection in 'ForwardIntersection.pas' {ForwardIntersectionForm},
  RectangularAdjustment in 'RectangularAdjustment.pas' {RectangularAdjustmentForm},
  Resection in 'Resection.pas' {ResectionForm},
  Levelling in 'Levelling.pas' {LevellingForm},
  ProtocolOrthogonal in '..\Protocols\ProtocolOrthogonal.pas',
  ProtocolPolar in '..\Protocols\ProtocolPolar.pas',
  ProtocolLineAdjustment in '..\Protocols\ProtocolLineAdjustment.pas',
  ProtocolLineIntersection in '..\Protocols\ProtocolLineIntersection.pas',
  ProtocolRectangularMeasurements in '..\Protocols\ProtocolRectangularMeasurements.pas',
  ProtocolDistanceIntersection in '..\Protocols\ProtocolDistanceIntersection.pas',
  ProtocolForwardIntersection in '..\Protocols\ProtocolForwardIntersection.pas',
  ProtocolRectangularAdjustment in '..\Protocols\ProtocolRectangularAdjustment.pas',
  ProtocolResection in '..\Protocols\ProtocolResection.pas',
  ProtocolCheckMeasurements in '..\Protocols\ProtocolCheckMeasurements.pas',
  ProtocolLevelling in '..\Protocols\ProtocolLevelling.pas',
  ProtocolTransformation in '..\Protocols\ProtocolTransformation.pas',
  ProtocolParcelArea in '..\Protocols\ProtocolParcelArea.pas',
  dbtest in 'dbtest.pas' {dbtestForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TGeoSoftForm, GeoSoftForm);
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
  Application.CreateForm(TdbtestForm, dbtestForm);
  Application.Run;
end.
