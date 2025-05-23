program GeoSoftConsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Point,
  PointsUtils,
  ValidationUtils;

var
  PointDict: TPointDictionary;
  Point: TPoint;

begin
  try
    // Create a point
    Point := TPoint.Create(1, 100.0, 200.0, 300.0, 1, 'Sample Point');
    //Point := TPoint.Create(-9, -8, 200.0, 1, 'Sample Point2');
    //Point := TPoint.Create(3, 100.0, 200.0, 1, 'Sample Point3');

    // Create the point dictionary
    PointDict := TPointDictionary.Create;

    try
      // Add the point to the dictionary
      PointDict.AddPoint(1, 100.0, 200.0, 300.0, 1, 'Sample Point');
      PointDict.AddPoint(-9, -8, 200.0, 1, 'Sample Point2');
      PointDict.AddPoint(3, 100.0, 200.0, 1, 'Sample Point3');

      // PointDict.ImportFromTXT('points98.txt');

      // Export the dictionary to a CSV file
      PointDict.ExportToTXT('points.txt');
      PointDict.ExportToCSV('points.csv');
      PointDict.ExportToBinary('points.bin');

      Writeln('Point added and exported successfully.');
    finally
      // Free the point dictionary
      PointDict.Free;
    end;

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
