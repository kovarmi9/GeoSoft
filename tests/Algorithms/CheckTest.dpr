program CheckTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmCheckMeasurements;

var
  M1, M2, M3, M4: TGeoRow;
  Frame: TGeoDataFrame;
  Alg: TCheckMeasurementsAlgorithm;
  R: TCheckResult;
  I: Integer;
begin
  // 1. Points 1 (0, 0) and 2 (0, 10), measured 10,02 m, small difference
  ClearGeoRow(M1);
  M1.Uloha := ULOHA_KONTROLNI;
  M1.KK := 3;              // worse quality code of the pair
  M1.CB := '1';
  M1.X := 0;
  M1.Y := 0;
  M1.CBm := '2';          // second point
  M1.Xm := 0;
  M1.Ym := 10;
  M1.SH := 10.02;         // measured length [m]

  // 2. Points 2 (0, 10) and 3 (10, 10), measured 10,30 m, too much
  ClearGeoRow(M2);
  M2.Uloha := ULOHA_KONTROLNI;
  M2.KK := 3;
  M2.CB := '2';
  M2.X := 0;
  M2.Y := 10;
  M2.CBm := '3';
  M2.Xm := 10;
  M2.Ym := 10;
  M2.SH := 10.30;

  // 3. Points 1 and 3, not measured, only the computed length
  ClearGeoRow(M3);
  M3.Uloha := ULOHA_KONTROLNI;
  M3.KK := 3;
  M3.CB := '1';
  M3.X := 0;
  M3.Y := 0;
  M3.CBm := '3';
  M3.Xm := 10;
  M3.Ym := 10;

  // 4. The second point has no coordinates
  ClearGeoRow(M4);
  M4.Uloha := ULOHA_KONTROLNI;
  M4.KK := 3;
  M4.CB := '1';
  M4.X := 0;
  M4.Y := 0;
  M4.CBm := '9';
  M4.SH := 5;

  Frame := TGeoDataFrame.Create([Uloha, CB, X, Y, CBm, Xm, Ym, SH, SS]);
  Alg := TCheckMeasurementsAlgorithm.Create;
  try
    try
      Frame.AddRow(M1);
      Frame.AddRow(M2);
      Frame.AddRow(M3);
      Frame.AddRow(M4);

      Alg.Calculate(Frame);

      // One line per measurement, as the grid shows it
      for I := 0 to Frame.Count - 1 do
      begin
        R := TCheckMeasurementsAlgorithm.ResultOf(Frame.Rows[I], Alg.Scale);
        Write(Format('Oměrná %d (%s - %s): ', [I + 1,
          string(Frame.Rows[I].CB), string(Frame.Rows[I].CBm)]));
        if not R.Found then
          Writeln('chybí bod')
        else if not R.HasMeasured then
          Writeln(Format('vypočteno %.3f m, neměřeno', [R.Computed]))
        else
          Writeln(Format('vypočteno %.3f, měřeno %.3f, rozdíl %.3f, ' +
            'mez %.3f m, vyhovuje %s', [R.Computed, R.Measured, R.Diff,
            R.Tolerance, BoolToStr(R.Passed, True)]));
      end;

      Writeln('Varování: ', Alg.Warnings.Count);
      for I := 0 to Alg.Warnings.Count - 1 do
        Writeln('  ', Alg.Warnings[I]);

      // The counts the protocol writes under the table
      Writeln(Format('Měřených %d, nevyhovuje %d, neměřených %d, ' +
        'nespočítaných %d, bez Mxy %d, největší rozdíl %.3f m',
        [Alg.Info.Measured, Alg.Info.Failed, Alg.Info.ComputedOnly,
         Alg.Info.Skipped, Alg.Info.NoQuality, Alg.Info.MaxDiff]));

      // 5. Measurement 1 with the scale 0,998, the length goes in reduced
      Alg.Scale := 0.998;
      R := TCheckMeasurementsAlgorithm.ResultOf(Frame.Rows[0], Alg.Scale);
      Writeln(Format('Oměrná 1 s měřítkem 0,998: rozdíl %.3f, mez %.3f m',
        [R.Diff, R.Tolerance]));
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
