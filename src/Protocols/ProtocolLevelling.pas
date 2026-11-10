unit ProtocolLevelling;

// Protocol of the levelling, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmLevelling;

type
  TLevellingProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TLevellingAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, GeoRow;

const
  // Header and rows share one format
  READING_LINE = '%3s  %-18s  %7s  %7s  %7s  %7s  %9s  %7s  %10s  %s';

class procedure TLevellingProtocol.Write(AProt: TProtocol; ALines: TStrings;
  AFrame: TGeoDataFrame; AAlg: TLevellingAlgorithm; const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
  Verdict: string;

begin
  if AFrame.Count = 0 then
  begin
    ALines.Clear;
    Exit;
  end;
  AProt.Title(ALines, 'Technická nivelace');

  // 3. Measurements with the results, heights to the mm
  AProt.TableHeader(Format(READING_LINE, ['Č.', 'Číslo bodu', 'Vzad', 'Vpřed',
    'Bočně', 'Délka', 'Převýšení', 'Oprava', 'Výška', '']));
  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    AProt.Text(Format(READING_LINE, [ARows.Numbers[I], PointId(Row.CB),
      Num(Row.Xm, 3), Num(Row.Ym, 3), Num(Row.Zm, 3), Num(Row.SH, 2),
      Num(Row.M3, 3), Num(Row.M1, 3), Num(Row.M2, 3), ARows.Notes[I]]));
  end;
  AProt.Line;

  // 4. Checks, there and back or against the given heights
  if Abs(AAlg.Info.Misclosure) <= AAlg.Info.Limit then
    Verdict := 'vyhovuje'
  else
    Verdict := 'nevyhovuje';
  if AAlg.Info.Valid and AAlg.Info.BothWays then
  begin
    AProt.Text('Tam a zpět    Délka pořadu = ' +
      Num(AAlg.Info.TotalLength, 2) +
      '    Sestav = ' + IntToStr(AAlg.Info.SetupCount));
    AProt.Text('Suma převýšení tam = ' + Num(AAlg.Info.SumHeight, 3) +
      '    zpět = ' + Num(AAlg.Info.SumBack, 3));
    AProt.Text('Rozdíl tam a zpět = ' + Num(AAlg.Info.Misclosure, 3) +
      '    Mezní rozdíl = ' + Num(AAlg.Info.Limit, 3) + '    ' + Verdict);
    AProt.Text('Mezní rozdíl: vyhláška č. 31/1995 Sb., příloha, bod 4.9');
    AProt.Text('Výšky bodů měřených tam i zpět jsou průměrem');
  end
  else if AAlg.Info.Valid then
  begin
    AProt.Text('Délka pořadu = ' + Num(AAlg.Info.TotalLength, 2) +
      '    Sestav = ' + IntToStr(AAlg.Info.SetupCount) +
      '    Suma převýšení = ' + Num(AAlg.Info.SumHeight, 3));
    if AAlg.Info.Open then
      AProt.Text('Pořad bez kontroly, konec nemá danou výšku')
    else
    begin
      if AAlg.Info.Closed then
        AProt.Text('Uzavřený pořad    Má být = ' + Num(AAlg.Info.Given, 3))
      else
        AProt.Text('Připojený pořad    Má být = ' + Num(AAlg.Info.Given, 3));
      AProt.Text('Odchylka = ' + Num(AAlg.Info.Misclosure, 3) +
        '    Mezní odchylka = ' + Num(AAlg.Info.Limit, 3) + '    ' + Verdict);
      AProt.Text('Mezní odchylka 20 mm·√(L/2), měření tam proti známým výškám');
      AProt.Text('Oprava rovnoměrně na záměry vzad po celých mm, ' +
        'zbytek k větším čtením');
    end;
  end;

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
