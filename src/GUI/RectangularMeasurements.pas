unit RectangularMeasurements;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Vcl.Menus,
  Types, Math, Point, PointsUtilsSingleton,
  GeoAlgorithmBase,
  GeoAlgorithmRectangularMeasurements,
  CalcBase;

type
  TRectangularMeasurementsForm = class(TCalcBaseForm)
    StringGrid1: TStringGrid;
    Memo1: TMemo;
    PanelCalculate: TPanel;
    ButtonCalculate: TButton;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure ButtonCalculateClick(Sender: TObject);
  private
    procedure MoveToNextCell;
    procedure FillFromDict(const R: Integer);
  public
  end;

var
  RectangularMeasurementsForm: TRectangularMeasurementsForm;

implementation

{$R *.dfm}

procedure TRectangularMeasurementsForm.FormCreate(Sender: TObject);
begin
  StringGrid1.ColCount := 5;
  StringGrid1.RowCount := 5;
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  StringGrid1.Cells[0, 0] := 'Č.';
  StringGrid1.Cells[1, 0] := 'Číslo bodu';
  StringGrid1.Cells[2, 0] := 'Délka';
  StringGrid1.Cells[3, 0] := 'Y';
  StringGrid1.Cells[4, 0] := 'X';

  StringGrid1.Cells[0, 1] := '1';
  StringGrid1.Cells[0, 2] := '2';
  StringGrid1.Cells[0, 3] := '3';
  StringGrid1.Cells[0, 4] := '4';

  StringGrid1.ColWidths[0] := 30;
  StringGrid1.ColWidths[1] := 90;
  StringGrid1.ColWidths[2] := 90;
  StringGrid1.ColWidths[3] := 120;
  StringGrid1.ColWidths[4] := 120;

  StringGrid1.OnKeyDown := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  Memo1.Lines.Clear;
end;

procedure TRectangularMeasurementsForm.MoveToNextCell;
begin
  if StringGrid1.Col < StringGrid1.ColCount - 1 then
    StringGrid1.Col := StringGrid1.Col + 1
  else
  begin
    if StringGrid1.Row = StringGrid1.RowCount - 1 then
      StringGrid1.RowCount := StringGrid1.RowCount + 1;
    StringGrid1.Row := StringGrid1.Row + 1;
    StringGrid1.Col := 1;
    StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row);
  end;
end;

procedure TRectangularMeasurementsForm.FillFromDict(const R: Integer);
var
  Num: Integer;
  P: Point.TPoint;
begin
  Num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if Num <= 0 then Exit;

  if LookupPoint(Num, P) then
  begin
    StringGrid1.Cells[3, R] := FloatToStr(P.Y);
    StringGrid1.Cells[4, R] := FloatToStr(P.X);
  end;
end;

procedure TRectangularMeasurementsForm.StringGrid1DrawCell(Sender: TObject;
  ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  Text: string;
  TextW, X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace;
      Font.Style := [fsBold];
      FillRect(Rect);
      Text := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(Text);
      X := Rect.Left + (Rect.Width - TextW) div 2;
      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      Brush.Color := clWindow;
      Font.Style := [];
      FillRect(Rect);
      Text := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;
end;

procedure TRectangularMeasurementsForm.StringGrid1KeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  if StringGrid1.Col = 1 then
    FillFromDict(StringGrid1.Row);

  MoveToNextCell;
end;

procedure TRectangularMeasurementsForm.ButtonCalculateClick(Sender: TObject);
var
  I, J, N, IdCount, FirstId, LastId: Integer;
  Chain, Identical, ResultPts, LocalPts: TPointsArray;
  IsKnown: array of Boolean;
  MeasDist, CalcDist: Double;
begin
  N := 0;
  IdCount := 0;

  for I := 1 to StringGrid1.RowCount - 1 do
  begin
    if StringGrid1.Cells[1, I] = '' then Continue;

    Inc(N);
    SetLength(Chain, N);
    SetLength(IsKnown, N);
    Chain[N - 1].PointNumber := StrToIntDef(StringGrid1.Cells[1, I], 0);
    Chain[N - 1].X := StrToFloatDef(StringGrid1.Cells[2, I], 0);
    IsKnown[N - 1] := False;

    if (StringGrid1.Cells[3, I] <> '') and (StringGrid1.Cells[4, I] <> '') then
    begin
      IsKnown[N - 1] := True;
      Inc(IdCount);
      SetLength(Identical, IdCount);
      Identical[IdCount - 1].PointNumber := Chain[N - 1].PointNumber;
      Identical[IdCount - 1].Y := StrToFloatDef(StringGrid1.Cells[3, I], 0);
      Identical[IdCount - 1].X := StrToFloatDef(StringGrid1.Cells[4, I], 0);
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

  TRectangularMeasurementsAlgorithm.IdenticalPoints := Identical;
  try
    ResultPts := TRectangularMeasurementsAlgorithm.Calculate(Chain);
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;

  LocalPts := TRectangularMeasurementsAlgorithm.LocalPoints;

  N := 0;
  for I := 1 to StringGrid1.RowCount - 1 do
  begin
    if StringGrid1.Cells[1, I] = '' then Continue;
    if N >= Length(ResultPts) then Break;
    StringGrid1.Cells[3, I] := Format('%.2f', [ResultPts[N].Y]);
    StringGrid1.Cells[4, I] := Format('%.2f', [ResultPts[N].X]);
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
      [TRectangularMeasurementsAlgorithm.Closure]));
    Memo1.Lines.Add(' ' + StringOfChar('-', 68));

    for I := 0 to High(ResultPts) do
      if not IsKnown[I] then
        Memo1.Lines.Add(Format(' %d  %.2f  %.2f',
          [ResultPts[I].PointNumber, ResultPts[I].Y, ResultPts[I].X]));

    if TRectangularMeasurementsAlgorithm.Warnings.Count > 0 then
      for I := 0 to TRectangularMeasurementsAlgorithm.Warnings.Count - 1 do
        Memo1.Lines.Add(' WARNING: ' + TRectangularMeasurementsAlgorithm.Warnings[I]);

    Memo1.Lines.Add(' ' + StringOfChar('=', 68));
  finally
    Memo1.Lines.EndUpdate;
  end;
end;

end.
