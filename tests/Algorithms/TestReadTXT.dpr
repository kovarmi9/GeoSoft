program TestReadTXT;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Point,
  PointsUtils;

var
  Dict: TPointDictionary;
  Point: TPoint;
  i: Integer;

begin
  try
    Writeln('Aktuální adresáø: ', GetCurrentDir);
    Dict := TPointDictionary.Create;
    try
      Writeln('Naèítám body...');
      Dict.ImportFromTXT('DetailPoints.txt');

      Writeln('Naètené body:');
      for i := 1 to 9999 do
      begin
        if Dict.PointExists(i) then
        begin
          Point := Dict.GetPoint(i);
          Writeln(Format('Bod %d: X = %.2f, Y = %.2f, Z = %.2f, Q = %d, Popis: %s',
            [Point.PointNumber, Point.X, Point.Y, Point.Z, Point.Quality, Point.Description]));
        end;
      end;
    finally
      Dict.Free;
    end;

    Writeln('Stiskni enter');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('Chyba: ', E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end.

