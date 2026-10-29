unit GeoAlgorithmForwardIntersection;

// Intersection from directions measured on two oriented stations.
// Blocks split by an empty row: station A with its orientations, station B
// with its orientations, then the new points with a direction from each.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, GeoAlgorithmPolar, GeoRow,
  GeoDataFrame, ValidationUtils;

const
  // Task code from the survey notebook convention
  ULOHA_PROTINANI_SMERY = 6;

  MIN_ANGLE = 30;       // [gon] a sharper intersection is weak
  MAX_ANGLE = 170;

type
  // What a frame row is
  TIntersectionRole = (irEmpty, irStation, irOrientation, irPoint);

  // One oriented station
  TStationInfo = record
    Row: Integer;          // frame row of the station, -1 if missing
    OrientCount: Integer;
    phi: Double;           // orientation shift [gon], 0 to 400
  end;

  TForwardIntersectionAlgorithm = class(TFrameAlgorithm)
  private
    FValid: Boolean;
    FRoles: TArray<TIntersectionRole>;
    FdPhi: TArray<Double>;   // dfi of each orientation [gon]
    FOmega: TArray<Double>;       // angle at each new point [gon]
    FStations: array[0..1] of TStationInfo;
    procedure FindRoles(AFrame: TGeoDataFrame);
    function OrientStation(AFrame: TGeoDataFrame; AIndex: Integer): Boolean;
    function GetStation(AIndex: Integer): TStationInfo;
  public
    class function TaskCode: Integer; override;

    /// <summary>HZ direction or the one from A, Zuhel from B.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    property Valid: Boolean read FValid;
    property Roles: TArray<TIntersectionRole> read FRoles;
    property dPhi: TArray<Double> read FdPhi;
    property omega: TArray<Double> read FOmega;
    /// <summary>0 is station A, 1 is station B.</summary>
    property Stations[AIndex: Integer]: TStationInfo read GetStation;
  end;

implementation

const
  GON_TO_RAD = Pi / 200;
  RAD_TO_GON = 200 / Pi;

class function TForwardIntersectionAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_PROTINANI_SMERY;
end;

function TForwardIntersectionAlgorithm.GetStation(
  AIndex: Integer): TStationInfo;
begin
  Result := FStations[AIndex];
end;

// Block 0 and 1 start with a station, block 2 and on are the new points
procedure TForwardIntersectionAlgorithm.FindRoles(AFrame: TGeoDataFrame);
var
  I, Block: Integer;
  InBlock: Boolean;
begin
  SetLength(FRoles, AFrame.Count);
  Block := 0;
  InBlock := False;
  for I := 0 to AFrame.Count - 1 do
  begin
    if Trim(string(AFrame.Rows[I].CB)) = '' then
    begin
      FRoles[I] := irEmpty;
      if InBlock then
        Inc(Block);              // an empty row ends the block
      InBlock := False;
      Continue;
    end;

    if Block >= 2 then
      FRoles[I] := irPoint
    else if not InBlock then
    begin
      FRoles[I] := irStation;
      FStations[Block].Row := I;
    end
    else
      FRoles[I] := irOrientation;
    InBlock := True;
  end;
end;

// The shift and the deviations as in the polar method
function TForwardIntersectionAlgorithm.OrientStation(AFrame: TGeoDataFrame;
  AIndex: Integer): Boolean;
var
  I, Last: Integer;
  Station: TGeoRow;
  LongestLength: Double;
begin
  Result := False;
  Station := AFrame.Rows[FStations[AIndex].Row];
  if IsNan(Station.X) or IsNan(Station.Y) then
  begin
    AddError(Format('Stanovisko %s nemá souřadnice.',
      [Trim(string(Station.CB))]));
    Exit;
  end;

  // The orientations are the rows up to the next station or point
  Last := FStations[AIndex].Row;
  while (Last + 1 < AFrame.Count) and (FRoles[Last + 1] = irOrientation) do
    Inc(Last);

  LongestLength := 0;
  for I := FStations[AIndex].Row + 1 to Last do
  begin
    if IsNan(AFrame.Rows[I].X) or IsNan(AFrame.Rows[I].Y) then
    begin
      AddError(Format('Orientace %s nemá souřadnice.',
        [Trim(string(AFrame.Rows[I].CB))]));
      Exit;
    end;
    if IsNan(AFrame.Rows[I].HZ) then
    begin
      AddError(Format('Orientace %s nemá směr.',
        [Trim(string(AFrame.Rows[I].CB))]));
      Exit;
    end;
    LongestLength := Max(LongestLength, Sqrt(Sqr(AFrame.Rows[I].X -
      Station.X) + Sqr(AFrame.Rows[I].Y - Station.Y)));
  end;

  FStations[AIndex].OrientCount := Last - FStations[AIndex].Row;
  if (FStations[AIndex].OrientCount = 0) or (LongestLength < 0.001) then
  begin
    AddError(Format('Stanovisko %s nemá orientaci.',
      [Trim(string(Station.CB))]));
    Exit;
  end;

  FStations[AIndex].phi := TPolarMethodAlgorithm.MeanShift(AFrame,
    Station, FStations[AIndex].Row + 1, Last);
  if FStations[AIndex].phi < 0 then
    FStations[AIndex].phi := FStations[AIndex].phi + 400;

  // Deviation of each orientation from the mean shift
  for I := FStations[AIndex].Row + 1 to Last do
  begin
    FdPhi[I] := -TPolarMethodAlgorithm.ResultOf(Station,
      AFrame.Rows[I], FStations[AIndex].phi, 1).dPhi;
    if Abs(FdPhi[I]) > MEZNI_DFI then
      AddWarning(Format('Orientace %s: odchylka dfi = %.4f g překračuje ' +
        'mezní hodnotu %.2f g - Návod pro obnovu katastrálního operátu, ' +
        'bod 4.3.5.1.2 c)', [Trim(string(AFrame.Rows[I].CB)),
        FdPhi[I], MEZNI_DFI]));
  end;
  Result := True;
end;

procedure TForwardIntersectionAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I, Quality: Integer;
  StationA, StationB: TGeoRow;
  DeltaXAB, DeltaYAB, sigmaAP, sigmaBP, sinOmega, sAP: Double;
  PointNumber: string;
begin
  ClearWarnings;
  FValid := False;
  FStations[0].Row := -1;
  FStations[1].Row := -1;
  FStations[0].OrientCount := 0;
  FStations[1].OrientCount := 0;
  FStations[0].phi := NaN;
  FStations[1].phi := NaN;
  SetLength(FdPhi, AFrame.Count);
  SetLength(FOmega, AFrame.Count);
  for I := 0 to AFrame.Count - 1 do
  begin
    FdPhi[I] := NaN;
    FOmega[I] := NaN;
  end;

  FindRoles(AFrame);

  // Old results must not survive a failed run
  for I := 0 to AFrame.Count - 1 do
    if FRoles[I] = irPoint then
    begin
      AFrame.Rows[I].X := NaN;
      AFrame.Rows[I].Y := NaN;
    end;

  if FStations[0].Row < 0 then
  begin
    AddError('Zadejte stanovisko A s orientacemi.');
    Exit;
  end;
  if FStations[1].Row < 0 then
  begin
    AddError('Zadejte stanovisko B s orientacemi.');
    Exit;
  end;
  if not OrientStation(AFrame, 0) or not OrientStation(AFrame, 1) then
    Exit;

  StationA := AFrame.Rows[FStations[0].Row];
  StationB := AFrame.Rows[FStations[1].Row];
  Quality := TValidationUtils.LowerQuality(StationA.KK, StationB.KK);
  DeltaXAB := StationB.X - StationA.X;
  DeltaYAB := StationB.Y - StationA.Y;

  for I := 0 to AFrame.Count - 1 do
  begin
    if FRoles[I] <> irPoint then
      Continue;
    PointNumber := Trim(string(AFrame.Rows[I].CB));
    if IsNan(AFrame.Rows[I].HZ) or IsNan(AFrame.Rows[I].Zuhel) then
    begin
      AddError(Format('Bod %s: chybí směr z A nebo z B.', [PointNumber]));
      Continue;
    end;

    // Oriented directions, the rays from A and from B
    sigmaAP := (AFrame.Rows[I].HZ + FStations[0].phi) * GON_TO_RAD;
    sigmaBP := (AFrame.Rows[I].Zuhel + FStations[1].phi) * GON_TO_RAD;
    // sin(sigmaBP - sigmaAP), zero means parallel directions
    sinOmega := Cos(sigmaAP) * Sin(sigmaBP) -
      Sin(sigmaAP) * Cos(sigmaBP);
    if Abs(sinOmega) < 1E-12 then
    begin
      AddError(Format('Bod %s: směry z A a z B jsou rovnoběžné.',
        [PointNumber]));
      Continue;
    end;

    // Length from A to the new point by the sine rule
    sAP := (DeltaXAB * Sin(sigmaBP) - DeltaYAB * Cos(sigmaBP)) / sinOmega;
    AFrame.Rows[I].X := StationA.X + sAP * Cos(sigmaAP);
    AFrame.Rows[I].Y := StationA.Y + sAP * Sin(sigmaAP);
    AFrame.Rows[I].KK := Quality;

    FOmega[I] := Abs(ArcTan2(sinOmega, Cos(sigmaAP) * Cos(sigmaBP) +
      Sin(sigmaAP) * Sin(sigmaBP))) * RAD_TO_GON;
    if (FOmega[I] < MIN_ANGLE) or (FOmega[I] > MAX_ANGLE) then
      AddWarning(Format('Bod %s: úhel protnutí %.1f gon je mimo %d až %d gon.',
        [PointNumber, FOmega[I], MIN_ANGLE, MAX_ANGLE]));
    if sAP < 0 then
      AddWarning(Format('Bod %s leží za stanoviskem A, zkontrolujte směry.',
        [PointNumber]));
  end;

  FValid := True;
end;

end.
