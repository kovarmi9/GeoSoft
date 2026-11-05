unit ParcelArea;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, System.Types,
  PointDictionary, PointPrefixState,
  Point,
  CoordOrderState, ProtocolTable, SettingsState,
  GeoRow, GeoDataFrame, GeoGrid, GeoFieldsGrid,
  GeoAlgorithmLHuilier,
  CalcBase, Vcl.Menus, Vcl.Mask, PointNumber;

type
  TParcelAreaForm = class(TCalcBaseForm)
    Grid: TGeoFieldsGrid;
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
  FFrame := TGeoDataFrame.Create([CB, X, Y]);
end;

destructor TParcelAreaForm.Destroy;
begin
  FAlg.Free;
  inherited;
end;

procedure TParcelAreaForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
end;

procedure TParcelAreaForm.FillFromDict(const R: Integer);
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  TPointNumber.TryParse(
    Grid.Cells[Grid.FieldToCol(CB), R], PointNumber);
  if PointNumber = 0 then Exit;

  if LookupPoint(PointNumber, ListPoint) then
  begin
    Grid.Cells[Grid.FieldToCol(Y), R] :=
      FloatToStr(ListPoint.Y, FS);
    Grid.Cells[Grid.FieldToCol(X), R] :=
      FloatToStr(ListPoint.X, FS);
  end;
end;

// Fills coordinates from the list, a missing point is offered via AddPoint.
// The first column carries the row number.
procedure TParcelAreaForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
begin
  if ARow < Grid.FixedRows then Exit;

  if ACol = Grid.FieldToCol(CB) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
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

  for R := Grid.FixedRows to Grid.RowCount - 1 do
  begin
    Grid.GetGeoRow(R, Row);
    PointNumber := Row.CB;
    if PointNumber = 0 then
      Continue;

    if not TPointDictionary.GetInstance.PointExists(PointNumber) then
    begin
      ShowMessage(Format('Bod %s není v seznamu souřadnic.',
        [TPointNumber.ToDisplay(Row.CB)]));
      Result := False;
      Exit;
    end;

    // The list decides, the cells only show it
    ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
    Row.X := ListPoint.X;
    Row.Y := ListPoint.Y;
    AddRow(Row, R);
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
  ClearGrid(Grid, Grid.FixedRows + AFrame.Count + 1);

  R := Grid.FixedRows;
  for I := 0 to AFrame.Count - 1 do
    if PutRow(Grid, R, AFrame.Rows[I], I, ABad) then
      Inc(R);
  Grid.RowCount := R + 1;
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
