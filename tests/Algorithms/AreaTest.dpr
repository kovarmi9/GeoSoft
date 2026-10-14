program AreaTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmLHuilier;

var
  P1, P2, P3, P4: TGeoRow;
  Frame: TGeoDataFrame;
  Alg: TLHuilierAlgorithm;

// Prints the area and the warnings of the last run
procedure ShowResult(const ATitle: string);
var
  I: Integer;
begin
  Writeln(ATitle);
  Writeln(Format('  Plocha: %.2f m2', [Alg.Area]));
  for I := 0 to Alg.Warnings.Count - 1 do
    Writeln('  ', Alg.Warnings[I]);
end;

begin
  // Square 10 x 10 m, corners in clockwise order
  ClearGeoRow(P1);
  P1.Uloha := ULOHA_VYMERA;
  P1.CB := '1';
  P1.X := 0;
  P1.Y := 0;

  ClearGeoRow(P2);
  P2.Uloha := ULOHA_VYMERA;
  P2.CB := '2';
  P2.X := 0;
  P2.Y := 10;

  ClearGeoRow(P3);
  P3.Uloha := ULOHA_VYMERA;
  P3.CB := '3';
  P3.X := 10;
  P3.Y := 10;

  ClearGeoRow(P4);
  P4.Uloha := ULOHA_VYMERA;
  P4.CB := '4';
  P4.X := 10;
  P4.Y := 0;

  Frame := TGeoDataFrame.Create([Uloha, CB, X, Y]);
  Alg := TLHuilierAlgorithm.Create;
  try
    try
      // 1. The square, expected 100.00 m2
      Frame.AddRow(P1);
      Frame.AddRow(P2);
      Frame.AddRow(P3);
      Frame.AddRow(P4);
      Alg.Calculate(Frame);
      ShowResult('Čtverec 1-2-3-4 (očekáváno 100,00 m2):');

      // 2. The same square in the opposite order, the area stays
      Frame.ClearData;
      Frame.AddRow(P4);
      Frame.AddRow(P3);
      Frame.AddRow(P2);
      Frame.AddRow(P1);
      Alg.Calculate(Frame);
      ShowResult('Čtverec 4-3-2-1 (očekáváno 100,00 m2):');

      // 3. Two points are not a polygon, expected a warning
      Frame.ClearData;
      Frame.AddRow(P1);
      Frame.AddRow(P2);
      Alg.Calculate(Frame);
      ShowResult('Jen dva body (očekáváno varování):');

      Writeln;
      Writeln(Frame.Print);
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    Alg.Free;
    Frame.Free;
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.
