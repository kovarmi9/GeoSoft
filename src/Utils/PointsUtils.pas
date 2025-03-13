unit PointsUtils;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Point;

type
  TPointDictionary = class
  private
    FPointDict: TDictionary<Integer, TPoint>;
    procedure CheckFileError(const FileName: string);
  public
    // Initializes the dictionary
    constructor Create;
    // Frees the dictionary memory
    destructor Destroy; override;
    // Adds a point to the dictionary
    procedure AddPoint(const APoint: TPoint); overload;
    procedure AddPoint(PointNumber: Integer; X, Y, Z: Double; Quality: Integer; const Description: string); overload;
    procedure AddPoint(PointNumber: Integer; X, Y: Double; Quality: Integer; const Description: string); overload;
    // Updates an existing point in the dictionary
    procedure UpdatePoint(const APoint: TPoint);
    // Finds a point based on the point number
    function GetPoint(const PointNumber: Integer): TPoint;
    // Removes a point based on the point number
    procedure RemovePoint(const PointNumber: Integer);
    // Returns the number of points in the dictionary
    function GetPointCount: Integer;
    // Checks if a point exists in the dictionary
    function PointExists(const PointNumber: Integer): Boolean;
    // Iterates over all points in the dictionary
//    procedure IteratePoints(const Proc: TProc<TPoint>);
    // Exports points to a TXT file with tab as delimiter
    procedure ExportToTXT(const FileName: string);
    // Exports points to a CSV file
    procedure ExportToCSV(const FileName: string);
    // Imports points from a TXT file with tab as delimiter
    procedure ImportFromTXT(const FileName: string);
    // Imports points from a CSV file
    procedure ImportFromCSV(const FileName: string);
    // Exports points to a binary file
    procedure ExportToBinary(const FileName: string);
    // Imports points from a binary file
    procedure ImportFromBinary(const FileName: string);
  end;

implementation

constructor TPointDictionary.Create;
begin
  inherited Create;  // Call the ancestor's constructor
  FPointDict := TDictionary<Integer, TPoint>.Create;  // Initialize the dictionary
end;

destructor TPointDictionary.Destroy;
begin
  FPointDict.Free;  // Free the dictionary memory
  inherited Destroy;  // Call the ancestor's destructor
end;

procedure TPointDictionary.AddPoint(const APoint: TPoint);
begin
  // Validate and then add the point to the dictionary
  if not PointExists(APoint.PointNumber) then
    FPointDict.Add(APoint.PointNumber, APoint)
  else
    raise Exception.CreateFmt('Point with number %d already exists.', [APoint.PointNumber]);
end;

procedure TPointDictionary.AddPoint(PointNumber: Integer; X, Y, Z: Double; Quality: Integer; const Description: string);
begin
  AddPoint(TPoint.Create(PointNumber, X, Y, Z, Quality, Description));  // Add 3D point
end;

procedure TPointDictionary.AddPoint(PointNumber: Integer; X, Y: Double; Quality: Integer; const Description: string);
begin
  AddPoint(TPoint.Create(PointNumber, X, Y, 0.0, Quality, Description));  // Add 2D point
end;

procedure TPointDictionary.UpdatePoint(const APoint: TPoint);
begin
  if FPointDict.ContainsKey(APoint.PointNumber) then
    FPointDict[APoint.PointNumber] := APoint
  else
    raise Exception.CreateFmt('Point with number %d not found for update.', [APoint.PointNumber]);
end;

function TPointDictionary.GetPoint(const PointNumber: Integer): TPoint;
begin
  if not FPointDict.TryGetValue(PointNumber, Result) then
    raise Exception.CreateFmt('Point with number %d not found.', [PointNumber]);
end;

procedure TPointDictionary.RemovePoint(const PointNumber: Integer);
begin
  if FPointDict.ContainsKey(PointNumber) then
    FPointDict.Remove(PointNumber)
  else
    raise Exception.CreateFmt('Point with number %d not found for removal.', [PointNumber]);
end;

function TPointDictionary.GetPointCount: Integer;
begin
  Result := FPointDict.Count;
end;

function TPointDictionary.PointExists(const PointNumber: Integer): Boolean;
begin
  Result := FPointDict.ContainsKey(PointNumber);
end;

//procedure TPointDictionary.IteratePoints(const Proc: TProc<TPoint>);
//var
//  Point: TPoint;
//begin
//  for Point in FPointDict.Values do
//    Proc(Point);
//end;

procedure TPointDictionary.ExportToTXT(const FileName: string);
var
  TXTFile: TextFile;
  Point: TPoint;
begin
  // CheckFileError(FileName); // Check file validity before writing
  AssignFile(TXTFile, FileName);
  Rewrite(TXTFile);
  try
    for Point in FPointDict.Values do
    begin
      WriteLn(TXTFile, Format('%d'#9'%.2f'#9'%.2f'#9'%.2f'#9'%d'#9'%s', [Point.PointNumber, Point.X, Point.Y, Point.Z, Point.Quality, Point.Description]));
    end;
  finally
    CloseFile(TXTFile);
  end;
end;

procedure TPointDictionary.ImportFromTXT(const FileName: string);
var
  TXTFile: TextFile;
  Line: string;
  Point: TPoint;
begin
  CheckFileError(FileName); // Check file validity before reading
  AssignFile(TXTFile, FileName);
  Reset(TXTFile);
  try
    while not Eof(TXTFile) do
    begin
      ReadLn(TXTFile, Line);
      with TStringList.Create do
      try
        Delimiter := #9;  // Tab character
        DelimitedText := Line;
        Point.PointNumber := StrToInt(Strings[0]);
        Point.X := StrToFloat(Strings[1]);
        Point.Y := StrToFloat(Strings[2]);
        Point.Z := StrToFloat(Strings[3]);
        Point.Quality := StrToInt(Strings[4]);
        Point.Description := Strings[5];
        AddPoint(Point);
      finally
        Free;
      end;
    end;
  finally
    CloseFile(TXTFile);
  end;
end;

procedure TPointDictionary.ExportToCSV(const FileName: string);
var
  CSVFile: TextFile;
  Point: TPoint;
begin
  //CheckFileError(FileName); // Check file validity before writing
  AssignFile(CSVFile, FileName);
  Rewrite(CSVFile);
  try
    for Point in FPointDict.Values do
    begin
      WriteLn(CSVFile, Format('%d;%.2f;%.2f;%.2f;%d;%s', [Point.PointNumber, Point.X, Point.Y, Point.Z, Point.Quality, Point.Description]));
    end;
  finally
    CloseFile(CSVFile);
  end;
end;

procedure TPointDictionary.ImportFromCSV(const FileName: string);
var
  CSVFile: TextFile;
  Line: string;
  Point: TPoint;
begin
  CheckFileError(FileName); // Check file validity before reading
  AssignFile(CSVFile, FileName);
  Reset(CSVFile);
  try
    while not Eof(CSVFile) do
    begin
      ReadLn(CSVFile, Line);
      with TStringList.Create do
      try
        Delimiter := ';'; // Semicolon delimiter
        DelimitedText := Line;
        Point.PointNumber := StrToInt(Strings[0]);
        Point.X := StrToFloat(Strings[1]);
        Point.Y := StrToFloat(Strings[2]);
        Point.Z := StrToFloat(Strings[3]);
        Point.Quality := StrToInt(Strings[4]);
        Point.Description := Strings[5];
        AddPoint(Point);
      finally
        Free;
      end;
    end;
  finally
    CloseFile(CSVFile);
  end;
end;

procedure TPointDictionary.ExportToBinary(const FileName: string);
var
  BinaryFile: TFileStream;
  Point: TPoint;
begin
  //CheckFileError(FileName); // Check file validity before writing
  BinaryFile := TFileStream.Create(FileName, fmCreate);
  try
    for Point in FPointDict.Values do
    begin
      BinaryFile.Write(Point, SizeOf(Point));
    end;
  finally
    BinaryFile.Free;
  end;
end;

procedure TPointDictionary.ImportFromBinary(const FileName: string);
var
  BinaryFile: TFileStream;
  Point: TPoint;
begin
  CheckFileError(FileName); // Check file validity before reading
  BinaryFile := TFileStream.Create(FileName, fmOpenRead);
  try
    while BinaryFile.Position < BinaryFile.Size do
    begin
      BinaryFile.Read(Point, SizeOf(Point));
      AddPoint(Point);
    end;
  finally
    BinaryFile.Free;
  end;
end;

// Additional helper to check file errors
procedure TPointDictionary.CheckFileError(const FileName: string);
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('File %s does not exist.', [FileName]);
end;


end.

