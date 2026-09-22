unit GeoAlgorithmRectangularMeasurements;

// Rectangular measurements method (konstrukční oměrné).
// Determines unknown points along a building outline from measured
// distances and 90-degree turn signs. Known points anywhere in the
// chain serve as identical points for a congruent transformation
// that maps local (chain-built) coordinates into S-JTSK.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase,
  GeoAlgorithmTransformCongruent, Point;

type
  TRectangularMeasurementsAlgorithm = class(TAlgorithm)
  private
    FIdenticalPoints: TPointsArray;
    FLocalPoints: TPointsArray;
    FClosure: Double;
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

    // Local coordinates from the signed chain, no transformation
    procedure BuildLocalPoints(const AChain: TPointsArray);
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
  DirX, DirY, NewDirX, CurX, CurY, Dist, TS: Double;
begin
  SetLength(FLocalPoints, Length(AChain));
  CurX := 0;  CurY := 0;
  DirX := 1;  DirY := 0;

  for I := 0 to High(AChain) do
  begin
    if I > 0 then
    begin
      // S-JTSK axes: X south, Y west
      TS := Sign(AChain[I].X);
      if TS <> 0 then
      begin
        NewDirX := -TS * DirY;
        DirY := TS * DirX;
        DirX := NewDirX;
      end;

      Dist := Abs(AChain[I].X);
      CurX := CurX + Dist * DirX;
      CurY := CurY + Dist * DirY;
    end;

    FLocalPoints[I].PointNumber := AChain[I].PointNumber;
    FLocalPoints[I].X := CurX;
    FLocalPoints[I].Y := CurY;
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

end.
