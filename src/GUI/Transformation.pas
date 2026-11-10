unit Transformation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Math, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin, Vcl.ExtCtrls,
  Vcl.Grids, PointPrefixState, Point, PointDictionary, GeoRow,
  GeoDataFrame, GeoGridBridge, GeoAlgorithmTransformation,
  CoordOrderState, GeoGrid, GeoFieldsGrid, CalcBase,
  Vcl.Menus, PointNumber, Validation, ProtocolTransformation;

type
  TTransformationForm = class(TCalcBaseForm)
    ComboBoxKind: TComboBox;
    StaticTextKind: TStaticText;
    Grid: TGeoFieldsGrid;
    PanelSummary: TPanel;
    LabelSummary: TLabel;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure KeyChanged(Sender: TObject);
    procedure CalculateClick(Sender: TObject);
    procedure GridGetEditText(Sender: TObject; ACol, ARow: Integer;
      var Value: string);
  private
    FAlg: TTransformationFrameAlgorithm;
    FOldNumber: Int64;        // target number before the edit
    procedure FillFromList(ARow: Integer; ANumberField, AYField,
      AXField: TGeoField; const APoint: Point.TPoint);
    function IsGiven(APointNumber: Int64): Boolean;
    procedure Recompute;
    procedure ShowSummary;
  protected
    function BuildFrame: Boolean; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
    procedure WriteProtocol(ALines: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  TransformationForm: TTransformationForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'transformace.csv';   // saved next to exe

constructor TTransformationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TTransformationFrameAlgorithm.Create;
  FNotebookName := CSV_NAME;
  // M1 dY, M2 dX, M4 Sxy
  FFrame := TGeoDataFrame.Create(
    [Checked, CB, Y, X, CBm, Ym, Xm, Typ, M1, M2, M4, KK, Popis]);
end;

destructor TTransformationForm.Destroy;
begin
  FAlg.Free;
  inherited;
end;

// Y, X, the source pair and dY, dX follow the setting
procedure TTransformationForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, [], M1, M2);       // dY and dX as Y and X
end;

// Writes the number and the coordinates of a point into a row
procedure TTransformationForm.FillFromList(ARow: Integer; ANumberField,
  AYField, AXField: TGeoField; const APoint: Point.TPoint);
begin
  Grid.Cells[Grid.FieldToCol(ANumberField), ARow] :=
    TPointNumber.ToText(APoint.PointNumber);
  Grid.Cells[Grid.FieldToCol(AYField), ARow] := FloatToStr(APoint.Y, FS);
  Grid.Cells[Grid.FieldToCol(AXField), ARow] := FloatToStr(APoint.X, FS);
end;

// In the list before this job, not stored by this form
function TTransformationForm.IsGiven(APointNumber: Int64): Boolean;
begin
  Result := (APointNumber <> 0) and
    TPointDictionary.GetInstance.PointExists(APointNumber) and
    not IsNewPoint(APointNumber);
end;

// The target number before the edit
procedure TTransformationForm.GridGetEditText(Sender: TObject;
  ACol, ARow: Integer; var Value: string);
begin
  if ACol = Grid.FieldToCol(CB) then
    TPointNumber.TryParse(Value, FOldNumber);
end;

// A given target fills itself and suggests the source -n
procedure TTransformationForm.PointCommitted(Sender: TObject;
  ACol, ARow: Integer);
var
  PointNumber, SourceNumber: Int64;
  Points: TPointDictionary;
begin
  if ARow < Grid.FixedRows then
    Exit;
  Points := TPointDictionary.GetInstance;

  if ACol = Grid.FieldToCol(CB) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    TPointNumber.TryParse(Grid.Cells[ACol, ARow], PointNumber);

    if PointNumber <> FOldNumber then
    begin
      // Coordinates of the old given point go
      if IsGiven(FOldNumber) and not IsGiven(PointNumber) then
      begin
        Grid.Cells[Grid.FieldToCol(Y), ARow] := '';
        Grid.Cells[Grid.FieldToCol(X), ARow] := '';
      end;

      // Source of the old number goes too
      TPointNumber.TryParse(Grid.Cells[Grid.FieldToCol(CBm), ARow],
        SourceNumber);
      if (FOldNumber <> 0) and (SourceNumber = -FOldNumber) then
      begin
        Grid.Cells[Grid.FieldToCol(CBm), ARow] := '';
        Grid.Cells[Grid.FieldToCol(Ym), ARow] := '';
        Grid.Cells[Grid.FieldToCol(Xm), ARow] := '';
      end;
    end;
    FOldNumber := 0;

    // A deleted number still has to recompute, so no Exit here
    if PointNumber <> 0 then
    begin
      if IsGiven(PointNumber) then
        FillFromList(ARow, CB, Y, X, Points.GetPoint(PointNumber));

      // Source under the negative number, a typed one stays
      if (Trim(Grid.Cells[Grid.FieldToCol(CBm), ARow]) = '') and
         Points.PointExists(-PointNumber) then
        FillFromList(ARow, CBm, Ym, Xm, Points.GetPoint(-PointNumber));
    end;
  end
  else if ACol = Grid.FieldToCol(CBm) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    TPointNumber.TryParse(Grid.Cells[ACol, ARow], PointNumber);
    // A source may be typed by hand
    if (PointNumber <> 0) and Points.PointExists(PointNumber) then
      FillFromList(ARow, CBm, Ym, Xm, Points.GetPoint(PointNumber));
  end;

  Recompute;
end;

// A check box or the type of the transformation has changed
procedure TTransformationForm.KeyChanged(Sender: TObject);
begin
  Recompute;
end;

// One frame row per grid row, Typ by the box and the list
function TTransformationForm.BuildFrame: Boolean;
var
  R: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
  Given: Boolean;
begin
  Result := True;
  FFrame.ClearData;

  for R := Grid.FixedRows to Grid.RowCount - 1 do
  begin
    Grid.GetGeoRow(R, Row);
    if (Row.CB = 0) and (Row.CBm = 0) then
      Continue;                        // an empty row

    PointNumber := Row.CB;
    Given := IsGiven(PointNumber);

    // A point from the list brings its own quality code
    if Given then
      Row.KK := TPointDictionary.GetInstance.GetPoint(PointNumber).Quality;

    // Not in the list is determined, the box only splits the given ones
    if not Given then
      Row.Typ := DRUH_URCOVANY
    else if Row.Checked then
      Row.Typ := DRUH_IDENTICKY
    else
      Row.Typ := DRUH_KONTROLNI;

    AddRow(Row, R);
  end;
  TTransformationFrameAlgorithm.ClearResults(FFrame);   // input only
end;

// Every change rebuilds the frame and computes again
procedure TTransformationForm.Recompute;
var
  R: Integer;
begin
  BuildFrame;

  case ComboBoxKind.ItemIndex of
    1: FAlg.Kind := ttSimilarity;
    2: FAlg.Kind := ttAffine;
  else
    FAlg.Kind := ttCongruent;
  end;
  FAlg.Calculate(FFrame);

  for R := Grid.FixedRows to Grid.RowCount - 1 do
  begin
    Grid.Cells[Grid.FieldToCol(M1), R] := '';
    Grid.Cells[Grid.FieldToCol(M2), R] := '';
    Grid.Cells[Grid.FieldToCol(M4), R] := '';
  end;
  FrameToGrid(Grid, FFrame, FRows, [Y, X, M1, M2, M4]);

  ShowSummary;
end;

// The line under the grid: the points of the key and its scale
procedure TTransformationForm.ShowSummary;
var
  Summary: string;
  I: Integer;
begin
  if FFrame.Count = 0 then
  begin
    LabelSummary.Caption := '';    // an empty form says nothing
    Exit;
  end;

  Summary := Format('Identických bodů v klíči: %d', [FAlg.Info.PointCount]);

  if not IsNan(FAlg.Info.Scale) then
    Summary := Summary + '    Měřítko transformace: ' +
      FormatFloat('0.000000', FAlg.Info.Scale, FS);
  // A failed key says why, the notes show too
  for I := 0 to FAlg.Errors.Count - 1 do
    Summary := Summary + '    ' + FAlg.Errors[I];
  for I := 0 to FAlg.Warnings.Count - 1 do
    Summary := Summary + '    ' + FAlg.Warnings[I];

  LabelSummary.Caption := Summary;
end;

// Stores the determined points into the coordinate list
procedure TTransformationForm.CalculateClick(Sender: TObject);
var
  I, Stored, Unnumbered: Integer;
  PointNumber: Int64;
  Msg: string;
begin
  if not CommitEditing then
    Exit;            // the typed value is invalid
  ForgetAnswers;     // ask again about points already in the list
  Recompute;
  if not FAlg.Info.Valid then
  begin
    ShowProtocol;   // the old one goes, the new says why
    ShowMessage(Trim(FAlg.Errors.Text));
    Exit;
  end;

  Stored := 0;
  Unnumbered := 0;
  for I := 0 to FFrame.Count - 1 do
  begin
    if (FFrame.Rows[I].Typ <> DRUH_URCOVANY) or
       IsNan(FFrame.Rows[I].X) then
      Continue;

    PointNumber := FFrame.Rows[I].CB;
    if PointNumber = 0 then
    begin
      Inc(Unnumbered);       // the list needs a number
      Continue;
    end;

    // The quality code of a new point comes from the toolbar
    FFrame.Rows[I].KK := TValidation.QualityFromText(GPointPrefix.KK);
    // No height from the key, a stored point keeps its own
    if IsNan(FFrame.Rows[I].Z) and
       TPointDictionary.GetInstance.PointExists(PointNumber) then
      FFrame.Rows[I].Z := TPointDictionary.GetInstance.GetPoint(PointNumber).Z;
    StorePoint(FFrame.Rows[I]);
    Inc(Stored);
  end;

  // A renumbered point goes to the grid with its new number
  FrameToGrid(Grid, FFrame, FRows, [CB]);
  ShowProtocol;

  Msg := Format('Do seznamu souřadnic uloženo bodů: %d', [Stored]);
  if Unnumbered > 0 then
    Msg := Msg + sLineBreak +
      Format('Neuloženo, chybí číslo bodu: %d', [Unnumbered]);
  ShowMessage(Msg);
end;

// One row of the file is one row of the grid, Typ gives the check box
procedure TTransformationForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I, R: Integer;
begin
  ClearGrid(Grid, Grid.FixedRows + AFrame.Count + 1);

  R := Grid.FixedRows;
  for I := 0 to AFrame.Count - 1 do
    if PutRow(Grid, R, AFrame.Rows[I], I, ABad) then
      Inc(R);
  Grid.RowCount := R + 1;
  Recompute;
end;

procedure TTransformationForm.WriteProtocol(ALines: TStrings);
begin
  TTransformationProtocol.Write(Prot, ALines, FFrame, FAlg, ProtocolRows);
end;

end.
