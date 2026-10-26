unit GeoAlgorithmLevelling;

// Technical levelling, a line between known heights or a closed loop.

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
    Closed:      Boolean;   // ends on the start point
    SetupCount:  Integer;
    TotalLength: Double;    // back and fore sights [m]
    SumHeight:   Double;    // measured height differences
    Given:       Double;    // end height minus start height
    Misclosure:  Double;    // SumHeight - Given
    Limit:       Double;    // 20 mm √r, r in km
  end;

  TLevellingAlgorithm = class(TFrameAlgorithm)
  private
    FInfo: TLevellingInfo;
    function CheckLayout(AFrame: TGeoDataFrame): Boolean;
  public
    class function TaskCode: Integer; override;

    /// <summary>Xm back, Ym fore, Zm side reading, SH sight length.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    /// <summary>The reading filled in on the row.</summary>
    class function ReadingOf(const ARow: TGeoRow): TLevellingReading;

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

// A setup is back, side readings, fore. The ends need heights.
function TLevellingAlgorithm.CheckLayout(AFrame: TGeoDataFrame): Boolean;
var
  I: Integer;
  Reading, Previous: TLevellingReading;
  First, Last: TGeoRow;
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

  First := AFrame.Rows[0];
  Last := AFrame.Rows[AFrame.Count - 1];
  if IsNan(First.Z) then
    AddError(Format('Začátek pořadu %s nemá výšku.',
      [Trim(string(First.CB))]));
  if (First.CB <> Last.CB) and IsNan(Last.Z) then
    AddError(Format('Konec pořadu %s nemá výšku.',
      [Trim(string(Last.CB))]));

  Result := Warnings.Count = 0;
end;

procedure TLevellingAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I, LastRow: Integer;
  Back, BackLength, SetupLength, Difference, Correction, Height: Double;
begin
  ClearWarnings;
  FInfo := Default(TLevellingInfo);

  // Old results must not survive, only the ends keep their heights
  LastRow := AFrame.Count - 1;
  for I := 0 to LastRow do
  begin
    AFrame.Rows[I].Vz := NaN;
    AFrame.Rows[I].Vy := NaN;
    if (I > 0) and (I < LastRow) then
      AFrame.Rows[I].Z := NaN;
  end;

  if not CheckLayout(AFrame) then
    Exit;

  FInfo.Closed := (Trim(string(AFrame.Rows[0].CB)) <> '') and
    (AFrame.Rows[0].CB = AFrame.Rows[LastRow].CB);
  if FInfo.Closed then
    AFrame.Rows[LastRow].Z := AFrame.Rows[0].Z;

  // Sums of the line
  Back := 0;
  BackLength := 0;
  for I := 0 to LastRow do
    case ReadingOf(AFrame.Rows[I]) of
      lrBack:
        begin
          Back := AFrame.Rows[I].Xm;
          BackLength := AFrame.Rows[I].SH;
        end;
      lrFore:
        begin
          FInfo.SumHeight := FInfo.SumHeight + Back - AFrame.Rows[I].Ym;
          FInfo.TotalLength := FInfo.TotalLength + BackLength +
            AFrame.Rows[I].SH;
          Inc(FInfo.SetupCount);
        end;
    end;

  if FInfo.TotalLength <= 0 then
  begin
    AddError('Součet délek záměr je nulový.');
    Exit;
  end;

  if FInfo.Closed then
    FInfo.Given := 0
  else
    FInfo.Given := AFrame.Rows[LastRow].Z - AFrame.Rows[0].Z;
  FInfo.Misclosure := FInfo.SumHeight - FInfo.Given;

  // Annex 4.9 of decree 31/1995, r in km
  FInfo.Limit := 0.020 * Sqrt(FInfo.TotalLength / 1000);
  if Abs(FInfo.Misclosure) > FInfo.Limit then
    AddWarning(Format('Odchylka %.3f m překračuje mezní odchylku %.3f m - ' +
      'příloha, bod 4.9 vyhlášky 31/1995 Sb.',
      [FInfo.Misclosure, FInfo.Limit]));

  // Heights, the correction goes by the length of the setup
  Height := AFrame.Rows[0].Z;
  for I := 0 to LastRow do
    case ReadingOf(AFrame.Rows[I]) of
      lrBack:
        begin
          Back := AFrame.Rows[I].Xm;
          BackLength := AFrame.Rows[I].SH;
          AFrame.Rows[I].Z := Height;
        end;
      lrSide:
        begin
          // From the instrument horizon, no correction
          AFrame.Rows[I].Vz := Back - AFrame.Rows[I].Zm;
          AFrame.Rows[I].Z := Height + AFrame.Rows[I].Vz;
        end;
      lrFore:
        begin
          SetupLength := BackLength + AFrame.Rows[I].SH;
          Difference := Back - AFrame.Rows[I].Ym;
          Correction := -FInfo.Misclosure * SetupLength / FInfo.TotalLength;
          AFrame.Rows[I].Vz := Difference;
          AFrame.Rows[I].Vy := Correction;
          Height := Height + Difference + Correction;
          if I < LastRow then
            AFrame.Rows[I].Z := Height;
        end;
    end;

  FInfo.Valid := True;
end;

end.
