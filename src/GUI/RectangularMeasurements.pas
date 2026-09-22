unit RectangularMeasurements;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Vcl.Menus,
  Types, Math, Point, PointsUtilsSingleton, PointPrefixState,
  GeoRow, GeoDataFrame, GeoGridBridge, GeoGrid, GeoFieldsGrid, CoordOrderState,
  GeoFieldsDef, ProtocolTable,
  GeoAlgorithmBase,
  GeoAlgorithmRectangularMeasurements,
  CalcBase, Vcl.Mask;

type
  TRectangularMeasurementsForm = class(TCalcBaseForm)
    StringGrid1: TGeoFieldsGrid;
    Memo1: TMemo;
    PanelCalculate: TPanel;
    ButtonCalculate: TButton;
    ButtonSave: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ButtonCalculateClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
  private
    FAlg: TRectangularMeasurementsAlgorithm;
    FFrame: TGeoDataFrame;          // the input and the output of the run
    FRows: TArray<Integer>;         // grid row of each frame row
    FWarnings: TStringList;         // collected from all stretches
    FRowNew: array of Boolean;      // listed point the user calls new
    FRowCB: array of string;        // last point number per row
    procedure CellCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure SetCell(F: TGeoField; ARow: Integer; const S: string);
    procedure FillRow(const R: Integer);
    procedure RecalcLocal;
    procedure BuildFrame;
  protected
    procedure ApplyCoordOrderToGrids; override;
    procedure WriteProtocol(ALines: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  RectangularMeasurementsForm: TRectangularMeasurementsForm;

implementation

{$R *.dfm}

constructor TRectangularMeasurementsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TRectangularMeasurementsAlgorithm.Create;
  FWarnings := TStringList.Create;
  FFrame := TGeoDataFrame.Create([Uloha, CB, X, Y, Xm, Ym, SH, Poznamka, KK]);
end;

destructor TRectangularMeasurementsForm.Destroy;
begin
  FAlg.Free;
  FWarnings.Free;
  FFrame.Free;
  inherited;
end;

procedure TRectangularMeasurementsForm.FormCreate(Sender: TObject);
var
  D: TColumnFilterData;
begin
  StringGrid1.SetColumnDisplayName(CB, 'Číslo bodu');
  StringGrid1.SetColumnDisplayName(SH, 'Délka');
  StringGrid1.SetColumnDisplayName(Xm, 'X místní');
  StringGrid1.SetColumnDisplayName(Ym, 'Y místní');
  StringGrid1.SetColumnDisplayName(KK, 'Kód kvality');
  StringGrid1.SetColumnDisplayName(Poznamka, 'Poznámka');

  // Left turn is written as a negative length
  D := GeoFieldColumns[SH].Filter;
  D.HasMinValue := False;
  StringGrid1.SetColumnFilterData(SH, D);

  // OnKeyDown never fires for Enter on TGeoGrid, so use OnCellCommitted
  StringGrid1.OnCellCommitted := CellCommitted;

  Memo1.Lines.Clear;
end;

const
  // Column order, both coordinate pairs follow the toolbar switch
  ORDER_YX: array[0..7] of TGeoField = (CB, SH, Ym, Xm, Y, X, KK, Poznamka);
  ORDER_XY: array[0..7] of TGeoField = (CB, SH, Xm, Ym, X, Y, KK, Poznamka);

procedure TRectangularMeasurementsForm.ApplyCoordOrderToGrids;
begin
  ApplyCoordOrder(StringGrid1, ORDER_YX, ORDER_XY);
end;

// Writes one value by field, when the grid shows it
procedure TRectangularMeasurementsForm.SetCell(F: TGeoField; ARow: Integer;
  const S: string);
var
  C: Integer;
begin
  C := StringGrid1.FieldToCol(F);
  if C >= 0 then
    StringGrid1.Cells[C, ARow] := S;
end;

// Fills the row after its point number was committed
procedure TRectangularMeasurementsForm.FillRow(const R: Integer);
var
  Num: Int64;
  P: Point.TPoint;
  CBText: string;
  Known: Boolean;
begin
  CBText := Trim(StringGrid1.Cells[StringGrid1.FieldToCol(CB), R]);
  Num := StrToInt64Def(CBText, -1);
  if Num <= 0 then Exit;

  // Only a new number refills the row, so user edits survive
  if Length(FRowCB) <= R then
    SetLength(FRowCB, R + 1);
  if Length(FRowNew) <= R then
    SetLength(FRowNew, R + 1);
  if CBText = FRowCB[R] then Exit;

  FRowNew[R] := False;

  if R = StringGrid1.FixedRows then
  begin
    // The chain has to start on a known point
    Known := LookupPoint(Num, P);
    if not Known then
    begin
      StringGrid1.RejectCommit;
      FRowCB[R] := '';
      Exit;
    end;
  end
  else
  begin
    Known := TPointDictionary.GetInstance.PointExists(Num);
    if Known then
    begin
      // Report the duplicate and let the user choose, the same as GEUS
      if MessageDlg(Format('Bod %s už je v seznamu souřadnic.' + sLineBreak +
           'Použít jeho souřadnice? (Ne = počítat ho jako nový)', [PointId(Num)]),
           mtConfirmation, [mbYes, mbNo], 0) = mrNo then
      begin
        Known := False;
        FRowNew[R] := True;
      end
      else
        P := TPointDictionary.GetInstance.GetPoint(Num);
    end;
  end;

  FRowCB[R] := CBText;

  if Known then
  begin
    SetCell(Y, R, FormatFloat('0.00', P.Y, FS));
    SetCell(X, R, FormatFloat('0.00', P.X, FS));
    SetCell(KK, R, IntToStr(P.Quality));
    SetCell(Poznamka, R, string(P.Description));
  end
  else
  begin
    SetCell(KK, R, GPointPrefix.KK);
    SetCell(Poznamka, R, GPointPrefix.Popis);
  end;
end;

// Walks the chain again and refreshes the local coordinates
procedure TRectangularMeasurementsForm.RecalcLocal;
begin
  if StringGrid1.FieldToCol(Xm) < 0 then
    Exit;

  // The walk needs no point list, so the plain bridge is enough
  GridToFrame(StringGrid1, FFrame, ULOHA_DET, FRows);
  FAlg.BuildLocalFrame(FFrame);
  FrameToGrid(StringGrid1, FFrame, FRows, [Xm, Ym]);
end;

// Normalizes the number and refills the row
procedure TRectangularMeasurementsForm.CellCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if ARow < StringGrid1.FixedRows then
    Exit;

  if ACol = StringGrid1.FieldToCol(CB) then
  begin
    NormalizePointCell(StringGrid1, ACol, ARow);
    FillRow(ARow);
  end;

  // The walk is cumulative, so any change redraws all rows
  if (ACol = StringGrid1.FieldToCol(CB)) or (ACol = StringGrid1.FieldToCol(SH)) then
    RecalcLocal;
end;

// Fills the frame from the grid and marks the given points
procedure TRectangularMeasurementsForm.BuildFrame;
var
  I, GridRow: Integer;
  Num: Int64;
  P: Point.TPoint;
  IsGiven: Boolean;
begin
  GridToFrame(StringGrid1, FFrame, ULOHA_DET, FRows);

  for I := 0 to FFrame.Count - 1 do
  begin
    GridRow := FRows[I];
    Num := StrToInt64Def(string(FFrame.Rows[I].CB), 0);

    // A listed point is given, unless the user said it is a new one
    IsGiven := TPointDictionary.GetInstance.PointExists(Num)
      and not ((GridRow <= High(FRowNew)) and FRowNew[GridRow]);

    if IsGiven then
    begin
      FFrame.Rows[I].Uloha := ULOHA_IDENT;

      // The list decides, the cell can be edited
      P := TPointDictionary.GetInstance.GetPoint(Num);
      FFrame.Rows[I].X := P.X;
      FFrame.Rows[I].Y := P.Y;
      SetCell(Y, GridRow, FormatFloat('0.00', P.Y, FS));
      SetCell(X, GridRow, FormatFloat('0.00', P.X, FS));
    end;
  end;
end;

procedure TRectangularMeasurementsForm.ButtonCalculateClick(Sender: TObject);
var
  I, S: Integer;
  Back: TArray<Integer>;
begin
  FWarnings.Clear;
  Memo1.Lines.Clear;
  BuildFrame;

  if FFrame.Count = 0 then
  begin
    ShowMessage('Zápisník je prázdný.');
    Exit;
  end;

  if FFrame.Rows[0].Uloha <> ULOHA_IDENT then
  begin
    ShowMessage('První bod řetězce musí být známý.');
    Exit;
  end;

  for I := 0 to FFrame.Count - 1 do
    if FFrame.Rows[I].Uloha = ULOHA_DET then
    begin
      // Old results would look valid if a stretch fails now
      SetCell(Y, FRows[I], '');
      SetCell(X, FRows[I], '');

      if TPointDictionary.GetInstance.PointExists(
           StrToInt64Def(string(FFrame.Rows[I].CB), 0)) then
        FWarnings.Add(Format('Bod %s je v seznamu, ale počítá se jako nový.',
          [FormatPointId(string(FFrame.Rows[I].CB))]));
    end;

  FAlg.CalculateFrame(FFrame);
  FWarnings.AddStrings(FAlg.Warnings);

  if Length(FAlg.Segments) = 0 then
  begin
    ShowMessage('V řetězci zatím není druhý známý bod s jiným číslem.');
    Exit;
  end;

  // Only computed points of a finished stretch go back to the grid
  SetLength(Back, FFrame.Count);
  for I := 0 to High(Back) do
    Back[I] := -1;
  for S := 0 to High(FAlg.Segments) do
    for I := FAlg.Segments[S].FromRow to FAlg.Segments[S].ToRow do
      if FFrame.Rows[I].Uloha = ULOHA_DET then
        Back[I] := FRows[I];

  FrameToGrid(StringGrid1, FFrame, Back, [X, Y]);
  ShowProtocol(Memo1.Lines);
end;

const
  CSV_NAME = 'konstrukcni_omerne.csv';   // saved next to exe

// Dumps the frame into CSV
procedure TRectangularMeasurementsForm.ButtonSaveClick(Sender: TObject);
var
  FileName: string;
begin
  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  BuildFrame;

  if FFrame.Count = 0 then
  begin
    ShowMessage('Zápisník je prázdný, nic se neuložilo.');
    Exit;
  end;

  FFrame.ToCSV(FileName, ';', ',');
  ShowMessage(Format('Uloženo %d řádků do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]));
end;

procedure TRectangularMeasurementsForm.WriteProtocol(ALines: TStrings);
var
  S, I: Integer;
  Seg: TSegmentInfo;
  Row: TGeoRow;
  Pt: Point.TPoint;
  Kind, Dist: string;
begin
  Prot.Title(ALines, 'Konstrukční oměrné');

  for S := 0 to High(FAlg.Segments) do
  begin
    Seg := FAlg.Segments[S];

    Prot.Text(Format('Úsek %d: %s → %s', [S + 1,
      FormatPointId(string(FFrame.Rows[Seg.FromRow].CB)),
      FormatPointId(string(FFrame.Rows[Seg.ToRow].CB))]));

    Prot.Table(['Č.', 'Číslo bodu', 'Délka', CoordNames, 'Typ'],
               [ColWNo, ColWPoint, ColWDist, ColWPair, ColWFlag]);

    for I := Seg.FromRow to Seg.ToRow do
    begin
      Row := FFrame.Rows[I];

      if Row.Uloha = ULOHA_IDENT then
        Kind := 'daný'
      else
        Kind := 'vypočtený';

      // the first point of a stretch has no length in front of it
      if I = Seg.FromRow then
        Dist := ''
      else
        Dist := Num(Row.SH);

      Pt.X := Row.X;
      Pt.Y := Row.Y;

      Prot.Row([IntToStr(I - Seg.FromRow + 1), FormatPointId(string(Row.CB)),
                Dist, CoordPair(Pt), Kind]);
    end;

    Prot.Text('');
    Prot.Text('Měřená délka = ' + Num(Seg.MeasDist) +
              '    Vypočtená délka = ' + Num(Seg.CalcDist));
    Prot.Text('Odchylka = ' + Num(Abs(Seg.CalcDist - Seg.MeasDist)));
    Prot.Text('Uzávěr = ' + Num(Seg.Closure, 3) + ' m');
    Prot.Text('');
  end;

  Prot.Finish(FWarnings);
end;

end.
