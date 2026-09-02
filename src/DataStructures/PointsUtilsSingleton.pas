unit PointsUtilsSingleton;

interface

uses
  System.Generics.Collections, SysUtils, Classes, System.UITypes, Vcl.Dialogs, Point,
  CoordOrderState;

type
  TPointDictionary = class
  private
    class var FInstance: TPointDictionary;
    FPointDict: TDictionary<Int64, TPoint>;
    procedure CheckFileError(const FileName: string);

    function GetValues: TEnumerable<TPoint>;
  public
    constructor Create;
    destructor Destroy; override;

    class function GetInstance: TPointDictionary;

    // Point access
    procedure AddPoint(const APoint: TPoint); overload;
    procedure AddPoint(PointNumber: Int64; X, Y, Z: Double; Quality: Integer; const Description: string); overload;
    procedure AddPoint(PointNumber: Int64; X, Y: Double; Quality: Integer; const Description: string); overload;
    procedure AddOrUpdatePoint(const APoint: TPoint);
    procedure UpdatePoint(const APoint: TPoint);
    function GetPoint(const PointNumber: Int64): TPoint;
    procedure RemovePoint(const PointNumber: Int64);
    function GetPointCount: Integer;
    function PointExists(const PointNumber: Int64): Boolean;
    procedure Clear;

    // File import and export
    procedure ExportToTXT(const FileName: string);
    procedure ExportToCSV(const FileName: string);
    procedure ImportFromTXT(const FileName: string);
    procedure ImportFromCSV(const FileName: string);
    procedure ExportToBinary(const FileName: string);
    procedure ImportFromBinary(const FileName: string);

    /// <summary>Iterates all points.</summary>
     property Values: TEnumerable<TPoint> read GetValues;
  end;

implementation

constructor TPointDictionary.Create;
begin
  inherited Create;
  FPointDict := TDictionary<Int64, TPoint>.Create;
end;

destructor TPointDictionary.Destroy;
begin
  FPointDict.Free;
  inherited Destroy;
end;

class function TPointDictionary.GetInstance: TPointDictionary;
begin
  if not Assigned(FInstance) then
    FInstance := TPointDictionary.Create;
  Result := FInstance;
end;

procedure TPointDictionary.AddPoint(const APoint: TPoint);
begin
  if PointExists(APoint.PointNumber) then
    raise Exception.CreateFmt('Point with number %d already exists.', [APoint.PointNumber]);
  AddOrUpdatePoint(APoint);
end;

procedure TPointDictionary.AddPoint(PointNumber: Int64; X, Y, Z: Double; Quality: Integer; const Description: string);
begin
  AddPoint(TPoint.Create(PointNumber, X, Y, Z, Quality, Description));
end;

procedure TPointDictionary.AddPoint(PointNumber: Int64; X, Y: Double; Quality: Integer; const Description: string);
begin
  AddPoint(TPoint.Create(PointNumber, X, Y, 0.0, Quality, Description));  // 2D point, Z = 0
end;

procedure TPointDictionary.AddOrUpdatePoint(const APoint: TPoint);
begin
  FPointDict.AddOrSetValue(APoint.PointNumber, APoint);
end;

procedure TPointDictionary.UpdatePoint(const APoint: TPoint);
begin
  if not PointExists(APoint.PointNumber) then
    raise Exception.CreateFmt('Point with number %d not found for update.', [APoint.PointNumber]);
  AddOrUpdatePoint(APoint);
end;

function TPointDictionary.GetPoint(const PointNumber: Int64): TPoint;
begin
  if not FPointDict.TryGetValue(PointNumber, Result) then
    raise Exception.CreateFmt('Point with number %d not found.', [PointNumber]);
end;

procedure TPointDictionary.RemovePoint(const PointNumber: Int64);
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

function TPointDictionary.PointExists(const PointNumber: Int64): Boolean;
begin
  Result := FPointDict.ContainsKey(PointNumber);
end;

procedure TPointDictionary.Clear;
begin
  FPointDict.Clear;
end;

// File export
procedure TPointDictionary.ExportToTXT(const FileName: string);
var
  TXTFile: TextFile;
  Point: TPoint;
  C1, C2: Double;
begin
  AssignFile(TXTFile, FileName);
  Rewrite(TXTFile);
  try
    for Point in FPointDict.Values do
    begin
      CoordRead(Point, C1, C2);
      WriteLn(TXTFile, Format('%015d'#9'%.2f'#9'%.2f'#9'%.2f'#9'%d'#9'%s', [Point.PointNumber, C1, C2, Point.Z, Point.Quality, string(Point.Description)]));
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
  Imported, Updated: Integer;
begin
  CheckFileError(FileName);
  AssignFile(TXTFile, FileName);
  Reset(TXTFile);
  Imported := 0;
  Updated := 0;
  try
    while not Eof(TXTFile) do
    begin
      ReadLn(TXTFile, Line);
      with TStringList.Create do
      try
        Delimiter := #9;
        StrictDelimiter := True;
        DelimitedText := Line;
        if Count < 6 then
          Continue;
        Point.PointNumber := StrToInt64(Trim(Strings[0]));
        CoordWrite(Point, StrToFloat(Strings[1]), StrToFloat(Strings[2]));
        Point.Z := StrToFloat(Strings[3]);
        Point.Quality := StrToInt(Strings[4]);
        {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
        Point.Description := Strings[5];
        {$WARN IMPLICIT_STRING_CAST_LOSS ON}
        if PointExists(Point.PointNumber) then
          Inc(Updated);
        AddOrUpdatePoint(Point);
        Inc(Imported);
      finally
        Free;
      end;
    end;
  finally
    CloseFile(TXTFile);
  end;
  if Updated > 0 then
    MessageDlg(Format('Importováno %d bodů, z toho %d přepsáno.', [Imported, Updated]),
      mtInformation, [mbOK], 0)
  else
    MessageDlg(Format('Importováno %d bodů.', [Imported]),
      mtInformation, [mbOK], 0);
end;

procedure TPointDictionary.ExportToCSV(const FileName: string);
var
  CSVFile: TextFile;
  Point: TPoint;
  C1, C2: Double;
begin
  //CheckFileError(FileName); // Check file validity before writing
  AssignFile(CSVFile, FileName);
  Rewrite(CSVFile);
  try
    for Point in FPointDict.Values do
    begin
      CoordRead(Point, C1, C2);
      WriteLn(CSVFile, Format('%015d;%.2f;%.2f;%.2f;%d;%s', [Point.PointNumber, C1, C2, Point.Z, Point.Quality, string(Point.Description)]));
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
  Imported, Updated: Integer;
begin
  CheckFileError(FileName);
  AssignFile(CSVFile, FileName);
  Reset(CSVFile);
  Imported := 0;
  Updated := 0;
  try
    while not Eof(CSVFile) do
    begin
      ReadLn(CSVFile, Line);
      with TStringList.Create do
      try
        Delimiter := ';';
        StrictDelimiter := True;
        DelimitedText := Line;
        if Count < 6 then
          Continue;
        Point.PointNumber := StrToInt64(Trim(Strings[0]));
        CoordWrite(Point, StrToFloat(Strings[1]), StrToFloat(Strings[2]));
        Point.Z := StrToFloat(Strings[3]);
        Point.Quality := StrToInt(Strings[4]);
        {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
        Point.Description := Strings[5];
        {$WARN IMPLICIT_STRING_CAST_LOSS ON}
        if PointExists(Point.PointNumber) then
          Inc(Updated);
        AddOrUpdatePoint(Point);
        Inc(Imported);
      finally
        Free;
      end;
    end;
  finally
    CloseFile(CSVFile);
  end;
  if Updated > 0 then
    MessageDlg(Format('Importováno %d bodů, z toho %d přepsáno.', [Imported, Updated]),
      mtInformation, [mbOK], 0)
  else
    MessageDlg(Format('Importováno %d bodů.', [Imported]),
      mtInformation, [mbOK], 0);
end;

procedure TPointDictionary.ExportToBinary(const FileName: string);
var
  BinaryFile: TFileStream;
  Point: TPoint;
  Rec: TPoint;
begin
  //CheckFileError(FileName); // Check file validity before writing
  BinaryFile := TFileStream.Create(FileName, fmCreate);
  try
    for Point in FPointDict.Values do
    begin
      Rec := Point;
      if GCoordOrder = coYX then
        SwapXY(Rec);   // the first slot in the file carries the first coordinate
      BinaryFile.Write(Rec, SizeOf(Rec));
    end;
  finally
    BinaryFile.Free;
  end;
end;

procedure TPointDictionary.ImportFromBinary(const FileName: string);
var
  BinaryFile: TFileStream;
  Point: TPoint;
  Imported, Updated: Integer;
begin
  CheckFileError(FileName);
  BinaryFile := TFileStream.Create(FileName, fmOpenRead);
  Imported := 0;
  Updated := 0;
  try
    while BinaryFile.Position < BinaryFile.Size do
    begin
      BinaryFile.Read(Point, SizeOf(Point));
      if GCoordOrder = coYX then
        SwapXY(Point);
      if PointExists(Point.PointNumber) then
        Inc(Updated);
      AddOrUpdatePoint(Point);
      Inc(Imported);
    end;
  finally
    BinaryFile.Free;
  end;
  if Updated > 0 then
    MessageDlg(Format('Importováno %d bodů, z toho %d přepsáno.', [Imported, Updated]),
      mtInformation, [mbOK], 0)
  else
    MessageDlg(Format('Importováno %d bodů.', [Imported]),
      mtInformation, [mbOK], 0);
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

