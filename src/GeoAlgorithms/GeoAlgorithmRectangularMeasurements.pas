unit GeoAlgorithmRectangularMeasurements;

// Rectangular measurements method (konstrukční oměrné).
// Determines unknown points along a building outline from measured
// distances and 90-degree turn signs. Known points anywhere in the
// chain serve as identical points for a congruent transformation
// that maps local (chain-built) coordinates into S-JTSK.

interface

uses
  System.SysUtils, System.Classes, Math, GeoAlgorithmBase,
  GeoAlgorithmTransformCongruent, Point, GeoRow, GeoDataFrame;

const
  // Row codes of this task, stored in TGeoRow.Uloha
  ULOHA_IDENT = 41;   // identical (given) point
  ULOHA_DET   = 42;   // point the program computes

type
  // One computed stretch; rows are indexes into the frame
  TSegmentInfo = record
    FromRow, ToRow: Integer;
    Closure:  Double;
    MeasDist: Double;   // from the local walk
    CalcDist: Double;   // from the given coordinates
  end;

  TSegmentArray = array of TSegmentInfo;

  TRectangularMeasurementsAlgorithm = class(TAlgorithm)
  private
    FIdenticalPoints: TPointsArray;
    FLocalPoints: TPointsArray;
    FClosure: Double;
    FSegments: TSegmentArray;

    procedure ComputeStretch(AFrame: TGeoDataFrame; AFrom, ATo: Integer;
      AMsgs: TStrings);

    // Local coordinates from the signed chain, no transformation
    procedure BuildLocalPoints(const AChain: TPointsArray);
  public
    constructor Create;

    property IdenticalPoints: TPointsArray
      read FIdenticalPoints write FIdenticalPoints;

    // Local coordinates built from the chain (before transformation)
    property LocalPoints: TPointsArray read FLocalPoints;

    property Closure: Double read FClosure;

    // InputPoints — measurement chain:
    //   PointNumber = point ID
    //   X = signed distance FROM previous point TO this point
    //       (+ right, - left in the field; first point = 0)
    function Calculate(const InputPoints: TPointsArray): TPointsArray; override;

    // Walks the chain in the frame and fills Xm, Ym of every row
    procedure BuildLocalFrame(AFrame: TGeoDataFrame);

    // Splits the frame into stretches between two different given points
    // and fills X, Y of the computed ones
    procedure CalculateFrame(AFrame: TGeoDataFrame);

    // Stretches of the last run, for the protocol
    property Segments: TSegmentArray read FSegments;
  end;

implementation

constructor TRectangularMeasurementsAlgorithm.Create;
begin
  inherited Create;
  FClosure := 0;
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

function TRectangularMeasurementsAlgorithm.Calculate(
  const InputPoints: TPointsArray): TPointsArray;
var
  I, J, N, IdCount: Integer;
  D: Double;
  LocalId, GlobalId: TPointsArray;
  Transform: TCongruentTransformation;
begin
  ClearWarnings;
  N := Length(InputPoints);

  if N < 3 then
    raise Exception.Create('Pro výpočet jsou potřeba alespoň 3 body.');

  BuildLocalPoints(InputPoints);

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
    raise Exception.Create('Jsou potřeba alespoň 2 body se známými souřadnicemi.');

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
        if D > 0.02 then
          AddWarning(Format('Point %d: residual %.3f m at identical point.',
            [Result[I].PointNumber, D]));
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
begin
  N := ATo - AFrom + 1;
  if N < 3 then Exit;            // two given points side by side

  Head := Format('Úsek %s–%s: ',
    [string(AFrame.Rows[AFrom].CB), string(AFrame.Rows[ATo].CB)]);

  SetLength(Chain, N);
  for I := 0 to N - 1 do
  begin
    Chain[I].PointNumber := StrToInt64Def(string(AFrame.Rows[AFrom + I].CB), 0);
    if I = 0 then
      Chain[I].X := 0            // the walk starts here
    else
    begin
      Chain[I].X := AFrame.Rows[AFrom + I].SH;
      if IsNan(Chain[I].X) then
        AMsgs.Add(Head + Format('bod %s nemá délku.',
          [string(AFrame.Rows[AFrom + I].CB)]));
    end;
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
    AMsgs.Add(Head + 'daný bod nemá souřadnice.');
    Exit;
  end;

  FIdenticalPoints := Ident;
  try
    Res := Calculate(Chain);
  except
    on E: Exception do
    begin
      AMsgs.Add(Head + E.Message);
      Exit;
    end;
  end;

  for I := 0 to Warnings.Count - 1 do
    AMsgs.Add(Head + Warnings[I]);

  Loc := FLocalPoints;
  Seg.FromRow  := AFrom;
  Seg.ToRow    := ATo;
  Seg.Closure  := FClosure;
  Seg.MeasDist := Sqrt(Sqr(Loc[N - 1].X - Loc[0].X) + Sqr(Loc[N - 1].Y - Loc[0].Y));
  Seg.CalcDist := Sqrt(Sqr(Ident[1].X - Ident[0].X) + Sqr(Ident[1].Y - Ident[0].Y));

  // Given points keep their own coordinates
  for I := 0 to N - 1 do
    if AFrame.Rows[AFrom + I].Uloha <> ULOHA_IDENT then
    begin
      AFrame.Rows[AFrom + I].X := Res[I].X;
      AFrame.Rows[AFrom + I].Y := Res[I].Y;
    end;

  SetLength(FSegments, Length(FSegments) + 1);
  FSegments[High(FSegments)] := Seg;
end;

procedure TRectangularMeasurementsAlgorithm.CalculateFrame(AFrame: TGeoDataFrame);
var
  I, First: Integer;
  Msgs: TStringList;
begin
  ClearWarnings;
  SetLength(FSegments, 0);
  if AFrame.Count = 0 then Exit;

  // The chain has to start on a given point
  if AFrame.Rows[0].Uloha <> ULOHA_IDENT then
  begin
    AddWarning('První bod řetězce musí být daný.');
    Exit;
  end;

  // Calculate clears the warnings, so they are kept aside
  Msgs := TStringList.Create;
  try
    First := 0;
    for I := 1 to AFrame.Count - 1 do
      // Coming back to the same point closes nothing - rotation needs two
      if (AFrame.Rows[I].Uloha = ULOHA_IDENT) and
         (AFrame.Rows[I].CB <> AFrame.Rows[First].CB) then
      begin
        ComputeStretch(AFrame, First, I, Msgs);
        First := I;
      end;

    if First < AFrame.Count - 1 then
      Msgs.Add(Format('Za bodem %s už není známý bod, nespočítané body: %d.',
        [string(AFrame.Rows[First].CB), AFrame.Count - 1 - First]));

    ClearWarnings;
    for I := 0 to Msgs.Count - 1 do
      AddWarning(Msgs[I]);
  finally
    Msgs.Free;
  end;
end;


end.
