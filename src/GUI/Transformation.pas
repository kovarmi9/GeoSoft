unit Transformation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Math, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin, Vcl.ExtCtrls,
  Vcl.Grids, PointPrefixState, Point, PointsUtilsSingleton, GeoRow,
  GeoDataFrame, GeoGridBridge, GeoAlgorithmTransformation,
  ProtocolTable, CoordOrderState, GeoGrid, GeoFieldsGrid, GeoColumnValidation,
  CalcBase, Vcl.Menus;

type
  TTransformationForm = class(TCalcBaseForm)
    ComboBoxKind: TComboBox;
    StaticTextKind: TStaticText;
    Grid: TGeoFieldsGrid;
    PanelSummary: TPanel;
    LabelSummary: TLabel;
    ButtonUncheckUp: TButton;
    EditUpLimit: TEdit;
    Splitter1: TSplitter;
    Memo1: TMemo;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure KeyChanged(Sender: TObject);
    procedure CalculateClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure GridGetEditText(Sender: TObject; ACol, ARow: Integer;
      var Value: string);
    procedure ButtonUncheckUpClick(Sender: TObject);
  private
    FAlg: TTransformationFrameAlgorithm;
    FFrame: TGeoDataFrame;
    FRows: TArray<Integer>;   // grid row each frame row came from
    FOldNumber: Int64;        // target number before the edit
    procedure FillFromList(ARow: Integer; ANumberField, AYField,
      AXField: TGeoField; const APoint: Point.TPoint);
    function IsGiven(APointNumber: Int64): Boolean;
    procedure BuildFrame;
    procedure Recompute;
    procedure ShowSummary;
    procedure WriteResiduals(ARole: Integer; const ACaption: string);
    procedure WriteSummary;
    procedure WriteKey;
    procedure WriteDetermined;
  protected
    function GridNumber(AFrameRow: Integer): string; override;
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
  FFrame := TGeoDataFrame.Create(
    [Uloha, CB, Y, X, CBm, Ym, Xm, TypS, Vy, Vx, Sxy, KK, Poznamka]);
end;

destructor TTransformationForm.Destroy;
begin
  FFrame.Free;
  FAlg.Free;
  inherited;
end;

// Y, X, the source pair and dY, dX follow the setting
procedure TTransformationForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
end;

// Writes the number and the coordinates of a point into a row
procedure TTransformationForm.FillFromList(ARow: Integer; ANumberField,
  AYField, AXField: TGeoField; const APoint: Point.TPoint);
begin
  Grid.Cells[Grid.FieldToCol(ANumberField), ARow] :=
    Format('%.15d', [APoint.PointNumber]);
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
    FOldNumber := StrToInt64Def(Trim(Value), 0);
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
    PointNumber := StrToInt64Def(Trim(Grid.Cells[ACol, ARow]), 0);

    if PointNumber <> FOldNumber then
    begin
      // Coordinates of the old given point go
      if IsGiven(FOldNumber) and not IsGiven(PointNumber) then
      begin
        Grid.Cells[Grid.FieldToCol(Y), ARow] := '';
        Grid.Cells[Grid.FieldToCol(X), ARow] := '';
      end;

      // Source of the old number goes too
      SourceNumber :=
        StrToInt64Def(Trim(Grid.Cells[Grid.FieldToCol(CBm), ARow]), 0);
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
    PointNumber := StrToInt64Def(Trim(Grid.Cells[ACol, ARow]), 0);
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

// Unticks every point with Up over the limit
procedure TTransformationForm.ButtonUncheckUpClick(Sender: TObject);
var
  Limit, Up: Double;
  R: Integer;
  Over: TArray<Integer>;
begin
  if not TryEvaluateExpression(Trim(EditUpLimit.Text), Limit) then
  begin
    ShowMessage('Zadejte hodnotu Up.');
    Exit;
  end;

  // Read first, every untick recomputes
  for R := Grid.FixedRows to Grid.RowCount - 1 do
    if Grid.Checked[R] and
       TryStrToFloat(Grid.Cells[Grid.FieldToCol(Sxy), R], Up, FS) and
       (Up > Limit) then
      Over := Over + [R];

  for R in Over do
    Grid.Checked[R] := False;
end;

// One frame row per grid row, TypS by the box and the list
procedure TTransformationForm.BuildFrame;
var
  R: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
  Given: Boolean;
begin
  FFrame.ClearData;
  SetLength(FRows, 0);

  for R := Grid.FixedRows to Grid.RowCount - 1 do
  begin
    Grid.GetGeoRow(R, Row);
    if (Trim(string(Row.CB)) = '') and (Trim(string(Row.CBm)) = '') then
      Continue;                        // an empty row

    Row.Uloha := FAlg.TaskCode;
    PointNumber := StrToInt64Def(Trim(string(Row.CB)), 0);
    Given := IsGiven(PointNumber);

    // A point from the list brings its own quality code
    if Given then
      Row.KK := TPointDictionary.GetInstance.GetPoint(PointNumber).Quality;

    // Not in the list is determined, the box only splits the given ones
    if not Given then
      Row.TypS := DRUH_URCOVANY
    else if Grid.Checked[R] then
      Row.TypS := DRUH_IDENTICKY
    else
      Row.TypS := DRUH_KONTROLNI;

    FFrame.AddRow(Row);
    SetLength(FRows, Length(FRows) + 1);
    FRows[High(FRows)] := R;
  end;
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
    Grid.Cells[Grid.FieldToCol(Vy), R] := '';
    Grid.Cells[Grid.FieldToCol(Vx), R] := '';
    Grid.Cells[Grid.FieldToCol(Sxy), R] := '';
  end;
  FrameToGrid(Grid, FFrame, FRows, [Y, X, Vy, Vx, Sxy]);

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
    ShowProtocol(Memo1.Lines);   // the old one goes, the new says why
    ShowMessage(Trim(FAlg.Warnings.Text));
    Exit;
  end;

  Stored := 0;
  Unnumbered := 0;
  for I := 0 to FFrame.Count - 1 do
  begin
    if (FFrame.Rows[I].TypS <> DRUH_URCOVANY) or
       IsNan(FFrame.Rows[I].X) then
      Continue;

    PointNumber := StrToInt64Def(Trim(string(FFrame.Rows[I].CB)), 0);
    if PointNumber = 0 then
    begin
      Inc(Unnumbered);       // the list needs a number
      Continue;
    end;

    // The quality code of a new point comes from the toolbar
    FFrame.Rows[I].KK := StrToIntDef(Trim(GPointPrefix.KK), 0);
    // No height from the key, a stored point keeps its own
    if IsNan(FFrame.Rows[I].Z) and
       TPointDictionary.GetInstance.PointExists(PointNumber) then
      FFrame.Rows[I].Z := TPointDictionary.GetInstance.GetPoint(PointNumber).Z;
    StorePoint(FFrame.Rows[I]);
    Inc(Stored);
  end;

  // A renumbered point goes to the grid with its new number
  FrameToGrid(Grid, FFrame, FRows, [CB]);
  ShowProtocol(Memo1.Lines);

  Msg := Format('Do seznamu souřadnic uloženo bodů: %d', [Stored]);
  if Unnumbered > 0 then
    Msg := Msg + sLineBreak +
      Format('Neuloženo, chybí číslo bodu: %d', [Unnumbered]);
  ShowMessage(Msg);
end;

// Saves what was typed in, Načíst computes the results again
procedure TTransformationForm.SaveClick(Sender: TObject);
var
  FileName: string;
begin
  if not CommitEditing then
    Exit;            // the typed value is invalid
  BuildFrame;
  TTransformationFrameAlgorithm.ClearResults(FFrame);   // input only

  if FFrame.Count = 0 then
  begin
    ShowMessage('Zápisník je prázdný, nic se neuložilo.');
    Exit;
  end;

  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  FFrame.ToCSV(FileName, ';', ',');
  ShowMessage(Format('Uloženo %d řádků do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]));
end;

// One row of the file is one row of the grid, TypS gives the check box
procedure TTransformationForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I, R: Integer;
begin
  Memo1.Clear;
  ClearGrid(Grid, Grid.FixedRows + AFrame.Count + 1);
  Grid.DefaultChecked := True;   // all boxes ticked again

  R := Grid.FixedRows;
  for I := 0 to AFrame.Count - 1 do
    if PutRow(Grid, R, AFrame.Rows[I], I, ABad) then
    begin
      Grid.Checked[R] := AFrame.Rows[I].TypS <> DRUH_KONTROLNI;
      Inc(R);
    end;
  Grid.RowCount := R + 1;
  Recompute;
end;

// Č. is the row of the grid
function TTransformationForm.GridNumber(AFrameRow: Integer): string;
begin
  Result := IntToStr(FRows[AFrameRow] - Grid.FixedRows + 1);
end;

// The key with its check, then the determined points
procedure TTransformationForm.WriteProtocol(ALines: TStrings);
const
  KIND_TEXT: array[TTransformationType] of string = ('Shodnostní',
    'Podobnostní (Helmertova)', 'Afinní');
var
  I: Integer;
  Row: TGeoRow;
begin
  if not BeginProtocol(ALines, 'Transformace', FAlg.Info.Valid, FFrame,
    FAlg.Warnings) then
    Exit;
  Prot.Text(KIND_TEXT[FAlg.Kind]);

  // The pairs of the key: Z the source point, Do the target point
  Prot.Section('IDENTICKÉ BODY');
  Prot.Columns([ColNumber, ColText('', 3), ColPoint, ColPair]);
  for I := 0 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    if (Row.TypS <> DRUH_IDENTICKY) or IsNan(Row.Sxy) then
      Continue;
    Prot.Row([GridNumber(I), 'Z:', PointId(string(Row.CBm)),
              CoordPair(Row.Xm, Row.Ym)]);
    Prot.Row(['', 'Do:', PointId(string(Row.CB)),
              CoordPair(Row.X, Row.Y)]);
  end;

  WriteResiduals(DRUH_IDENTICKY, 'ODCHYLKY TRANSFORMACE');
  WriteSummary;
  if FAlg.Info.CheckCount > 0 then
    WriteResiduals(DRUH_KONTROLNI, 'KONTROLNÍ BODY (mimo klíč)');
  WriteKey;

  if FAlg.Info.DeterminedCount > 0 then
  begin
    Prot.Section('TRANSFORMACE - PODROBNÉ BODY');
    WriteKey;
    WriteDetermined;
  end;

  Prot.Finish(FAlg.Warnings);
end;

// Vy, Vx, Sxy and the band of the rows of one role
procedure TTransformationForm.WriteResiduals(ARole: Integer;
  const ACaption: string);
var
  I: Integer;
  Row: TGeoRow;
begin
  Prot.Section(ACaption);
  Prot.Columns([ColNumber, ColField(CB), ColField(Vy), ColField(Vx),
    ColField(Sxy), ColField(KK), ColText('')]);
  for I := 0 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    if (Row.TypS = ARole) and not IsNan(Row.Sxy) then
      Prot.FrameRow(Row, [GridNumber(I), BandText(Row.Sxy, Row.KK)]);
  end;
end;

// KatV 13.7 to 13.9 and § 75 (4), the algorithm has counted the bands
procedure TTransformationForm.WriteSummary;
var
  I: Integer;
  Row: TGeoRow;
  Info: TTransformationInfo;
begin
  Info := FAlg.Info;
  Prot.Line;
  if not IsNan(Info.MeanError) then
    Prot.Text('Střední chyba transformace: ' + Num(Info.MeanError));
  // One code, when all points share it
  if Info.Quality >= 0 then
    Prot.Text(QualityText(Info.Quality));

  Prot.Text('Odchylky dle KatV, body přílohy 13.7 až 13.9');
  Prot.Text('Celkem bodů: ' + IntToStr(Info.Total) +
            '   z toho do Mxy: ' + IntToStr(Info.InMxy) +
            '   do Uxy: ' + IntToStr(Info.InUxy) +
            '   přes Uxy: ' + IntToStr(Info.OverUxy) +
            '   % do Mxy: ' + IntToStr(Round(100 * Info.InMxy / Info.Total)));
  if Info.Unknown > 0 then
    Prot.Text('Body bez Mxy (' + NoMxy + '): ' + IntToStr(Info.Unknown))
  else
  begin
    // KatV 13.8, every point within Uxy, over 20 points 40 % within Mxy
    Prot.Text('Všechny body do Uxy: ' + Fulfilled(Info.OverUxy = 0));
    if Info.Total > 20 then
      Prot.Text('Nejméně 40 % bodů do Mxy: ' +
                Fulfilled(100 * Info.InMxy >= 40 * Info.Total));
  end;

  // KatV § 75 (4), circle of the identical points
  Prot.Text('Kružnice rozmístění identických bodů (§ 75 odst. 4), ' +
            'poloměr: ' + Num(Info.CircleRadius));
  Prot.Text('Zaměřené body uvnitř kružnice: ' +
            Fulfilled(Length(Info.OutsideRows) = 0));
  for I := 0 to High(Info.OutsideRows) do
  begin
    Row := FFrame.Rows[Info.OutsideRows[I]];
    if Trim(string(Row.CB)) = '' then
      Prot.Text('  mimo kružnici: ' + PointId(string(Row.CBm)))
    else
      Prot.Text('  mimo kružnici: ' + PointId(string(Row.CB)));
  end;
end;

// The coefficients and the formula
procedure TTransformationForm.WriteKey;
var
  Info: TTransformationInfo;
begin
  Info := FAlg.Info;
  Prot.Section('TRANSFORMAČNÍ KOEFICIENTY');
  Prot.Text('A[1,1] = ' + Num(Info.A11, 10) +
            '    A[1,2] = ' + Num(Info.A12, 10));
  Prot.Text('A[2,1] = ' + Num(Info.A21, 10) +
            '    A[2,2] = ' + Num(Info.A22, 10));
  Prot.Text('Posun Y = ' + Num(Info.ShiftY) +
            '    Posun X = ' + Num(Info.ShiftX));
  if not IsNan(Info.Scale) then
    Prot.Text('Měřítko = ' + Num(Info.Scale, 10));
  Prot.Text('Yn = PosunY + A[1,1]*Ys + A[1,2]*Xs');
  Prot.Text('Xn = PosunX + A[2,1]*Ys + A[2,2]*Xs');
end;

// Z: the source point, Do: the target point with its quality code
procedure TTransformationForm.WriteDetermined;
var
  I: Integer;
  Row: TGeoRow;
begin
  Prot.Section('');
  Prot.Columns([ColNumber, ColText('', 3), ColPoint, ColPair,
    ColField(KK)]);
  for I := 0 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    if (Row.TypS <> DRUH_URCOVANY) or IsNan(Row.X) then
      Continue;
    Prot.Row([GridNumber(I), 'Z:', PointId(string(Row.CBm)),
              CoordPair(Row.Xm, Row.Ym)]);
    if Trim(string(Row.CB)) = '' then
      Prot.Row(['', 'Do:', '', CoordPair(Row.X, Row.Y), ''],
               '*** neuloženo, chybí číslo bodu ***')
    else
      Prot.Row(['', 'Do:', PointId(string(Row.CB)),
                CoordPair(Row.X, Row.Y), IntToStr(Row.KK)],
               UpdatedTail(Row));
  end;
end;

end.
