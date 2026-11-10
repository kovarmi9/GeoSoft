unit ProtocolCheckMeasurements;

// Protocol of the check measurements, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmCheckMeasurements;

type
  TCheckMeasurementsProtocol = class
  private
    class procedure AddPointNumber(var APointNumbers: TArray<Int64>;
      APointNumber: Int64);
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TCheckMeasurementsAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, GeoRow, Point, PointDictionary;

const
  // Header and rows share one format
  USED_LINE  = '%3s  %-18s  %s  %8s';
  CHECK_LINE = '%3s  %-18s  %-18s  %8s  %12s  %8s  %8s  %s';

class procedure TCheckMeasurementsProtocol.Write(AProt: TProtocol;
  ALines: TStrings; AFrame: TGeoDataFrame; AAlg: TCheckMeasurementsAlgorithm;
  const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
  Check: TCheckResult;
  ListPoint: Point.TPoint;
  Dictionary: TPointDictionary;
  PointNumbers: TArray<Int64>;
  Note: string;
begin
  AProt.Title(ALines, 'Kontrolní oměrné');

  // 1. Settings of the run
  AProt.Text('Měřítko délek = ' + Num(AAlg.Scale, 7));

  // 2. Given points, as the list has them
  Dictionary := TPointDictionary.GetInstance;
  PointNumbers := nil;
  for I := 0 to AFrame.Count - 1 do
  begin
    AddPointNumber(PointNumbers, AFrame.Rows[I].CB);
    AddPointNumber(PointNumbers, AFrame.Rows[I].CBm);
  end;

  AProt.Section('POUŽITÉ BODY');
  AProt.TableHeader(Format(USED_LINE, ['Č.', 'Číslo bodu', CoordCaption, 'Z']));
  for I := 0 to High(PointNumbers) do
    if Dictionary.PointExists(PointNumbers[I]) then
    begin
      ListPoint := Dictionary.GetPoint(PointNumbers[I]);
      AProt.Text(Format(USED_LINE, [IntToStr(I + 1), PointId(PointNumbers[I]),
        CoordPair(ListPoint), Num(ListPoint.Z)]));
    end
    else
      AProt.Text(Format(USED_LINE, [IntToStr(I + 1), PointId(PointNumbers[I]),
        '*** bod není v seznamu souřadnic ***', '']));
  AProt.Line;

  // 4. Checks, every measurement against its limit
  AProt.Section('OMĚRNÉ MÍRY');
  AProt.TableHeader(Format(CHECK_LINE, ['Č.', 'Z bodu', 'Na bod', 'Měřená',
    'Ze souřadnic', 'Rozdíl', 'Mezní', '']));
  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    Check := TCheckMeasurementsAlgorithm.ResultOf(Row, AAlg.Scale);

    if not Check.Found then
      AProt.Text(Format(CHECK_LINE, [ARows.Numbers[I], PointId(Row.CB),
        PointId(Row.CBm), '', '', '', '',
        '*** nelze spočítat, chybí bod ***']))
    else if Check.HasMeasured then
      AProt.Text(Format(CHECK_LINE, [ARows.Numbers[I], PointId(Row.CB),
        PointId(Row.CBm), Num(Check.Measured), Num(Check.Computed),
        Num(Check.Diff), Num(Check.Tolerance),
        TCheckMeasurementsAlgorithm.Verdict(Check)]))
    else
      // KatV annex 17.11 - a value that was not measured goes in brackets
      AProt.Text(Format(CHECK_LINE, [ARows.Numbers[I], PointId(Row.CB),
        PointId(Row.CBm), '', '(' + Num(Check.Computed) + ')', '', '',
        'neměřeno']));

    Note := string(Row.Popis);
    if Note <> '' then
      AProt.Text('      Poznámka: ' + Note);
  end;
  AProt.Line;

  AProt.Text('Měřených oměrných: ' + IntToStr(AAlg.Info.Measured) +
    '    Nevyhovuje: ' + IntToStr(AAlg.Info.Failed) +
    '    Největší rozdíl: ' + Num(AAlg.Info.MaxDiff));
  AProt.Text(LengthLimitSource);
  if AAlg.Info.ComputedOnly > 0 then
    AProt.Text('Neměřených, uvedených ze souřadnic v závorkách: ' +
      IntToStr(AAlg.Info.ComputedOnly));
  if AAlg.Info.Skipped > 0 then
    AProt.Text('Nespočítaných oměrných (chybí bod v seznamu): ' +
      IntToStr(AAlg.Info.Skipped));
  if AAlg.Info.NoQuality > 0 then
    AProt.Text('Bez mezního rozdílu (' + NoMxy + '): ' +
      IntToStr(AAlg.Info.NoQuality));

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

// Every point of the job once, in order of first use
class procedure TCheckMeasurementsProtocol.AddPointNumber(
  var APointNumbers: TArray<Int64>; APointNumber: Int64);
var
  I, Count: Integer;
begin
  for I := 0 to High(APointNumbers) do
    if APointNumbers[I] = APointNumber then
      Exit;
  Count := Length(APointNumbers);
  SetLength(APointNumbers, Count + 1);
  APointNumbers[Count] := APointNumber;
end;

end.
