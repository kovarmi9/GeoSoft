unit RectangularMeasurements;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Vcl.Menus,
  Types, Math, Point, PointsUtilsSingleton, PointPrefixState,
  GeoRow, GeoDataFrame, GeoGridBridge, GeoGrid, GeoFieldsGrid, CoordOrderState,
  GeoFieldsDef, ProtocolTable,
  GeoAlgorithmBase,
  GeoAlgorithmRectangularMeasurements,
  CalcBase, Vcl.Mask;

type
  // One point of the chain, as the protocol shows it
  TChainLine = record
    Num:     Int64;
    Dist:    Double;        // measured length to the next point
    HasDist: Boolean;
    Pt:      Point.TPoint;  // given coordinates, or computed ones
    Known:   Boolean;       // True = given point
  end;

  // One item of the chain, as the grid holds it
  TChainItem = record
    Row:   Integer;         // grid row
    Num:   Int64;
    Dist:  Double;          // signed length from the previous point
    Known: Boolean;         // found in the point list
    Pt:    Point.TPoint;    // given coordinates of a known point
  end;

  // One computed stretch between two known points
  TChainSegment = record
    Lines:    array of TChainLine;
    Closure:  Double;
    MeasDist: Double;       // from the local walk
    CalcDist: Double;       // from the given coordinates
  end;

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
    FChain: array of TChainItem;
    FSegments: array of TChainSegment;
    FWarnings: TStringList;         // collected from all stretches
    FRowNew: array of Boolean;      // listed point the user calls new
    FRowCB: array of string;        // last point number per row
    procedure CellCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure SetCell(F: TGeoField; ARow: Integer; const S: string);
    procedure FillRow(const R: Integer);
    procedure RecalcLocal;
    procedure CollectChain;
    procedure ComputeSegment(AFrom, ATo: Integer);
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
end;

destructor TRectangularMeasurementsForm.Destroy;
begin
  FAlg.Free;
  FWarnings.Free;
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
    SetCell(Y, R, FloatToStr(P.Y));
    SetCell(X, R, FloatToStr(P.X));
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
var
  I, N, cCB, cSH: Integer;
  Chain, Local: TPointsArray;
  Rows: array of Integer;
begin
  if StringGrid1.FieldToCol(Xm) < 0 then
    Exit;

  cCB := StringGrid1.FieldToCol(CB);
  cSH := StringGrid1.FieldToCol(SH);

  N := 0;
  for I := StringGrid1.FixedRows to StringGrid1.RowCount - 1 do
  begin
    if Trim(StringGrid1.Cells[cCB, I]) = '' then Continue;
    Inc(N);
    SetLength(Chain, N);
    SetLength(Rows, N);
    Chain[N - 1].PointNumber := StrToInt64Def(StringGrid1.Cells[cCB, I], 0);
    Chain[N - 1].X := StrToFloatDef(StringGrid1.Cells[cSH, I], 0);
    Rows[N - 1] := I;
  end;

  if N = 0 then Exit;

  FAlg.BuildLocalPoints(Chain);
  Local := FAlg.LocalPoints;

  for I := 0 to High(Local) do
  begin
    SetCell(Xm, Rows[I], FormatFloat('0.00', Local[I].X, FS));
    SetCell(Ym, Rows[I], FormatFloat('0.00', Local[I].Y, FS));
  end;
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

// Reads the grid rows into FChain
procedure TRectangularMeasurementsForm.CollectChain;
var
  I, N, cCB, cSH: Integer;
begin
  SetLength(FChain, 0);
  cCB := StringGrid1.FieldToCol(CB);
  cSH := StringGrid1.FieldToCol(SH);
  N := 0;

  for I := StringGrid1.FixedRows to StringGrid1.RowCount - 1 do
  begin
    if Trim(StringGrid1.Cells[cCB, I]) = '' then Continue;

    Inc(N);
    SetLength(FChain, N);
    FChain[N - 1].Row   := I;
    FChain[N - 1].Num   := StrToInt64Def(StringGrid1.Cells[cCB, I], 0);
    FChain[N - 1].Dist  := StrToFloatDef(StringGrid1.Cells[cSH, I], 0);
    FChain[N - 1].Known := TPointDictionary.GetInstance.PointExists(FChain[N - 1].Num);

    // The user said this listed point is a new one
    if FChain[N - 1].Known and (I <= High(FRowNew)) and FRowNew[I] then
    begin
      FChain[N - 1].Known := False;
      FWarnings.Add(Format('Bod %s je v seznamu, ale počítá se jako nový.',
        [PointId(FChain[N - 1].Num)]));
    end;

    // Coordinates of a known point always come from the list
    if FChain[N - 1].Known then
      FChain[N - 1].Pt := TPointDictionary.GetInstance.GetPoint(FChain[N - 1].Num);
  end;
end;

// Computes one stretch between two different known points
procedure TRectangularMeasurementsForm.ComputeSegment(AFrom, ATo: Integer);
var
  I, N: Integer;
  Chain, Ident, Res, Loc: TPointsArray;
  Seg: TChainSegment;
  Head: string;
begin
  N := ATo - AFrom + 1;
  if N < 3 then Exit;            // two known points side by side

  Head := Format('Úsek %s–%s: ',
    [PointId(FChain[AFrom].Num), PointId(FChain[ATo].Num)]);

  SetLength(Chain, N);
  for I := 0 to N - 1 do
  begin
    Chain[I].PointNumber := FChain[AFrom + I].Num;
    if I = 0 then
      Chain[I].X := 0            // the walk starts here
    else
    begin
      Chain[I].X := FChain[AFrom + I].Dist;
      if Chain[I].X = 0 then
        FWarnings.Add(Head + Format('bod %s nemá délku.',
          [PointId(FChain[AFrom + I].Num)]));
    end;
  end;

  SetLength(Ident, 2);
  Ident[0] := FChain[AFrom].Pt;
  Ident[1] := FChain[ATo].Pt;

  FAlg.IdenticalPoints := Ident;
  try
    Res := FAlg.Calculate(Chain);
  except
    on E: Exception do
    begin
      FWarnings.Add(Head + E.Message);
      Exit;
    end;
  end;

  for I := 0 to FAlg.Warnings.Count - 1 do
    FWarnings.Add(Head + FAlg.Warnings[I]);

  Loc := FAlg.LocalPoints;
  Seg.Closure  := FAlg.Closure;
  Seg.MeasDist := Sqrt(Sqr(Loc[N - 1].X - Loc[0].X) + Sqr(Loc[N - 1].Y - Loc[0].Y));
  Seg.CalcDist := Sqrt(Sqr(Ident[1].X - Ident[0].X) + Sqr(Ident[1].Y - Ident[0].Y));

  SetLength(Seg.Lines, N);
  for I := 0 to N - 1 do
  begin
    Seg.Lines[I].Num     := FChain[AFrom + I].Num;
    Seg.Lines[I].Dist    := Chain[I].X;
    Seg.Lines[I].HasDist := I > 0;
    Seg.Lines[I].Known   := FChain[AFrom + I].Known;

    if FChain[AFrom + I].Known then
      Seg.Lines[I].Pt := FChain[AFrom + I].Pt
    else
    begin
      Seg.Lines[I].Pt := Res[I];
      SetCell(Y, FChain[AFrom + I].Row, FormatFloat('0.00', Res[I].Y, FS));
      SetCell(X, FChain[AFrom + I].Row, FormatFloat('0.00', Res[I].X, FS));
    end;
  end;

  SetLength(FSegments, Length(FSegments) + 1);
  FSegments[High(FSegments)] := Seg;
end;

procedure TRectangularMeasurementsForm.ButtonCalculateClick(Sender: TObject);
var
  I, First: Integer;
begin
  FWarnings.Clear;
  CollectChain;
  SetLength(FSegments, 0);

  if Length(FChain) = 0 then
  begin
    ShowMessage('Zápisník je prázdný.');
    Exit;
  end;

  if not FChain[0].Known then
  begin
    ShowMessage('První bod řetězce musí být známý.');
    Exit;
  end;

  // Old results would look valid if a stretch fails now
  for I := 0 to High(FChain) do
    if not FChain[I].Known then
    begin
      SetCell(Y, FChain[I].Row, '');
      SetCell(X, FChain[I].Row, '');
    end;

  First := 0;
  for I := 1 to High(FChain) do
    // Coming back to the same point closes nothing - rotation needs two points
    if FChain[I].Known and (FChain[I].Num <> FChain[First].Num) then
    begin
      ComputeSegment(First, I);
      First := I;
    end;

  if Length(FSegments) = 0 then
  begin
    ShowMessage('V řetězci zatím není druhý známý bod s jiným číslem.');
    Exit;
  end;

  if First < High(FChain) then
    FWarnings.Add(Format('Za bodem %s už není známý bod, %d bodů zůstalo nespočítaných.',
      [PointId(FChain[First].Num), High(FChain) - First]));

  ShowProtocol(Memo1.Lines);
end;

const
  ULOHA_KONSTR_OMERNE = 4;                        // task code
  CSV_NAME            = 'konstrukcni_omerne.csv'; // saved next to exe

// Dumps the grid through a data frame into CSV
procedure TRectangularMeasurementsForm.ButtonSaveClick(Sender: TObject);
var
  DF: TGeoDataFrame;
  FileName: string;
begin
  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;

  DF := TGeoDataFrame.Create([Uloha, CB, X, Y, Xm, Ym, SH, Poznamka, KK]);
  try
    GridToFrame(StringGrid1, DF, ULOHA_KONSTR_OMERNE);

    if DF.Count = 0 then
    begin
      ShowMessage('Zápisník je prázdný, nic se neuložilo.');
      Exit;
    end;

    DF.ToCSV(FileName, ';', ',');
    ShowMessage(Format('Uloženo %d řádků do souboru%s%s', [DF.Count, sLineBreak, FileName]));
  finally
    DF.Free;
  end;
end;

procedure TRectangularMeasurementsForm.WriteProtocol(ALines: TStrings);
var
  S, I: Integer;
  Seg: TChainSegment;
  Kind, Dist: string;
begin
  Prot.Title(ALines, 'Konstrukční oměrné');

  for S := 0 to High(FSegments) do
  begin
    Seg := FSegments[S];

    Prot.Text(Format('Úsek %d: %s → %s', [S + 1,
      PointId(Seg.Lines[0].Num), PointId(Seg.Lines[High(Seg.Lines)].Num)]));

    Prot.Table(['Č.', 'Číslo bodu', 'Délka', CoordNames, 'Typ'],
               [ColWNo, ColWPoint, ColWDist, ColWPair, ColWFlag]);

    for I := 0 to High(Seg.Lines) do
    begin
      if Seg.Lines[I].Known then
        Kind := 'daný'
      else
        Kind := 'vypočtený';

      // the first point of a stretch has no length in front of it
      if Seg.Lines[I].HasDist then
        Dist := Num(Seg.Lines[I].Dist)
      else
        Dist := '';

      Prot.Row([IntToStr(I + 1), PointId(Seg.Lines[I].Num), Dist,
                CoordPair(Seg.Lines[I].Pt), Kind]);
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
