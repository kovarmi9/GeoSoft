program TransformTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Math,
  Point,
  GeoAlgorithmBase,
  GeoAlgorithmTransformBase,
  GeoAlgorithmTransformSimilarity;

var
  LocalPoints, GlobalPoints, DetailPoints, ResultPoints: TPointsArray;
  Transform: TSimilarityTransformation;
  i: Integer;
begin
  try
    SetLength(LocalPoints, 10);
    SetLength(GlobalPoints, 10);

    // místní
    LocalPoints[0] := TPoint.Create(1, 109.73193, 35.709, 0, 0, '');
    LocalPoints[1] := TPoint.Create(2, 186.36054, 29.012, 0, 0, '');
    LocalPoints[2] := TPoint.Create(3, 259.80355, 76.883, 0, 0, '');
    LocalPoints[3] := TPoint.Create(4, 265.67724, 127.580, 0, 0, '');
    LocalPoints[4] := TPoint.Create(5, 268.88743, 207.587, 0, 0, '');
    LocalPoints[5] := TPoint.Create(6, 293.58177, 93.374, 0, 0, '');
    LocalPoints[6] := TPoint.Create(7, 340.26969, 161.907, 0, 0, '');
    LocalPoints[7] := TPoint.Create(8, 374.49961, 136.955, 0, 0, '');
    LocalPoints[8] := TPoint.Create(9, 48.44371, 93.061, 0, 0, '');
    LocalPoints[9] := TPoint.Create(10, 134.53295, 214.158, 0, 0, '');

    // DKM
    GlobalPoints[0] := TPoint.Create(1, 1040844.80, 744570.46, 0, 0, '');
    GlobalPoints[1] := TPoint.Create(2, 1040875.84, 744590.90, 0, 0, '');
    GlobalPoints[2] := TPoint.Create(3, 1040913.49, 744650.26, 0, 0, '');
    GlobalPoints[3] := TPoint.Create(4, 1040947.53, 744688.93, 0, 0, '');
    GlobalPoints[4] := TPoint.Create(5, 1041001.15, 744748.80, 0, 0, '');
    GlobalPoints[5] := TPoint.Create(6, 1040889.08, 744690.84, 0, 0, '');
    GlobalPoints[6] := TPoint.Create(7, 1040801.31, 744759.78, 0, 0, '');
    GlobalPoints[7] := TPoint.Create(8, 1040747.83, 744696.11, 0, 0, '');
    GlobalPoints[8] := TPoint.Create(9, 1040766.64, 744566.08, 0, 0, '');
    GlobalPoints[9] := TPoint.Create(10, 1040897.85, 744396.73, 0, 0, '');

    // Podrobné body
    SetLength(DetailPoints, 7);
    DetailPoints[0] := TPoint.Create(100, 38.84350, 11.663, 0, 0, '100');
    DetailPoints[1] := TPoint.Create(101, 27.52856, 11.016, 0, 0, '101');
    DetailPoints[2] := TPoint.Create(102, 7.71597, 35.648, 0, 0, '102');
    DetailPoints[3] := TPoint.Create(103, 3.71983, 67.094, 0, 0, '103');
    DetailPoints[4] := TPoint.Create(104, 12.91883, 68.434, 0, 0, '104');
    DetailPoints[5] := TPoint.Create(105, 26.65925, 72.975, 0, 0, '105');
    DetailPoints[6] := TPoint.Create(106, 28.06989, 44.885, 0, 0, '106');

    // Výpoèet transformace
    Transform := TSimilarityTransformation.Create;
    try
      Transform.ComputeParametersFromPoints(LocalPoints, GlobalPoints);
      ResultPoints := Transform.Calculate(DetailPoints);

      Writeln('Transformované body:');
      for i := 0 to High(ResultPoints) do
      begin
        Writeln(Format('Bod %d: X = %.3f, Y = %.3f, Popis: %s',
          [ResultPoints[i].PointNumber,
           ResultPoints[i].X,
           ResultPoints[i].Y,
           ResultPoints[i].Description]));
      end;

      Writeln(Format('\nTransf. parametry: q = %.8f, X0 = %.4f, Y0 = %.4f',
        [Transform.Q, Transform.X0, Transform.Y0]));
    finally
      Transform.Free;
    end;

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
