unit GeoAlgorithmRectangularMeasurements;

// Construction distances, a congruent key per stretch

interface

uses
  System.SysUtils, System.Classes, Math, GeoAlgorithmBase,
  GeoAlgorithmTransformCongruent, Point, GeoRow, GeoDataFrame,
  ValidationUtils;

const
  // Task code from the survey notebook convention
  ULOHA_KONSTRUKCNI = 4;

  // Older technology rules, points between the two given ones
  MAX_INTERMEDIATE = 8;

type
  // One computed stretch, rows are indexes into the frame
  TSegmentInfo = record
    FromRow, ToRow: Integer;
    Closure:  Double;
    MeasDist: Double;   // from the local walk
    CalcDist: Double;   // from the given coordinates
    Limit:    Double;   // ud of the difference, NaN without quality
  end;

  TSegmentArray = array of TSegmentInfo;

  TRectangularMeasurementsAlgorithm = class(TFrameAlgorithm)
  private
    FIdenticalPoints: TPointsArray;
    FLocalPoints: TPointsArray;
    FClosure: Double;
    FSegments: TSegmentArray;

    procedure ComputeStretch(AFrame: TGeoDataFrame; AFrom, ATo: Integer;
      AMsgs: TStrings);

    // Local coordinates from the signed chain, no transformation
    procedure BuildLocalPoints(const AChain: TPointsArray);

    // AChain - one stretch:
    //   PointNumber = point ID
    //   X = signed distance FROM previous point TO this point
    //       (+ right, - left in the field, first point = 0)
    // IdenticalPoints must hold the two given ends before the call.
    function TransformChain(const AChain: TPointsArray): TPointsArray;
  public
    class function TaskCode: Integer; override;

    // Walks the chain in the frame and fills Xm, Ym of every row
    procedure BuildLocalFrame(AFrame: TGeoDataFrame);

    /// <summary>A given point already has coordinates.</summary>
    class function IsGiven(const ARow: TGeoRow): Boolean;

    // Splits the frame into stretches between two different given points
    // and fills X, Y of the computed ones
    procedure Calculate(AFrame: TGeoDataFrame); override;

    // Stretches of the last run, for the protocol
    property Segments: TSegmentArray read FSegments;
  end;

implementation

class function TRectangularMeasurementsAlgorithm.IsGiven(
  const ARow: TGeoRow): Boolean;
begin
  Result := not (IsNan(ARow.X) or IsNan(ARow.Y));
end;

class function TRectangularMeasurementsAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_KONSTRUKCNI;
end;

procedure TRectangularMeasurementsAlgorithm.BuildLocalPoints(
  const AChain: TPointsArray);
var
  I: Integer;
  DirX, DirY, NewDirX, CurX, CurY, Dist, TS, D: Double;
begin
  SetLength(FLocalPoints, Length(AChain));
  CurX := 0;  CurY := 0;
  DirX := 1;  DirY := 0;

  for I := 0 to High(AChain) do
  begin
    if I > 0 then
    begin
      D := AChain[I].X;
      if IsNan(D) then
        D := 0;                    // an unfilled length is no step

      // S-JTSK axes: X south, Y west
      TS := Sign(D);
      if TS <> 0 then
      begin
        NewDirX := -TS * DirY;
        DirY := TS * DirX;
        DirX := NewDirX;
      end;

      Dist := Abs(D);
      CurX := CurX + Dist * DirX;
      CurY := CurY + Dist * DirY;
    end;

    FLocalPoints[I].PointNumber := AChain[I].PointNumber;
    FLocalPoints[I].X := CurX;
    FLocalPoints[I].Y := CurY;
  end;
end;

procedure TRectangularMeasurementsAlgorithm.BuildLocalFrame(AFrame: TGeoDataFrame);
var
  I: Integer;
  Chain: TPointsArray;
begin
  SetLength(Chain, AFrame.Count);
  for I := 0 to AFrame.Count - 1 do
  begin
    Chain[I].PointNumber := StrToInt64Def(string(AFrame.Rows[I].CB), 0);
    if I = 0 then
      Chain[I].X := 0              // the walk starts here
    else
      Chain[I].X := AFrame.Rows[I].SH;
  end;

  BuildLocalPoints(Chain);

  for I := 0 to AFrame.Count - 1 do
  begin
    AFrame.Rows[I].Xm := FLocalPoints[I].X;
    AFrame.Rows[I].Ym := FLocalPoints[I].Y;
  end;
end;

function TRectangularMeasurementsAlgorithm.TransformChain(
  const AChain: TPointsArray): TPointsArray;
var
  I, J, N, IdCount: Integer;
  D: Double;
  LocalId, GlobalId: TPointsArray;
  Transform: TCongruentTransformation;
begin
  ClearWarnings;
  N := Length(AChain);

  BuildLocalPoints(AChain);

  IdCount := 0;
  for I := 0 to N - 1 do
    for J := 0 to High(FIdenticalPoints) do
      if FLocalPoints[I].PointNumber = FIdenticalPoints[J].PointNumber then
      begin
        Inc(IdCount);
        SetLength(LocalId, IdCount);
        SetLength(GlobalId, IdCount);
        LocalId[IdCount - 1] := FLocalPoints[I];
        GlobalId[IdCount - 1] := FIdenticalPoints[J];
        Break;
      end;

  if IdCount < 2 then
    raise Exception.Create(
      'Jsou potřeba alespoň 2 body se známými souřadnicemi.');

  Transform := TCongruentTransformation.Create;
  try
    Transform.ComputeParametersFromPoints(LocalId, GlobalId);
    Result := Transform.Calculate(FLocalPoints);
  finally
    Transform.Free;
  end;

  FClosure := 0;
  for I := 0 to High(Result) do
    for J := 0 to High(FIdenticalPoints) do
      if Result[I].PointNumber = FIdenticalPoints[J].PointNumber then
      begin
        D := Sqrt(Sqr(Result[I].X - FIdenticalPoints[J].X) +
                  Sqr(Result[I].Y - FIdenticalPoints[J].Y));
        if D > FClosure then
          FClosure := D;
        Break;
      end;
end;
procedure TRectangularMeasurementsAlgorithm.ComputeStretch(
  AFrame: TGeoDataFrame; AFrom, ATo: Integer; AMsgs: TStrings);
var
  I, N: Integer;
  Chain, Ident, Res, Loc: TPointsArray;
  Seg: TSegmentInfo;
  Head: string;
  NoLength: Boolean;
begin
  N := ATo - AFrom + 1;
  if N < 3 then Exit;            // two given points side by side

  Head := Format('Úsek %s-%s: ',
    [string(AFrame.Rows[AFrom].CB), string(AFrame.Rows[ATo].CB)]);

  if N - 2 > MAX_INTERMEDIATE then
    AMsgs.Add(Head + Format('%d mezilehlých bodů, obvykle nejvýš %d.',
      [N - 2, MAX_INTERMEDIATE]));

  NoLength := False;
  SetLength(Chain, N);
  for I := 0 to N - 1 do
  begin
    Chain[I].PointNumber := StrToInt64Def(string(AFrame.Rows[AFrom + I].CB), 0);
    if I = 0 then
      Chain[I].X := 0            // the walk starts here
    else
    begin
      // Into the map the length goes reduced by the scale
      Chain[I].X := AFrame.Rows[AFrom + I].SH * Scale;
      if IsNan(Chain[I].X) then
      begin
        AMsgs.AddObject(Head + Format('bod %s nemá délku.',
          [string(AFrame.Rows[AFrom + I].CB)]), ErrorMark);
        NoLength := True;
      end;
    end;
  end;

  // A missing length would put the point onto the previous one
  if NoLength then
  begin
    AMsgs.AddObject(Head + 'úsek se nepočítá.', ErrorMark);
    Exit;
  end;

  SetLength(Ident, 2);
  Ident[0].PointNumber := Chain[0].PointNumber;
  Ident[0].X := AFrame.Rows[AFrom].X;
  Ident[0].Y := AFrame.Rows[AFrom].Y;
  Ident[1].PointNumber := Chain[N - 1].PointNumber;
  Ident[1].X := AFrame.Rows[ATo].X;
  Ident[1].Y := AFrame.Rows[ATo].Y;

  if IsNan(Ident[0].X) or IsNan(Ident[0].Y) or
     IsNan(Ident[1].X) or IsNan(Ident[1].Y) then
  begin
    AMsgs.AddObject(Head + 'daný bod nemá souřadnice.', ErrorMark);
    Exit;
  end;

  FIdenticalPoints := Ident;
  try
    Res := TransformChain(Chain);
  except
    on E: Exception do
    begin
      AMsgs.AddObject(Head + E.Message, ErrorMark);
      Exit;
    end;
  end;

  for I := 0 to Warnings.Count - 1 do
    AMsgs.AddObject(Head + Warnings[I], Warnings.Objects[I]);

  Loc := FLocalPoints;
  Seg.FromRow  := AFrom;
  Seg.ToRow    := ATo;
  Seg.Closure  := FClosure;
  Seg.MeasDist := Sqrt(Sqr(Loc[N - 1].X - Loc[0].X) +
    Sqr(Loc[N - 1].Y - Loc[0].Y));
  Seg.CalcDist := Sqrt(Sqr(Ident[1].X - Ident[0].X) +
    Sqr(Ident[1].Y - Ident[0].Y));

  // KatV 13.5, the end with the lower accuracy decides
  Seg.Limit := TValidationUtils.LengthLimit(
    Max(Seg.MeasDist, Seg.CalcDist),
    TValidationUtils.LowerQuality(AFrame.Rows[AFrom].KK,
      AFrame.Rows[ATo].KK));

  if not IsNan(Seg.Limit) and
     (Abs(Seg.CalcDist - Seg.MeasDist) >= Seg.Limit) then
    AMsgs.Add(Head + Format('odchylka délky %.3f m není menší ' +
      'než mezní rozdíl %.3f m.',
      [Abs(Seg.CalcDist - Seg.MeasDist), Seg.Limit]));

  // Given points keep their own coordinates
  for I := 0 to N - 1 do
    if not IsGiven(AFrame.Rows[AFrom + I]) then
    begin
      AFrame.Rows[AFrom + I].X := Res[I].X;
      AFrame.Rows[AFrom + I].Y := Res[I].Y;
    end;

  SetLength(FSegments, Length(FSegments) + 1);
  FSegments[High(FSegments)] := Seg;
end;

procedure TRectangularMeasurementsAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I, First: Integer;
  Msgs: TStringList;
begin
  ClearWarnings;
  SetLength(FSegments, 0);
  if AFrame.Count = 0 then Exit;

  // The chain has to start on a given point
  if not IsGiven(AFrame.Rows[0]) then
  begin
    AddError('První bod řetězce musí být daný.');
    Exit;
  end;

  // Calculate clears the warnings, so they are kept aside
  Msgs := TStringList.Create;
  try
    First := 0;
    for I := 1 to AFrame.Count - 1 do
      // Coming back to the same point closes nothing - rotation needs two
      if IsGiven(AFrame.Rows[I]) and
         (AFrame.Rows[I].CB <> AFrame.Rows[First].CB) then
      begin
        ComputeStretch(AFrame, First, I, Msgs);
        First := I;
      end;

    if First < AFrame.Count - 1 then
      Msgs.AddObject(Format('Za bodem %s už není známý bod, ' +
        'nespočítané body: %d.',
        [string(AFrame.Rows[First].CB), AFrame.Count - 1 - First]), ErrorMark);

    // The marks of the errors go with the messages
    ClearWarnings;
    Warnings.AddStrings(Msgs);
  finally
    Msgs.Free;
  end;
end;


end.
