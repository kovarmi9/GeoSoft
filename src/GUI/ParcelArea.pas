unit ParcelArea;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Types,
  PointsUtilsSingleton, PointPrefixState,
  Point,
  CoordOrderState, ProtocolTable,
  GeoRow, GeoGrid, GeoFieldsGrid,
  GeoAlgorithmBase,
  GeoAlgorithmLHuilier,
  CalcBase, Vcl.Menus;

type
  TParcelAreaForm = class(TCalcBaseForm)
    StringGrid1: TGeoFieldsGrid;
    Memo1: TMemo;
    PanelCalculate: TPanel;
    Calculate: TButton;
    procedure FormCreate(Sender: TObject);
    procedure CalculateClick(Sender: TObject);
  private
    FAlg: TLHuilierAlgorithm;
    FPts: TPointsArray;          // polygon corners, in grid order
    FNums: array of string;      // point number of every corner
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure FillFromDict(const R: Integer);
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

constructor TParcelAreaForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TLHuilierAlgorithm.Create;
end;

destructor TParcelAreaForm.Destroy;
begin
  FAlg.Free;
  inherited;
end;

procedure TParcelAreaForm.FormCreate(Sender: TObject);
begin
  StringGrid1.SetColumnDisplayName(CB, 'Číslo bodu');

  // OnKeyDown never fires for Enter on TGeoGrid, so use OnCellCommitted
  StringGrid1.OnCellCommitted := PointCommitted;

  Memo1.Lines.Clear;
end;

procedure TParcelAreaForm.ApplyCoordOrderToGrids;
begin
  ApplyCoordOrder(StringGrid1);
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
    StringGrid1.Cells[StringGrid1.FieldToCol(Y), R] := FloatToStr(P.Y);
    StringGrid1.Cells[StringGrid1.FieldToCol(X), R] := FloatToStr(P.X);
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

procedure TParcelAreaForm.CalculateClick(Sender: TObject);
var
  i, n, cCB, cY, cX: Integer;
begin
  cCB := StringGrid1.FieldToCol(CB);
  cY  := StringGrid1.FieldToCol(Y);
  cX  := StringGrid1.FieldToCol(X);

  n := 0;
  SetLength(FPts, 0);
  SetLength(FNums, 0);

  for i := 1 to StringGrid1.RowCount - 1 do
  begin
    if (StringGrid1.Cells[cY, i] = '') or (StringGrid1.Cells[cX, i] = '') then
      Continue;
    Inc(n);
    SetLength(FPts, n);
    SetLength(FNums, n);
    FPts[n-1].Y := StrToFloatDef(StringGrid1.Cells[cY, i], 0);
    FPts[n-1].X := StrToFloatDef(StringGrid1.Cells[cX, i], 0);
    FNums[n-1] := StringGrid1.Cells[cCB, i];
  end;

  if n < 3 then
  begin
    ShowMessage('Pro výpočet plochy jsou potřeba alespoň 3 body.');
    Exit;
  end;

  FAlg.Calculate(FPts);
  ShowProtocol(Memo1.Lines);
end;

procedure TParcelAreaForm.WriteProtocol(ALines: TStrings);
var
  i: Integer;
begin
  Prot.Title(ALines, 'Výpočet plochy parcely');

  Prot.Table(['Č.', 'Číslo bodu', CoordNames],
             [ColWNo, ColWPoint, ColWPair]);
  for i := 0 to High(FPts) do
    Prot.Row([IntToStr(i + 1), FormatPointId(FNums[i]), CoordPair(FPts[i])]);

  Prot.Text('');
  Prot.Text('Plocha = ' + Num(FAlg.Area) + ' m²');
  Prot.Finish(FAlg.Warnings);
end;

end.
