unit GeoAlgorithmRectangularAdjustment;

// Construction distances with adjustment, a closed figure
//   a' = a - D * |a| / sum |a|

interface

uses
  System.SysUtils, Math, Point, GeoAlgorithmBase, GeoAlgorithmTransformBase,
  GeoAlgorithmTransformCongruent, GeoRow, GeoDataFrame;

const
  // Task code from the survey notebook convention
  ULOHA_KONSTRUKCNI_VYROVNANI = 7;

  MIN_ROWS = 5;          // four sides and the closing row

type
  TRectangularAdjustmentAlgorithm = class(TFrameAlgorithm)
  private
    FValid: Boolean;
    FClosureAlong: Double;
    FClosureAcross: Double;
    FAdjusted: TArray<Double>;
    FResiduals: TPointResiduals;
    FMeanError: Double;
  public
    class function TaskCode: Integer; override;

    /// <summary>A given point has coordinates from the list.</summary>
    class function IsGiven(const ARow: TGeoRow): Boolean;

    /// <summary>SH: signed sides, last row closes on the first.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    property Valid: Boolean read FValid;
    /// <summary>Closure along the first side, before the adjustment.</summary>
    property ClosureAlong: Double read FClosureAlong;
    /// <summary>Closure across the first side, + to the right.</summary>
    property ClosureAcross: Double read FClosureAcross;
    /// <summary>Adjusted signed side of each row, NaN in row 0.</summary>
    property Adjusted: TArray<Double> read FAdjusted;
    /// <summary>Residuals of the given points.</summary>
    property Residuals: TPointResiduals read FResiduals;
    /// <summary>Mean error of the key, NaN without redundancy.</summary>
    property MeanError: Double read FMeanError;
  end;

implementation

class function TRectangularAdjustmentAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_KONSTRUKCNI_VYROVNANI;
end;

class function TRectangularAdjustmentAlgorithm.IsGiven(
  const ARow: TGeoRow): Boolean;
begin
  Result := not (IsNan(ARow.X) or IsNan(ARow.Y));
end;

procedure TRectangularAdjustmentAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I, J, N, Count: Integer;
  DirX, DirY, NewDirX, TS: Double;
  FirstDirX, FirstDirY, ClosureX, ClosureY: Double;
  SumX, SumY, Xm, Ym: Double;
  StepX, StepY: TArray<Double>;
  Local, LocalId, GlobalId, Res: TPointsArray;
  Known: Boolean;
  Key: TCongruentTransformation;
begin
  ClearWarnings;
  FValid := False;
  FClosureAlong := NaN;
  FClosureAcross := NaN;
  FMeanError := NaN;
  SetLength(FResiduals, 0);
  N := AFrame.Count;
  SetLength(FAdjusted, N);
  for I := 0 to N - 1 do
    FAdjusted[I] := NaN;

  if N < MIN_ROWS then
  begin
    AddError('Uzavřený obrazec má aspoň čtyři strany.');
    Exit;
  end;
  if AFrame.Rows[N - 1].CB <> AFrame.Rows[0].CB then
  begin
    AddError('Obrazec není uzavřený, poslední bod musí být první bod.');
    Exit;
  end;
  for I := 1 to N - 1 do
    if IsNan(AFrame.Rows[I].SH) or (AFrame.Rows[I].SH = 0) then
    begin
      AddError(Format('Bod %s nemá délku.',
        [Trim(string(AFrame.Rows[I].CB))]));
      Exit;
    end;

  // Walk with right angles, + turns right (S-JTSK axes)
  SetLength(StepX, N);
  SetLength(StepY, N);
  DirX := 1;
  DirY := 0;
  FirstDirX := 0;
  FirstDirY := 0;
  ClosureX := 0;
  ClosureY := 0;
  SumX := 0;
  SumY := 0;
  for I := 1 to N - 1 do
  begin
    TS := Sign(AFrame.Rows[I].SH);
    NewDirX := -TS * DirY;
    DirY := TS * DirX;
    DirX := NewDirX;
    if I = 1 then
    begin
      FirstDirX := DirX;
      FirstDirY := DirY;
    end;
    StepX[I] := Abs(AFrame.Rows[I].SH) * Scale * DirX;
    StepY[I] := Abs(AFrame.Rows[I].SH) * Scale * DirY;
    ClosureX := ClosureX + StepX[I];
    ClosureY := ClosureY + StepY[I];
    SumX := SumX + Abs(StepX[I]);
    SumY := SumY + Abs(StepY[I]);
  end;
  if (SumX = 0) or (SumY = 0) then
  begin
    AddError('Všechny strany leží v jedné přímce.');
    Exit;
  end;

  // As the surveyor sees it, right of the first side is + across
  FClosureAlong := ClosureX * FirstDirX + ClosureY * FirstDirY;
  FClosureAcross := -ClosureX * FirstDirY + ClosureY * FirstDirX;

  // Closure split in proportion to the sides of each axis
  SetLength(Local, N);
  Xm := 0;
  Ym := 0;
  for I := 0 to N - 1 do
  begin
    if I > 0 then
    begin
      StepX[I] := StepX[I] - ClosureX * Abs(StepX[I]) / SumX;
      StepY[I] := StepY[I] - ClosureY * Abs(StepY[I]) / SumY;
      Xm := Xm + StepX[I];
      Ym := Ym + StepY[I];
      FAdjusted[I] := Sign(AFrame.Rows[I].SH) *
        (Abs(StepX[I]) + Abs(StepY[I]));
    end;
    AFrame.Rows[I].Xm := Xm;
    AFrame.Rows[I].Ym := Ym;
    Local[I].PointNumber := StrToInt64Def(Trim(string(AFrame.Rows[I].CB)), 0);
    Local[I].X := Xm;
    Local[I].Y := Ym;
  end;

  // Every given point once, the closing row repeats the first
  Count := 0;
  for I := 0 to N - 2 do
  begin
    if not IsGiven(AFrame.Rows[I]) then
      Continue;
    Known := False;
    for J := 0 to Count - 1 do
      if GlobalId[J].PointNumber = Local[I].PointNumber then
        Known := True;
    if Known then
      Continue;
    Inc(Count);
    SetLength(LocalId, Count);
    SetLength(GlobalId, Count);
    LocalId[Count - 1] := Local[I];
    GlobalId[Count - 1] := Local[I];
    GlobalId[Count - 1].X := AFrame.Rows[I].X;
    GlobalId[Count - 1].Y := AFrame.Rows[I].Y;
  end;
  if Count < 2 then
  begin
    AddError('Jsou potřeba aspoň dva dané body, jeden obrazec nenatočí.');
    Exit;
  end;

  Key := TCongruentTransformation.Create;
  try
    try
      Key.ComputeParametersFromPoints(LocalId, GlobalId);
    except
      on E: Exception do
      begin
        AddError(E.Message);
        Exit;
      end;
    end;
    Res := Key.Calculate(Local);
    FResiduals := Key.Residuals;
    // Shifts and rotation
    if 2 * Count - 3 > 0 then
      FMeanError := Sqrt(Key.SumVV / (2 * Count - 3));
  finally
    Key.Free;
  end;

  // Given points keep their own coordinates
  for I := 0 to N - 1 do
    if not IsGiven(AFrame.Rows[I]) then
    begin
      AFrame.Rows[I].X := Res[I].X;
      AFrame.Rows[I].Y := Res[I].Y;
    end;

  FValid := True;
end;

end.
