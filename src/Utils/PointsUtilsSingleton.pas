unit PointsUtilsSingleton;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Point;

type
  TPointDictionary = class
  private
    class var FInstance: TPointDictionary;  // Statická instance
    FPointDict: TDictionary<Integer, TPoint>;  // Slovník pro body
    procedure CheckFileError(const FileName: string);

    function GetValues: TEnumerable<TPoint>;
  public
    // Konstruktor a destruktor
    constructor Create;
    destructor Destroy; override;

    // Statická metoda pro získání jediné instance
    class function GetInstance: TPointDictionary;

    // Metody pro manipulaci s body
    procedure AddPoint(const APoint: TPoint); overload;
    procedure AddPoint(PointNumber: Integer; X, Y, Z: Double; Quality: Integer; const Description: string); overload;
    procedure AddPoint(PointNumber: Integer; X, Y: Double; Quality: Integer; const Description: string); overload;
    procedure UpdatePoint(const APoint: TPoint);
    function GetPoint(const PointNumber: Integer): TPoint;
    procedure RemovePoint(const PointNumber: Integer);
    function GetPointCount: Integer;
    function PointExists(const PointNumber: Integer): Boolean;

    // Exportní a importní metody pro soubory
    procedure ExportToTXT(const FileName: string);
    procedure ExportToCSV(const FileName: string);
    procedure ImportFromTXT(const FileName: string);
    procedure ImportFromCSV(const FileName: string);
    procedure ExportToBinary(const FileName: string);
    procedure ImportFromBinary(const FileName: string);

    /// <summary>Iterátor pøes všechny body ve slovníku</summary>
     property Values: TEnumerable<TPoint> read GetValues;
  end;

implementation

constructor TPointDictionary.Create;
begin
  inherited Create;
  FPointDict := TDictionary<Integer, TPoint>.Create;  // Inicializace slovníku
end;

destructor TPointDictionary.Destroy;
begin
  FPointDict.Free;
  inherited Destroy;
end;

// Singleton - získání jediné instance
class function TPointDictionary.GetInstance: TPointDictionary;
begin
  if not Assigned(FInstance) then
    FInstance := TPointDictionary.Create;
  Result := FInstance;
end;

procedure TPointDictionary.AddPoint(const APoint: TPoint);
begin
  if not PointExists(APoint.PointNumber) then
    FPointDict.Add(APoint.PointNumber, APoint)
  else
    raise Exception.CreateFmt('Point with number %d already exists.', [APoint.PointNumber]);
end;

procedure TPointDictionary.AddPoint(PointNumber: Integer; X, Y, Z: Double; Quality: Integer; const Description: string);
begin
  AddPoint(TPoint.Create(PointNumber, X, Y, Z, Quality, Description));
end;

procedure TPointDictionary.AddPoint(PointNumber: Integer; X, Y: Double; Quality: Integer; const Description: string);
begin
  AddPoint(TPoint.Create(PointNumber, X, Y, 0.0, Quality, Description));  // Pøidání 2D bodu
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

// Exportní metody pro soubory (TXT, CSV, Binary atd.)
procedure TPointDictionary.ExportToTXT(const FileName: string);
var
  TXTFile: TextFile;
  Point: TPoint;
begin
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

// Public iterator support
function TPointDictionary.GetValues: TEnumerable<TPoint>;
begin
  Result := FPointDict.Values;
end;

end.

