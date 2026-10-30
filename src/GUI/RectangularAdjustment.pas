unit RectangularAdjustment;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, Vcl.Mask, Math, Point,
  PointsUtilsSingleton, PointPrefixState, GeoRow, GeoDataFrame,
  GeoGridBridge, GeoGrid, GeoFieldsGrid, CoordOrderState, GeoFieldsDef,
  ProtocolTable, GeoAlgorithmTransformBase, GeoAlgorithmRectangularAdjustment;

type
  TRectangularAdjustmentForm = class(TCalcBaseForm)
    StringGrid1: TGeoFieldsGrid;
    PanelClosure: TPanel;
    LabelClosure: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure CalculateClick(Sender: TObject);
    procedure CellCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure GridCellSelectable(Sender: TObject; ACol, ARow: Integer;
      var ASelectable: Boolean);
  private
    FAlg: TRectangularAdjustmentAlgorithm;
    FRowNew: array of Boolean;      // listed point the user calls new
    FRowCB: array of string;        // last point number per row
    procedure SetCell(F: TGeoField; ARow: Integer; const S: string);
    procedure FillRow(const R: Integer);
    procedure RecalcLocal;
    procedure Recompute;
  protected
    function BuildFrame: Boolean; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure ApplySettings; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  RectangularAdjustmentForm: TRectangularAdjustmentForm;

implementation

{$R *.dfm}

uses
  SettingsState;

const
  CSV_NAME = 'konstrukcni_omerne_vyrovnani.csv';   // saved next to exe

constructor TRectangularAdjustmentForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TRectangularAdjustmentAlgorithm.Create;
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create([Uloha, CB, X, Y, Xm, Ym, SH, Poznamka, KK]);
end;

destructor TRectangularAdjustmentForm.Destroy;
begin
  FAlg.Free;
  inherited;
end;

procedure TRectangularAdjustmentForm.FormCreate(Sender: TObject);
var
  FilterData: TColumnFilterData;
begin
  // Left turn is written as a negative length
  FilterData := GeoFieldColumns[SH].Filter;
  FilterData.HasMinValue := False;
  StringGrid1.SetColumnFilterData(SH, FilterData);
end;

procedure TRectangularAdjustmentForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(StringGrid1, []);
end;

procedure TRectangularAdjustmentForm.ApplySettings;
begin
  FAlg.Scale := GSettings.Scale;
end;

// Writes one value by field, when the grid shows it
procedure TRectangularAdjustmentForm.SetCell(F: TGeoField; ARow: Integer;
  const S: string);
var
  C: Integer;
begin
  C := StringGrid1.FieldToCol(F);
  if C >= 0 then
    StringGrid1.Cells[C, ARow] := S;
end;

// Fills the row after its point number was committed
procedure TRectangularAdjustmentForm.FillRow(const R: Integer);
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
  CBText: string;
  Known: Boolean;
  First: Integer;
begin
  CBText := Trim(StringGrid1.Cells[StringGrid1.FieldToCol(CB), R]);
  PointNumber := StrToInt64Def(CBText, -1);
  if PointNumber = 0 then Exit;

  // Only a new number refills the row, so user edits survive
  if Length(FRowCB) <= R then
    SetLength(FRowCB, R + 1);
  if Length(FRowNew) <= R then
    SetLength(FRowNew, R + 1);
  if CBText = FRowCB[R] then Exit;

  FRowNew[R] := False;
  First := StringGrid1.FixedRows;
  Known := TPointDictionary.GetInstance.PointExists(PointNumber);

  // The closing row is the first point again, no second question
  if (R > First) and (Length(FRowCB) > First) and
    (CBText = FRowCB[First]) then
    FRowNew[R] := FRowNew[First]
  else if Known then
  begin
    // Duplicate point, the user chooses
    if Application.MessageBox(PChar(Format(
      'Bod %s již v seznamu existuje.' + sLineBreak +
      'Použít jeho souřadnice? (Ne = počítat ho jako nový)',
      [PointId(PointNumber)])), 'Dotaz',
      MB_YESNO or MB_ICONQUESTION) = IDNO then
      FRowNew[R] := True;
  end;
  Known := Known and not FRowNew[R];

  FRowCB[R] := CBText;

  if Known then
  begin
    ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
    SetCell(Y, R, FloatToStr(ListPoint.Y, FS));
    SetCell(X, R, FloatToStr(ListPoint.X, FS));
    SetCell(KK, R, IntToStr(ListPoint.Quality));
    SetCell(Poznamka, R, string(ListPoint.Description));
  end
  else
  begin
    SetCell(KK, R, GPointPrefix.KK);
    SetCell(Poznamka, R, GPointPrefix.Popis);
  end;
end;

// The adjusted shape and the closure, once the figure is closed
procedure TRectangularAdjustmentForm.RecalcLocal;
var
  I: Integer;
begin
  // The walk needs no point list, so the plain bridge is enough
  GridToFrame(StringGrid1, FFrame, ULOHA_KONSTRUKCNI_VYROVNANI, FRows);
  for I := 0 to FFrame.Count - 1 do
  begin
    FFrame.Rows[I].Xm := NaN;
    FFrame.Rows[I].Ym := NaN;
  end;
  FAlg.Calculate(FFrame);
  FrameToGrid(StringGrid1, FFrame, FRows, [Xm, Ym]);

  if IsNan(FAlg.ClosureAlong) then
    LabelClosure.Caption := 'Obrazec zatím není uzavřený'
  else
    LabelClosure.Caption := 'Uzávěr: podélný ' + Num(FAlg.ClosureAlong) +
      '    příčný ' + Num(FAlg.ClosureAcross);
end;

// The first point starts the figure, no length leads to it
procedure TRectangularAdjustmentForm.GridCellSelectable(Sender: TObject;
  ACol, ARow: Integer; var ASelectable: Boolean);
begin
  if (ARow = StringGrid1.FixedRows) and (ACol = StringGrid1.FieldToCol(SH)) then
    ASelectable := False;
end;

// Normalizes the number and refills the row
procedure TRectangularAdjustmentForm.CellCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if ARow < StringGrid1.FixedRows then
    Exit;

  if ACol = StringGrid1.FieldToCol(CB) then
  begin
    NormalizePointCell(StringGrid1, ACol, ARow);
    FillRow(ARow);
  end;

  // The adjustment spreads over all sides, so any change redraws all rows
  if (ACol = StringGrid1.FieldToCol(CB)) or
    (ACol = StringGrid1.FieldToCol(SH)) then
    RecalcLocal;
end;

// Fills the frame from the grid and marks the given points
function TRectangularAdjustmentForm.BuildFrame: Boolean;
var
  I, GridRow: Integer;
  PointNumber: Int64;
  ListPoint: Point.TPoint;
  IsGiven: Boolean;
begin
  Result := True;
  GridToFrame(StringGrid1, FFrame, ULOHA_KONSTRUKCNI_VYROVNANI, FRows);

  for I := 0 to FFrame.Count - 1 do
  begin
    GridRow := FRows[I];
    PointNumber := StrToInt64Def(string(FFrame.Rows[I].CB), 0);

    // A listed point is given, unless the user said it is a new one
    IsGiven := TPointDictionary.GetInstance.PointExists(PointNumber)
      and not ((GridRow <= High(FRowNew)) and FRowNew[GridRow]);

    if IsGiven then
    begin
      // The list decides, the cell can be edited
      ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
      FFrame.Rows[I].X := ListPoint.X;
      FFrame.Rows[I].Y := ListPoint.Y;
      FFrame.Rows[I].KK := ListPoint.Quality;
      SetCell(Y, GridRow, FloatToStr(ListPoint.Y, FS));
      SetCell(X, GridRow, FloatToStr(ListPoint.X, FS));
    end
    else
    begin
      // An old result read from the grid would look like a given point
      FFrame.Rows[I].X := NaN;
      FFrame.Rows[I].Y := NaN;
    end;
  end;
end;

// The frame is the only input, so every run rebuilds it
procedure TRectangularAdjustmentForm.Recompute;
var
  I: Integer;
  Back: TArray<Integer>;
begin
  BuildFrame;
  if FFrame.Count = 0 then
    Exit;

  for I := 0 to FFrame.Count - 1 do
    if not TRectangularAdjustmentAlgorithm.IsGiven(FFrame.Rows[I]) then
    begin
      // Old results would look valid if the run fails now
      SetCell(Y, FRows[I], '');
      SetCell(X, FRows[I], '');
    end;

  FAlg.Calculate(FFrame);

  SetLength(Back, FFrame.Count);
  for I := 0 to High(Back) do
    if FAlg.Valid and
      not TRectangularAdjustmentAlgorithm.IsGiven(FFrame.Rows[I]) then
      Back[I] := FRows[I]
    else
      Back[I] := -1;

  // Store first, a renumbered point goes to the grid with its new number.
  // The closing row repeats the first point, so it is stored once.
  for I := 0 to High(Back) - 1 do
    if Back[I] >= 0 then
    begin
      StorePoint(FFrame.Rows[I]);
      // A computed point stays computed in the next runs
      if Length(FRowNew) <= Back[I] then
        SetLength(FRowNew, Back[I] + 1);
      FRowNew[Back[I]] := True;
    end;

  FrameToGrid(StringGrid1, FFrame, Back, [CB, X, Y]);
  FrameToGrid(StringGrid1, FFrame, FRows, [Xm, Ym]);
  ShowProtocol;
end;

procedure TRectangularAdjustmentForm.CalculateClick(Sender: TObject);
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid
  MemoProtocol.Clear;
  Recompute;

  if FFrame.Count = 0 then
    ShowMessage('Zápisník je prázdný.')
  else if not FAlg.Valid then
    ShowMessage(Trim(FAlg.Warnings.Text));
end;

// Puts the loaded rows into the grid
procedure TRectangularAdjustmentForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I, R: Integer;
begin
  // Forget the old job
  ClearGrid(StringGrid1, StringGrid1.FixedRows + AFrame.Count + 1);
  SetLength(FRowCB, 0);
  SetLength(FRowNew, 0);
  SetLength(FRowCB, StringGrid1.RowCount);
  SetLength(FRowNew, StringGrid1.RowCount);

  R := StringGrid1.FixedRows;
  for I := 0 to AFrame.Count - 1 do
    if PutRow(StringGrid1, R, AFrame.Rows[I], I, ABad) then
    begin
      // Do not ask again for this number
      FRowCB[R] := Trim(StringGrid1.Cells[StringGrid1.FieldToCol(CB), R]);
      // Empty X means a new point
      FRowNew[R] := IsNan(AFrame.Rows[I].X);
      Inc(R);
    end;

  // One empty row at the end
  StringGrid1.RowCount := R + 1;
  RecalcLocal;
end;

// Sides with their corrections, the closure, the key and the points
procedure TRectangularAdjustmentForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Row: TGeoRow;
  Residual: TPointResidual;
  Kind, Dist, Correction, Tail: string;
begin
  Prot.Title(ALines, 'Konstrukční oměrné s vyrovnáním');
  Prot.Text('Měřítko délek = ' + Num(FAlg.Scale, 7));

  if FAlg.Valid then
  begin
    Prot.Section('');
    Prot.Values(['Uzávěr podélný', Num(FAlg.ClosureAlong),
      'Uzávěr příčný', Num(FAlg.ClosureAcross)]);

    Prot.Section('BODY OBRAZCE');
    Prot.Columns([ColNumber, ColField(CB), ColLength('Délka'),
      ColLength('Oprava'), ColPair, ColText('Typ')]);
    for I := 0 to FFrame.Count - 1 do
    begin
      Row := FFrame.Rows[I];

      Tail := '';
      if TRectangularAdjustmentAlgorithm.IsGiven(Row) then
        Kind := 'daný'
      else
      begin
        Kind := 'vypočtený';
        // The closing row repeats the first point
        if I < FFrame.Count - 1 then
          Tail := UpdatedTail(Row);
      end;

      // The first point has no side in front of it
      if I = 0 then
      begin
        Dist := '';
        Correction := '';
      end
      else
      begin
        Dist := Num(Row.SH);
        Correction := Num(FAlg.Adjusted[I] - Row.SH * FAlg.Scale);
      end;

      Prot.FrameRow(Row, [GridNumber(I), Dist, Correction, Kind], Tail);
    end;
    Prot.Line;

    Prot.Section('SHODNOSTNÍ TRANSFORMACE NA DANÉ BODY');
    Prot.Columns([ColPoint, ColLength('vy'), ColLength('vx')]);
    for Residual in FAlg.Residuals do
      Prot.Row([PointId(Residual.PointNumber), Num(Residual.Vy),
                Num(Residual.Vx)]);
    Prot.Line;
    if not IsNan(FAlg.MeanError) then
      Prot.Values(['Střední chyba', Num(FAlg.MeanError)]);
  end;

  Prot.Finish(FAlg.Warnings);
end;

end.
