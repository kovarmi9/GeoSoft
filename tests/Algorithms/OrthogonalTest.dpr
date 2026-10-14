program OrthogonalTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmOrthogonal;

var
  P, K, D1, D2: TGeoRow;
  Frame: TGeoDataFrame;
  Alg: TOrthogonalMethodAlgorithm;
  I: Integer;
begin
  // P - start of the measuring line
  ClearGeoRow(P);
  P.Uloha := ULOHA_ORTOGONALNI;
  P.CB := '5210';
  P.X := 0;
  P.Y := 0;
  P.Xm := 0;              // chainage
  P.Ym := 0;              // offset

  // K - end of the measuring line, 8.485 m from P
  ClearGeoRow(K);
  K.Uloha := ULOHA_ORTOGONALNI;
  K.CB := '5200';
  K.X := 6;
  K.Y := 6;
  K.Xm := 8.485281374;
  K.Ym := 0;

  // Detail point 1 in the middle of the line
  ClearGeoRow(D1);
  D1.Uloha := ULOHA_ORTOGONALNI;
  D1.CB := '1';
  D1.Xm := 4.242640687;
  D1.Ym := 0;

  // Detail point 2 off the middle of the line
  ClearGeoRow(D2);
  D2.Uloha := ULOHA_ORTOGONALNI;
  D2.CB := '2';
  D2.Xm := 4.242640687;
  D2.Ym := 4.242640687;

  // P and K first, then the detail points
  Frame := TGeoDataFrame.Create([Uloha, CB, X, Y, Xm, Ym]);
  Alg := TOrthogonalMethodAlgorithm.Create;
  try
    try
      Frame.AddRow(P);
      Frame.AddRow(K);
      Frame.AddRow(D1);
      Frame.AddRow(D2);

      Alg.Calculate(Frame);

      Writeln(Format('Přímka: páska %.3f m, souřadnice %.3f m, rozdíl %.3f m',
        [Alg.Baseline.L, Alg.Baseline.Lg, Alg.Baseline.Diff]));
      Writeln('Varování: ', Alg.Warnings.Count);
      for I := 0 to Alg.Warnings.Count - 1 do
        Writeln('  ', Alg.Warnings[I]);
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
