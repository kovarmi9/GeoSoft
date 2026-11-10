program CheckTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmCheckMeasurements;

var
  Row1, Row2, Row3, Row4: TGeoRow;
  Frame: TGeoDataFrame;
  Alg: TCheckMeasurementsAlgorithm;
  R: TCheckResult;
  I: Integer;
begin
  // 1. Points 1 (0, 0) and 2 (0, 10), measured 10,02 m, small difference
  ClearGeoRow(Row1);
  Row1.KK := 3;            // worse quality code of the pair
  Row1.CB := 1;
  Row1.X := 0;
  Row1.Y := 0;
  Row1.CBm := 2;        // second point
  Row1.Xm := 0;
  Row1.Ym := 10;
  Row1.SH := 10.02;       // measured length [m]

  // 2. Points 2 (0, 10) and 3 (10, 10), measured 10,30 m, too much
  ClearGeoRow(Row2);
  Row2.KK := 3;
  Row2.CB := 2;
  Row2.X := 0;
  Row2.Y := 10;
  Row2.CBm := 3;
  Row2.Xm := 10;
  Row2.Ym := 10;
  Row2.SH := 10.30;

  // 3. Points 1 and 3, not measured, only the computed length
  ClearGeoRow(Row3);
  Row3.KK := 3;
  Row3.CB := 1;
  Row3.X := 0;
  Row3.Y := 0;
  Row3.CBm := 3;
  Row3.Xm := 10;
  Row3.Ym := 10;

  // 4. The second point has no coordinates
  ClearGeoRow(Row4);
  Row4.KK := 3;
  Row4.CB := 1;
  Row4.X := 0;
  Row4.Y := 0;
  Row4.CBm := 9;
  Row4.SH := 5;

  Frame := TGeoDataFrame.Create([CB, X, Y, CBm, Xm, Ym, SH, M1]);
  Alg := TCheckMeasurementsAlgorithm.Create;
  try
    try
      Frame.AddRow(Row1);
      Frame.AddRow(Row2);
      Frame.AddRow(Row3);
      Frame.AddRow(Row4);

      Alg.Calculate(Frame);

      // One line per measurement, as the grid shows it
      for I := 0 to Frame.Count - 1 do
      begin
        R := TCheckMeasurementsAlgorithm.ResultOf(Frame.Rows[I], Alg.Scale);
        Write(Format('Oměrná %d (%s - %s): ', [I + 1,
          IntToStr(Frame.Rows[I].CB), IntToStr(Frame.Rows[I].CBm)]));
        if not R.Found then
          Writeln('chybí bod')
        else if not R.HasMeasured then
          Writeln(Format('vypočteno %.3f m, neměřeno', [R.Computed]))
        else
          Writeln(Format('vypočteno %.3f, měřeno %.3f, rozdíl %.3f, ' +
            'mez %.3f m, vyhovuje %s', [R.Computed, R.Measured, R.Diff,
            R.Tolerance, BoolToStr(R.Passed, True)]));
      end;

      Writeln('Varování: ', Alg.Errors.Count + Alg.Warnings.Count);
      for I := 0 to Alg.Errors.Count - 1 do
        Writeln('  ', Alg.Errors[I]);
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
