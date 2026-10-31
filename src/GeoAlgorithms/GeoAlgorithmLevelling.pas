unit GeoAlgorithmLevelling;

// Technical levelling, one way or there and back.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, GeoRow, GeoDataFrame;

const
  // Task code of levelling, not in the MAPA2 list
  ULOHA_NIVELACE = 51;

type
  // Which reading a row carries
  TLevellingReading = (lrNone, lrBack, lrFore, lrSide, lrMore);

  // The last run for the protocol
  TLevellingInfo = record
    Valid:       Boolean;
    BothWays:    Boolean;   // measured there and back
    Closed:      Boolean;   // ends on the start point
    Open:        Boolean;   // the end has no given height, no check
    SetupCount:  Integer;
    TotalLength: Double;    // back and fore sights [m]
    SumHeight:   Double;    // measured height differences, there
    SumBack:     Double;    // the way back, NaN if one way
    Given:       Double;    // end height minus start height, NaN if open
    Misclosure:  Double;    // against Given, or there plus back
    Limit:       Double;    // 20 mm √(L/2), there and back 20 mm √L
  end;

  TLevellingAlgorithm = class(TFrameAlgorithm)
  private
    FInfo: TLevellingInfo;
    FBothWays: Boolean;
    function CheckLayout(AFrame: TGeoDataFrame): Boolean;
    function FindTurn(AFrame: TGeoDataFrame): Integer;
    procedure SumRows(AFrame: TGeoDataFrame; AFrom, ATo: Integer; out ASum, ALength: Double);
    procedure DistributeCorrection(AFrame: TGeoDataFrame);
    procedure ChainHeights(AFrame: TGeoDataFrame; AFrom, ATo: Integer; AStart: Double);
    procedure CalculateBothWays(AFrame: TGeoDataFrame);
  public
    class function TaskCode: Integer; override;

    /// <summary>Readings in Xm, Ym, Zm, heights out in VC.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    /// <summary>The reading filled in on the row.</summary>
    class function ReadingOf(const ARow: TGeoRow): TLevellingReading;

    /// <summary>Measured there and back, the turn point twice.</summary>
    property BothWays: Boolean read FBothWays write FBothWays;
    property Info: TLevellingInfo read FInfo;
  end;

implementation

class function TLevellingAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_NIVELACE;
end;

class function TLevellingAlgorithm.ReadingOf(
  const ARow: TGeoRow): TLevellingReading;
var
  Count: Integer;
begin
  Count := 0;
  if not IsNan(ARow.Xm) then
    Inc(Count);
  if not IsNan(ARow.Ym) then
    Inc(Count);
  if not IsNan(ARow.Zm) then
    Inc(Count);

  if Count > 1 then
    Result := lrMore
  else if not IsNan(ARow.Xm) then
    Result := lrBack
  else if not IsNan(ARow.Ym) then
    Result := lrFore
  else if not IsNan(ARow.Zm) then
    Result := lrSide
  else
    Result := lrNone;
end;

// A setup is back, side readings, fore. The start needs a height.
function TLevellingAlgorithm.CheckLayout(AFrame: TGeoDataFrame): Boolean;
var
  I: Integer;
  Reading, Previous: TLevellingReading;
begin
  Result := False;
  if AFrame.Count = 0 then
  begin
    AddError('Zápisník je prázdný.');
    Exit;
  end;

  // Before the first row the line expects a back reading
  Previous := lrFore;
  for I := 0 to AFrame.Count - 1 do
  begin
    Reading := ReadingOf(AFrame.Rows[I]);
    if Reading = lrNone then
      AddError(Format('Řádek %d: chybí čtení.', [I + 1]))
    else if Reading = lrMore then
      AddError(Format('Řádek %d: vyplňte jen jedno čtení.', [I + 1]))
    else if (Reading = lrBack) and (Previous <> lrFore) then
      AddError(Format('Řádek %d: čtení vzad bez předchozího vpřed.',
        [I + 1]))
    else if (Reading <> lrBack) and (Previous = lrFore) then
      AddError(Format('Řádek %d: chybí čtení vzad.', [I + 1]))
    else
      Previous := Reading;

    if IsNan(AFrame.Rows[I].SH) then
      AddError(Format('Řádek %d: chybí délka záměry.', [I + 1]));
  end;
  if Previous <> lrFore then
    AddError('Pořad musí končit čtením vpřed.');

  if IsNan(AFrame.Rows[0].Z) then
    AddError(Format('Začátek pořadu %s nemá danou výšku.',
      [Trim(string(AFrame.Rows[0].CB))]));

  Result := Warnings.Count = 0;
end;

// The turn: one point number on a fore row and on the next back row
function TLevellingAlgorithm.FindTurn(AFrame: TGeoDataFrame): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to AFrame.Count - 2 do
    if (ReadingOf(AFrame.Rows[I]) = lrFore) and
       (ReadingOf(AFrame.Rows[I + 1]) = lrBack) and
       (Trim(string(AFrame.Rows[I].CB)) <> '') and
       (AFrame.Rows[I].CB = AFrame.Rows[I + 1].CB) then
    begin
      if Result >= 0 then
      begin
        AddError('Tam a zpět: bod obratu je v zápisníku víckrát.');
        Exit(-1);
      end;
      Result := I;
    end;

  if Result < 0 then
    AddError('Tam a zpět: číslo bodu obratu zapište na řádek vpřed ' +
      'i na následující řádek vzad.');
end;

// Height difference and length of the setups in rows AFrom..ATo
procedure TLevellingAlgorithm.SumRows(AFrame: TGeoDataFrame; AFrom, ATo: Integer; out ASum, ALength: Double);
var
  I: Integer;
  Back, BackLength: Double;
begin
  ASum := 0;
  ALength := 0;
  Back := 0;
  BackLength := 0;
  for I := AFrom to ATo do
    case ReadingOf(AFrame.Rows[I]) of
      lrBack:
        begin
          Back := AFrame.Rows[I].Xm;
          BackLength := AFrame.Rows[I].SH;
        end;
      lrFore:
        begin
          ASum := ASum + Back - AFrame.Rows[I].Ym;
          ALength := ALength + BackLength + AFrame.Rows[I].SH;
          Inc(FInfo.SetupCount);
        end;
    end;
end;

// Whole mm on the back readings, evenly, the rest to the larger readings
procedure TLevellingAlgorithm.DistributeCorrection(AFrame: TGeoDataFrame);
var
  I, K, Best, Total, Base, Rest: Integer;
  Backs: TArray<Integer>;
  Chosen: TArray<Boolean>;
begin
  for I := 0 to AFrame.Count - 1 do
    if ReadingOf(AFrame.Rows[I]) = lrBack then
      Backs := Backs + [I];

  // Should be minus is, in mm
  Total := Round(-FInfo.Misclosure * 1000);
  Base := Abs(Total) div Length(Backs);
  Rest := Abs(Total) mod Length(Backs);
  for I in Backs do
    AFrame.Rows[I].Vy := Sign(Total) * Base / 1000;

  // The first of equal readings wins
  SetLength(Chosen, Length(Backs));
  for K := 1 to Rest do
  begin
    Best := -1;
    for I := 0 to High(Backs) do
      if not Chosen[I] and ((Best < 0) or
         (AFrame.Rows[Backs[I]].Xm > AFrame.Rows[Backs[Best]].Xm)) then
        Best := I;
    Chosen[Best] := True;
    AFrame.Rows[Backs[Best]].Vy := AFrame.Rows[Backs[Best]].Vy +
      Sign(Total) / 1000;
  end;
end;

// Heights from AStart, the horizon with the corrected back reading
procedure TLevellingAlgorithm.ChainHeights(AFrame: TGeoDataFrame; AFrom, ATo: Integer; AStart: Double);
var
  I: Integer;
  Back, Horizon, Height: Double;
begin
  Back := 0;
  Horizon := AStart;
  Height := AStart;
  for I := AFrom to ATo do
    case ReadingOf(AFrame.Rows[I]) of
      lrBack:
        begin
          Back := AFrame.Rows[I].Xm;
          Horizon := Height + Back;
          if not IsNan(AFrame.Rows[I].Vy) then
            Horizon := Horizon + AFrame.Rows[I].Vy;
          AFrame.Rows[I].VC := Height;
        end;
      lrSide:
        begin
          AFrame.Rows[I].Vz := Back - AFrame.Rows[I].Zm;
          AFrame.Rows[I].VC := Horizon - AFrame.Rows[I].Zm;
        end;
      lrFore:
        begin
          AFrame.Rows[I].Vz := Back - AFrame.Rows[I].Ym;
          Height := Horizon - AFrame.Rows[I].Ym;
          AFrame.Rows[I].VC := Height;
        end;
    end;
end;

// There and back, the difference of the two ways, heights as their mean
procedure TLevellingAlgorithm.CalculateBothWays(AFrame: TGeoDataFrame);
var
  I, J, Turn, LastRow: Integer;
  LengthThere, LengthBack, Mean: Double;
begin
  LastRow := AFrame.Count - 1;
  if AFrame.Rows[0].CB <> AFrame.Rows[LastRow].CB then
    AddError(Format('Tam a zpět musí skončit na bodě začátku %s.',
      [Trim(string(AFrame.Rows[0].CB))]));
  Turn := FindTurn(AFrame);
  if Warnings.Count > 0 then
    Exit;

  SumRows(AFrame, 0, Turn, FInfo.SumHeight, LengthThere);
  SumRows(AFrame, Turn + 1, LastRow, FInfo.SumBack, LengthBack);
  // L is the length of the line, one way
  FInfo.TotalLength := (LengthThere + LengthBack) / 2;
  if FInfo.TotalLength <= 0 then
  begin
    AddError('Součet délek záměr je nulový.');
    Exit;
  end;

  FInfo.Misclosure := FInfo.SumHeight + FInfo.SumBack;
  // Annex 4.9 of decree 31/1995, L in km
  FInfo.Limit := 0.020 * Sqrt(FInfo.TotalLength / 1000);
  if Abs(FInfo.Misclosure) > FInfo.Limit then
    AddWarning(Format('Rozdíl tam a zpět %.3f m překračuje mezní rozdíl ' +
      '%.3f m - příloha, bod 4.9 vyhlášky 31/1995 Sb.',
      [FInfo.Misclosure, FInfo.Limit]));

  // Each way on its own, the way back ends on the start
  ChainHeights(AFrame, 0, Turn, AFrame.Rows[0].Z);
  ChainHeights(AFrame, Turn + 1, LastRow, AFrame.Rows[Turn].VC);
  for I := Turn + 1 to LastRow do
    AFrame.Rows[I].VC := AFrame.Rows[I].VC - FInfo.Misclosure;

  // A point measured both ways gets the mean, the start keeps its height
  for I := 0 to Turn do
  begin
    if (ReadingOf(AFrame.Rows[I]) = lrSide) or
       (Trim(string(AFrame.Rows[I].CB)) = '') or
       (AFrame.Rows[I].CB = AFrame.Rows[0].CB) then
      Continue;
    for J := Turn + 1 to LastRow do
      if (ReadingOf(AFrame.Rows[J]) <> lrSide) and
         (AFrame.Rows[J].CB = AFrame.Rows[I].CB) then
      begin
        Mean := (AFrame.Rows[I].VC + AFrame.Rows[J].VC) / 2;
        AFrame.Rows[I].VC := Mean;
        AFrame.Rows[J].VC := Mean;
      end;
  end;
  if Trim(string(AFrame.Rows[0].CB)) <> '' then
    for I := 0 to LastRow do
      if AFrame.Rows[I].CB = AFrame.Rows[0].CB then
        AFrame.Rows[I].VC := AFrame.Rows[0].Z;
  // A back row without a number is the point of the fore row above it
  for I := 1 to LastRow do
    if (ReadingOf(AFrame.Rows[I]) = lrBack) and
       (Trim(string(AFrame.Rows[I].CB)) = '') and
       (ReadingOf(AFrame.Rows[I - 1]) = lrFore) then
      AFrame.Rows[I].VC := AFrame.Rows[I - 1].VC;

  FInfo.Valid := True;
end;

procedure TLevellingAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I, LastRow: Integer;
begin
  ClearWarnings;
  FInfo := Default(TLevellingInfo);
  FInfo.BothWays := FBothWays;
  FInfo.SumBack := NaN;
  FInfo.Given := NaN;
  FInfo.Misclosure := NaN;
  FInfo.Limit := NaN;

  // Old results must not survive a failed run
  for I := 0 to AFrame.Count - 1 do
  begin
    AFrame.Rows[I].Vz := NaN;
    AFrame.Rows[I].Vy := NaN;
    AFrame.Rows[I].VC := NaN;
  end;

  if not CheckLayout(AFrame) then
    Exit;

  if FBothWays then
  begin
    CalculateBothWays(AFrame);
    Exit;
  end;

  LastRow := AFrame.Count - 1;
  FInfo.Closed := (Trim(string(AFrame.Rows[0].CB)) <> '') and
    (AFrame.Rows[0].CB = AFrame.Rows[LastRow].CB);
  FInfo.Open := not FInfo.Closed and IsNan(AFrame.Rows[LastRow].Z);

  SumRows(AFrame, 0, LastRow, FInfo.SumHeight, FInfo.TotalLength);
  if FInfo.TotalLength <= 0 then
  begin
    AddError('Součet délek záměr je nulový.');
    Exit;
  end;

  if FInfo.Open then
  begin
    AddWarning(Format('Konec pořadu %s nemá danou výšku, výšky jsou ' +
      'bez kontroly.', [Trim(string(AFrame.Rows[LastRow].CB))]));
    ChainHeights(AFrame, 0, LastRow, AFrame.Rows[0].Z);
  end
  else
  begin
    if FInfo.Closed then
      FInfo.Given := 0
    else
      FInfo.Given := AFrame.Rows[LastRow].Z - AFrame.Rows[0].Z;
    FInfo.Misclosure := FInfo.SumHeight - FInfo.Given;

    // One way against given heights, half of L in km
    FInfo.Limit := 0.020 * Sqrt(FInfo.TotalLength / 1000 / 2);
    if Abs(FInfo.Misclosure) > FInfo.Limit then
      AddWarning(Format('Odchylka %.3f m překračuje mezní odchylku ' +
        '%.3f m (20 mm·√(L/2), měření tam proti známým výškám).',
        [FInfo.Misclosure, FInfo.Limit]));

    DistributeCorrection(AFrame);
    ChainHeights(AFrame, 0, LastRow, AFrame.Rows[0].Z);
  end;

  FInfo.Valid := True;
end;

end.
