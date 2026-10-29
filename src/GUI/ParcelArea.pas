unit ParcelArea;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Types,
  PointsUtilsSingleton, PointPrefixState,
  Point,
  CoordOrderState, ProtocolTable, SettingsState,
  GeoRow, GeoDataFrame, GeoGrid, GeoFieldsGrid,
  GeoAlgorithmLHuilier,
  CalcBase, Vcl.Menus, Vcl.Mask;

type
  TParcelAreaForm = class(TCalcBaseForm)
    StringGrid1: TGeoFieldsGrid;
    PanelParcel: TPanel;
    EditParcel: TLabeledEdit;
    procedure CalculateClick(Sender: TObject);
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
  private
    FAlg: TLHuilierAlgorithm;
    procedure FillFromDict(const R: Integer);
  protected
    function BuildFrame: Boolean; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ParcelAreaForm: TParcelAreaForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'vymera.csv';   // saved next to exe

constructor TParcelAreaForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TLHuilierAlgorithm.Create;
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create([Uloha, CB, X, Y]);
end;

destructor TParcelAreaForm.Destroy;
begin
  FAlg.Free;
  inherited;
end;

procedure TParcelAreaForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(StringGrid1, []);
end;

procedure TParcelAreaForm.FillFromDict(const R: Integer);
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  PointNumber := StrToInt64Def(
    StringGrid1.Cells[StringGrid1.FieldToCol(CB), R], -1);
  if PointNumber = 0 then Exit;

  if LookupPoint(PointNumber, ListPoint) then
  begin
    StringGrid1.Cells[StringGrid1.FieldToCol(Y), R] :=
      FloatToStr(ListPoint.Y, FS);
    StringGrid1.Cells[StringGrid1.FieldToCol(X), R] :=
      FloatToStr(ListPoint.X, FS);
  end;
end;

// Fills coordinates from the list, a missing point is offered via AddPoint.
// The first column carries the row number.
procedure TParcelAreaForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
begin
  if ARow < StringGrid1.FixedRows then Exit;

  if ACol = StringGrid1.FieldToCol(CB) then
  begin
    NormalizePointCell(StringGrid1, ACol, ARow);
    FillFromDict(ARow);
  end;
end;

// Every row with a point number is a corner. False, with a message, when
// a corner is not in the list.
function TParcelAreaForm.BuildFrame: Boolean;
var
  R: Integer;
  PointNumber: Int64;
  Row: TGeoRow;
  ListPoint: Point.TPoint;
begin
  Result := True;
  FFrame.ClearData;

  for R := StringGrid1.FixedRows to StringGrid1.RowCount - 1 do
  begin
    StringGrid1.GetGeoRow(R, Row);
    PointNumber := StrToInt64Def(Trim(string(Row.CB)), 0);
    if PointNumber = 0 then
      Continue;

    if not TPointDictionary.GetInstance.PointExists(PointNumber) then
    begin
      ShowMessage(Format('Bod %s není v seznamu souřadnic.',
        [Trim(string(Row.CB))]));
      Result := False;
      Exit;
    end;

    // The list decides, the cells only show it
    ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
    Row.Uloha := ULOHA_VYMERA;
    Row.X := ListPoint.X;
    Row.Y := ListPoint.Y;
    FFrame.AddRow(Row);
  end;
end;

procedure TParcelAreaForm.CalculateClick(Sender: TObject);
begin
  if not CommitEditing then
    Exit;            // the typed value is invalid
  MemoProtocol.Clear;       // old area would look like a new one

  // The frame is the only input, so every run rebuilds it
  if not BuildFrame then
    Exit;
  FAlg.Calculate(FFrame);
  ShowProtocol;

  if IsNan(FAlg.Area) then
    ShowMessage(Trim(FAlg.Warnings.Text));
end;

// Every row is a corner
procedure TParcelAreaForm.LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings);
var
  I, R: Integer;
begin
  ClearGrid(StringGrid1, StringGrid1.FixedRows + AFrame.Count + 1);

  R := StringGrid1.FixedRows;
  for I := 0 to AFrame.Count - 1 do
    if PutRow(StringGrid1, R, AFrame.Rows[I], I, ABad) then
      Inc(R);
  StringGrid1.RowCount := R + 1;
end;

procedure TParcelAreaForm.WriteProtocol(ALines: TStrings);
begin
  if not BeginProtocol(ALines, 'Výpočet výměr', not IsNan(FAlg.Area),
    FFrame, FAlg.Warnings) then
    Exit;
  if Trim(EditParcel.Text) <> '' then
    Prot.Text('Parcela ' + Trim(EditParcel.Text));
  FrameTable('', FFrame, [ColNumber, ColField(CB), ColPair], 0,
    FFrame.Count - 1);
  Prot.Values(['Plocha', Num(FAlg.Area, GSettings.AreaDecimals) + ' m²']);
  // KatV § 82 (2), whole m², at least 1 m², none after an error
  if FAlg.Warnings.Count = 0 then
    Prot.Values(['Výměra',
      IntToStr(Max(1, Trunc(FAlg.Area + 0.5))) + ' m²']);
  Prot.Finish(FAlg.Warnings);
end;

end.
