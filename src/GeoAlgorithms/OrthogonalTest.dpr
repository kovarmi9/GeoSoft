program OrthogonalTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  GeoAlgorithmBase,
  GeoAlgorithmOrthogonal,
  Point,
  GeoAlgorithmTransformSimilarity in 'GeoAlgorithmTransformSimilarity.pas';

var
  DetailPoints, ResultPoints: TPointsArray;
  i: Integer;
  P, K: TPoint;
  Alg: TOrthogonalMethodAlgorithm;
begin
  try
    // Po��te�n� bod p��mky (P)
    P.PointNumber := 5210;
    P.X := 0;
    P.Y := 0;
    P.Z := 0.0;
    P.Quality := 1;
    P.Description := 'P';

    // Koncov� bod p��mky (K)
    K.PointNumber := 5200;
    K.X := 6;
    K.Y := 6;
    K.Z := 0.0;
    K.Quality := 1;
    K.Description := 'K';

    // Vytvo�en� instance algoritmu s body P a K
    Alg := TOrthogonalMethodAlgorithm.Create(P, K);
    try
      Alg.Scale := 1.0;

      SetLength(DetailPoints, 2);

      DetailPoints[0].PointNumber := 1;
      DetailPoints[0].X := 4.242640687; // stani�en�
      DetailPoints[0].Y := 0;           // kolmice
      DetailPoints[0].Z := 0.0;
      DetailPoints[0].Quality := 0;
      DetailPoints[0].Description := 'bod 1';

      DetailPoints[1].PointNumber := 2;
      DetailPoints[1].X := 4.242640687;
      DetailPoints[1].Y := 4.242640687;
      DetailPoints[1].Z := 0.0;
      DetailPoints[1].Quality := 0;
      DetailPoints[1].Description := 'bod 2';

      // V�po�et
      ResultPoints := Alg.Calculate(DetailPoints);

      Writeln('V�sledn� sou�adnice podrobn�ch bod�:');
      for i := 0 to High(ResultPoints) do
      begin
        Writeln(Format('Bod %d: X = %.3f, Y = %.3f, Z = %.3f, Popis: %s',
          [ResultPoints[i].PointNumber, ResultPoints[i].X, ResultPoints[i].Y,
           ResultPoints[i].Z, ResultPoints[i].Description]));
      end;
    finally
      Alg.Free;
    end;

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

