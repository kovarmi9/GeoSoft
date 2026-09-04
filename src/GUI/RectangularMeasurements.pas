unit RectangularMeasurements;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Vcl.Menus,
  Types, Math, Point, PointsUtilsSingleton,
  GeoRow, GeoGrid, GeoFieldsGrid, CoordOrderState,
  GeoAlgorithmBase,
  GeoAlgorithmRectangularMeasurements,
  CalcBase;

type
  TRectangularMeasurementsForm = class(TCalcBaseForm)
    StringGrid1: TGeoFieldsGrid;
    Memo1: TMemo;
    PanelCalculate: TPanel;
    ButtonCalculate: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ButtonCalculateClick(Sender: TObject);
  private
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure FillFromDict(const R: Integer);
  protected
    procedure ApplyCoordOrderToGrids; override;
  public
  end;

var
  RectangularMeasurementsForm: TRectangularMeasurementsForm;

implementation

{$R *.dfm}

procedure TRectangularMeasurementsForm.FormCreate(Sender: TObject);
begin
  StringGrid1.SetColumnDisplayName(CB, 'Číslo bodu');
  StringGrid1.SetColumnDisplayName(SH, 'Délka');
  StringGrid1.SetColumnDisplayName(Poznamka, 'Poznámka');

  // OnKeyDown never fires for Enter on TGeoGrid, so use OnCellCommitted
  StringGrid1.OnCellCommitted := PointCommitted;

  Memo1.Lines.Clear;
end;

procedure TRectangularMeasurementsForm.ApplyCoordOrderToGrids;
begin
  ApplyCoordOrder(StringGrid1);
end;

procedure TRectangularMeasurementsForm.FillFromDict(const R: Integer);
var
  Num: Int64;
  P: Point.TPoint;
begin
  Num := StrToInt64Def(StringGrid1.Cells[StringGrid1.FieldToCol(CB), R], -1);
  if Num <= 0 then Exit;

  if LookupPoint(Num, P) then
  begin
    StringGrid1.Cells[StringGrid1.FieldToCol(Y), R] := FloatToStr(P.Y);
    StringGrid1.Cells[StringGrid1.FieldToCol(X), R] := FloatToStr(P.X);
  end;
end;

// Fills coordinates from the list; a missing point is offered via AddPoint.
procedure TRectangularMeasurementsForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
begin
  if (ACol <> StringGrid1.FieldToCol(CB)) or (ARow < StringGrid1.FixedRows) then
    Exit;
  FillFromDict(ARow);
end;

procedure TRectangularMeasurementsForm.ButtonCalculateClick(Sender: TObject);
var
  I, J, N, IdCount, FirstId, LastId: Integer;
  Chain, Identical, ResultPts, LocalPts: TPointsArray;
  IsKnown: array of Boolean;
  MeasDist, CalcDist: Double;
  Alg: TRectangularMeasurementsAlgorithm;
  cCB, cSH, cY, cX: Integer;
begin
  cCB := StringGrid1.FieldToCol(CB);
  cSH := StringGrid1.FieldToCol(SH);
  cY  := StringGrid1.FieldToCol(Y);
  cX  := StringGrid1.FieldToCol(X);

  N := 0;
  IdCount := 0;

  for I := 1 to StringGrid1.RowCount - 1 do
  begin
    if StringGrid1.Cells[cCB, I] = '' then Continue;

    Inc(N);
    SetLength(Chain, N);
    SetLength(IsKnown, N);
    Chain[N - 1].PointNumber := StrToInt64Def(StringGrid1.Cells[cCB, I], 0);
    Chain[N - 1].X := StrToFloatDef(StringGrid1.Cells[cSH, I], 0);
    IsKnown[N - 1] := False;

    if (StringGrid1.Cells[cY, I] <> '') and (StringGrid1.Cells[cX, I] <> '') then
    begin
      IsKnown[N - 1] := True;
      Inc(IdCount);
      SetLength(Identical, IdCount);
      Identical[IdCount - 1].PointNumber := Chain[N - 1].PointNumber;
      Identical[IdCount - 1].Y := StrToFloatDef(StringGrid1.Cells[cY, I], 0);
      Identical[IdCount - 1].X := StrToFloatDef(StringGrid1.Cells[cX, I], 0);
    end;
  end;

  if N < 3 then
  begin
    ShowMessage('Potřeba alespoň 3 body v řetězci.');
    Exit;
  end;

  if IdCount < 2 then
  begin
    ShowMessage('Potřeba alespoň 2 body se známými souřadnicemi.');
    Exit;
  end;

  Alg := TRectangularMeasurementsAlgorithm.Create;
  try
    Alg.IdenticalPoints := Identical;
    try
      ResultPts := Alg.Calculate(Chain);
    except
      on E: Exception do
      begin
        ShowMessage(E.Message);
        Exit;
      end;
    end;

    LocalPts := Alg.LocalPoints;

    N := 0;
    for I := 1 to StringGrid1.RowCount - 1 do
    begin
      if StringGrid1.Cells[cCB, I] = '' then Continue;
      if N >= Length(ResultPts) then Break;
      StringGrid1.Cells[cY, I] := Format('%.2f', [ResultPts[N].Y]);
      StringGrid1.Cells[cX, I] := Format('%.2f', [ResultPts[N].X]);
      Inc(N);
    end;

    // Find first and last identical point indices for distance comparison
    FirstId := -1;
    LastId := -1;
    for I := 0 to High(IsKnown) do
      if IsKnown[I] then
      begin
        if FirstId < 0 then FirstId := I;
        LastId := I;
      end;

    Memo1.Lines.BeginUpdate;
    try
      Memo1.Lines.Clear;
      Memo1.Lines.Add(' == Konstrukční oměrné =====================================================');
      Memo1.Lines.Add(Format(' %-15s  %8s', ['ČÍSLO BODU', 'Délka']));

      for I := 0 to High(ResultPts) do
      begin
        if Chain[I].X <> 0 then
          Memo1.Lines.Add(Format(' %d: %d  %.2f',
            [I + 1, ResultPts[I].PointNumber, Chain[I].X]))
        else
          Memo1.Lines.Add(Format(' %d: %d',
            [I + 1, ResultPts[I].PointNumber]));

        if IsKnown[I] then
        begin
          J := 0;
          while J <= High(Identical) do
          begin
            if Identical[J].PointNumber = ResultPts[I].PointNumber then
            begin
              Memo1.Lines.Add(Format('     YX:  %.2f  %.2f',
                [Identical[J].Y, Identical[J].X]));
              Break;
            end;
            Inc(J);
          end;
        end;
      end;

      Memo1.Lines.Add(' ' + StringOfChar('-', 68));

      // Distance comparison between first and last identical points
      if (FirstId >= 0) and (LastId >= 0) and (FirstId <> LastId) then
      begin
        MeasDist := Sqrt(
          Sqr(LocalPts[LastId].X - LocalPts[FirstId].X) +
          Sqr(LocalPts[LastId].Y - LocalPts[FirstId].Y));
        CalcDist := Sqrt(
          Sqr(Identical[High(Identical)].X - Identical[0].X) +
          Sqr(Identical[High(Identical)].Y - Identical[0].Y));

        Memo1.Lines.Add(Format(' Měřená délka = %.2f  Vypočtená délka = %.2f',
          [MeasDist, CalcDist]));
        Memo1.Lines.Add(Format(' Odch = %.2f', [Abs(CalcDist - MeasDist)]));
        Memo1.Lines.Add(' ' + StringOfChar('-', 68));
      end;

      Memo1.Lines.Add(Format(' Uzávěr = %.3f m',
        [Alg.Closure]));
      Memo1.Lines.Add(' ' + StringOfChar('-', 68));

      for I := 0 to High(ResultPts) do
        if not IsKnown[I] then
          Memo1.Lines.Add(Format(' %d  %.2f  %.2f',
            [ResultPts[I].PointNumber, ResultPts[I].Y, ResultPts[I].X]));

      if Alg.Warnings.Count > 0 then
        for I := 0 to Alg.Warnings.Count - 1 do
          Memo1.Lines.Add(' WARNING: ' + Alg.Warnings[I]);

      Memo1.Lines.Add(' ' + StringOfChar('=', 68));
    finally
      Memo1.Lines.EndUpdate;
    end;
  finally
    Alg.Free;
  end;
end;

end.
