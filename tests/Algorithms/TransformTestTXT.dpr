program TransformTestTXT;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Math,
  Point,
  PointsUtils,
  GeoAlgorithmBase,
  GeoAlgorithmTransformBase,
  GeoAlgorithmTransformSimilarity,
  System.Generics.Collections,
  GeoAlgorithmTransformCongruent,
  GeoAlgorithmTransformAffine;

function ConvertDictToArray(Dict: TPointDictionary): TPointsArray;
var
  i, Count, Num: Integer;
  TempList: TList<TPoint>;
  Point: TPoint;
begin
  TempList := TList<TPoint>.Create;
  try
    for Num := 1 to 9999 do
      if Dict.PointExists(Num) then
        TempList.Add(Dict.GetPoint(Num));

    Count := TempList.Count;
    SetLength(Result, Count);
    for i := 0 to Count - 1 do
      Result[i] := TempList[i];
  finally
    TempList.Free;
  end;
end;

var
  LocalDict, GlobalDict, DetailDict: TPointDictionary;
  LocalPoints, GlobalPoints, DetailPoints, ResultPoints: TPointsArray;
  Transform: TSimilarityTransformation;
  //Transform: TCongruentTransformation;
  //Transform: TAffineTransformation;
  i: Integer;

begin
  try
    Writeln('Aktuální adresáø: ', GetCurrentDir);

    LocalDict := TPointDictionary.Create;
    GlobalDict := TPointDictionary.Create;
    DetailDict := TPointDictionary.Create;

    try
      Writeln('Naèítám body...');
      LocalDict.ImportFromTXT('LocalPoints.txt');
      GlobalDict.ImportFromTXT('GlobalPoints.txt');
      DetailDict.ImportFromTXT('DetailPoints.txt');

      LocalPoints := ConvertDictToArray(LocalDict);
      GlobalPoints := ConvertDictToArray(GlobalDict);
      DetailPoints := ConvertDictToArray(DetailDict);

      Transform := TSimilarityTransformation.Create;
      //Transform := TCongruentTransformation.Create;
      //Transform := TAffineTransformation.Create;
      try
        Transform.ComputeParametersFromPoints(LocalPoints, GlobalPoints);
        ResultPoints := Transform.Calculate(DetailPoints);

        Writeln('Transformované body:');
        for i := 0 to High(ResultPoints) do
          Writeln(Format('Bod %d: X = %.3f, Y = %.3f, Popis: %s',
            [ResultPoints[i].PointNumber,
             ResultPoints[i].X,
             ResultPoints[i].Y,
             ResultPoints[i].Description]));

        Writeln(Format(#13#10'Transf. parametry: q = %.8f, omega = %.4f, X0 = %.4f, Y0 = %.4f',
          [Transform.Q, Transform.Omega*200/pi, Transform.X0, Transform.Y0]));
        //Writeln(Format(#13#10'Transf. parametry: q_X = %.8f, q_Y = %.8f, omega_X = %.4f, omega_Y = %.4f, X0 = %.4f, Y0 = %.4f',
  //[Transform.QX, Transform.QY, Transform.OmegaX * 200 / Pi, Transform.OmegaY * 200 / Pi, Transform.X0, Transform.Y0]));
      finally
        Transform.Free;
      end;

    finally
      LocalDict.Free;
      GlobalDict.Free;
      DetailDict.Free;
    end;

    Writeln('Hotovo. Stiskni Enter pro ukonèení.');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('Chyba: ', E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end.

