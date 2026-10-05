unit ParcelArea;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Types,
  PointsUtilsSingleton, PointPrefixState,
  Point,
  CoordOrderState, ProtocolArea,
  GeoRow, GeoDataFrame, GeoGrid, GeoFieldsGrid,
  GeoAlgorithmLHuilier,
  CalcBase, Vcl.Menus;

type
  TParcelAreaForm = class(TCalcBaseForm)
    StringGrid1: TGeoFieldsGrid;
    Memo1: TMemo;
    PanelCalculate: TPanel;
    Calculate: TButton;
    Save: TButton;
    procedure CalculateClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
  private
    FAlg: TLHuilierAlgorithm;
    FFrame: TGeoDataFrame;       // the input of the run
    FProtocol: TAreaProtocol;
    procedure FillFromDict(const R: Integer);
    function  BuildFrame: Boolean;
  protected
    procedure ApplyCoordOrderToGrids; override;
    procedure WriteProtocol(ALines: TStrings); override;
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
  FFrame := TGeoDataFrame.Create([Uloha, CB, X, Y]);
  FProtocol := TAreaProtocol.Create(Prot, FAlg, FFrame);
end;

destructor TParcelAreaForm.Destroy;
begin
  FProtocol.Free;
  FAlg.Free;
  FFrame.Free;
  inherited;
end;

procedure TParcelAreaForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(StringGrid1, []);
end;

procedure TParcelAreaForm.FillFromDict(const R: Integer);
var
  num: Int64;
  P: Point.TPoint;
begin
  num := StrToInt64Def(StringGrid1.Cells[StringGrid1.FieldToCol(CB), R], -1);
  if num <= 0 then Exit;

  if LookupPoint(num, P) then
  begin
    StringGrid1.Cells[StringGrid1.FieldToCol(Y), R] := FloatToStr(P.Y, FS);
    StringGrid1.Cells[StringGrid1.FieldToCol(X), R] := FloatToStr(P.X, FS);
  end;
end;

// Fills coordinates from the list; a missing point is offered via AddPoint.
// The first column carries the row number.
procedure TParcelAreaForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
begin
  if ARow < StringGrid1.FixedRows then Exit;

  if ACol = StringGrid1.FieldToCol(CB) then
  begin
    NormalizePointCell(StringGrid1, ACol, ARow);
    FillFromDict(ARow);
  end;

  StringGrid1.Cells[0, ARow] := IntToStr(ARow);
end;

// Every row with a point number is a corner. False, with a message, when
// a corner is not in the list.
function TParcelAreaForm.BuildFrame: Boolean;
var
  R: Integer;
  Num: Int64;
  Row: TGeoRow;
  P: Point.TPoint;
begin
  Result := True;
  FFrame.ClearData;

  for R := StringGrid1.FixedRows to StringGrid1.RowCount - 1 do
  begin
    StringGrid1.GetGeoRow(R, Row);
    Num := StrToInt64Def(Trim(string(Row.CB)), 0);
    if Num <= 0 then
      Continue;

    if not TPointDictionary.GetInstance.PointExists(Num) then
    begin
      ShowMessage(Format('Bod %s není v seznamu souřadnic.',
        [Trim(string(Row.CB))]));
      Result := False;
      Exit;
    end;

    // The list decides, the cells only show it
    P := TPointDictionary.GetInstance.GetPoint(Num);
    Row.Uloha := ULOHA_VYMERA;
    Row.X := P.X;
    Row.Y := P.Y;
    FFrame.AddRow(Row);
  end;
end;

procedure TParcelAreaForm.CalculateClick(Sender: TObject);
begin
  // The frame is the only input, so every run rebuilds it
  if not BuildFrame then
    Exit;
  FAlg.Calculate(FFrame);
  ShowProtocol(Memo1.Lines);

  if IsNan(FAlg.Area) then
    ShowMessage(Trim(FAlg.Warnings.Text));
end;

// Dumps the frame into CSV. The area belongs to the whole job, not to a
// row, so it stays in the protocol.
procedure TParcelAreaForm.SaveClick(Sender: TObject);
var
  FileName: string;
begin
  if not BuildFrame then
    Exit;

  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  FFrame.ToCSV(FileName, ';', ',');

  ShowMessage(Format('Uloženo %d řádků do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]));
end;

// TAreaProtocol writes it
procedure TParcelAreaForm.WriteProtocol(ALines: TStrings);
begin
  FProtocol.Write(ALines);
end;

end.
