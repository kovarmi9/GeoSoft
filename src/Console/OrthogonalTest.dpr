program OrthogonalTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  GeoAlgorithmOrthogonal,
  GeoAlgorithmBase,
  Point;

var
  DetailPoints, ResultPoints: TPointsArray;
  i: Integer;
  P, K: TPoint;
begin
  try
    // P - poèáteèní bod mìøické pøímky
    P.PointNumber := 5210;
    P.X := 0;
    P.Y := 0;
    P.Z := 0.0;
    P.Quality := 1;
    P.Description := 'P';

    // K – koncový bod mìøické pøímky
    K.PointNumber := 5200;
    K.X := 48.75;
    K.Y := 0;
    K.Z := 0.0;
    K.Quality := 1;
    K.Description := 'K';

    // Nastavení základních bodù u algoritmu
    TOrthogonalMethodAlgorithm.BasePoint := P;
    TOrthogonalMethodAlgorithm.EndPoint := K;
    // Mìøítko zkreslení
    TAlgorithm.Scale := 1.0;

    SetLength(DetailPoints, 4);

    DetailPoints[0].PointNumber := 17;
    DetailPoints[0].X := -3.54;  // stanièení
    DetailPoints[0].Y := 2.18;   // kolmice
    DetailPoints[0].Z := 0.0;
    DetailPoints[0].Quality := 0;
    DetailPoints[0].Description := 'bod 1';

    DetailPoints[1].PointNumber := 18;
    DetailPoints[1].X := 5.14;
    DetailPoints[1].Y := -2.35;
    DetailPoints[1].Z := 0.0;
    DetailPoints[1].Quality := 0;
    DetailPoints[1].Description := 'bod 2';

    DetailPoints[2].PointNumber := 19;
    DetailPoints[2].X := 12.37;
    DetailPoints[2].Y := -1.15;
    DetailPoints[2].Z := 0.0;
    DetailPoints[2].Quality := 0;
    DetailPoints[2].Description := 'bod 3';

    DetailPoints[3].PointNumber := 20;
    DetailPoints[3].X := 15.50;
    DetailPoints[3].Y := -2.78;
    DetailPoints[3].Z := 0.0;
    DetailPoints[3].Quality := 0;
    DetailPoints[3].Description := 'bod 4';

    ResultPoints := TOrthogonalMethodAlgorithm.Calculate(DetailPoints);

    Writeln('Výsledné souøadnice detailních bodù:');
    for i := 0 to High(ResultPoints) do
    begin
      Writeln(Format('Bod %d: X = %.3f, Y = %.3f, Z = %.3f, Popis: %s',
        [ResultPoints[i].PointNumber, ResultPoints[i].X, ResultPoints[i].Y,
         ResultPoints[i].Z, ResultPoints[i].Description]));
    end;

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

