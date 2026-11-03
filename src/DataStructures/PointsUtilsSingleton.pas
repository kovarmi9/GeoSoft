unit PointsUtilsSingleton;

interface

uses
  Winapi.Windows, System.Generics.Collections, System.SysUtils, System.Classes,
  Point, CoordOrderState, PointNumber;

type
  /// <summary>The one point list of the program.</summary>
  TPointDictionary = class
  private
    FPointDict: TDictionary<Int64, TPoint>;
    FModified: Boolean;
    FChangeCount: Integer;
    class var FInstance: TPointDictionary;
    function GetCount: Integer;
    // TXT and CSV, one point per line
    function ReadText(const FileName: string; ADelimiter: Char;
      APoints: TList<TPoint>): Integer;
    procedure ExportText(const FileName: string; ADelimiter: Char;
      APlaces: Integer);
    procedure CheckFileExists(const FileName: string);
    // .yxz keeps Y first
    class procedure SwapXY(var P: TPoint); static;
    // True when nothing changed
    class function SamePoint(const A, B: TPoint): Boolean; static;
    // Reads 1,5 and 1.5
    class function FileStrToFloat(const AText: string): Double; static;

  public
    /// <summary>Use GetInstance instead.</summary>
    constructor Create;
    destructor Destroy; override;

    /// <summary>True when the list is not saved.</summary>
    property Modified: Boolean read FModified write FModified;
    /// <summary>Grows with every change.</summary>
    property ChangeCount: Integer read FChangeCount;
    /// <summary>Number of points.</summary>
    property Count: Integer read GetCount;

    /// <summary>The one point list.</summary>
    class function GetInstance: TPointDictionary;

    // Point access
    /// <summary>Adds or overwrites a point. The only way to write.</summary>
    procedure AddOrUpdatePoint(const APoint: TPoint);
    /// <summary>Copy of the point, error if missing.</summary>
    function GetPoint(const PointNumber: Int64): TPoint;
    /// <summary>Deletes the point, error if missing.</summary>
    procedure RemovePoint(const PointNumber: Int64);
    /// <summary>True if the point is in the list.</summary>
    function PointExists(const PointNumber: Int64): Boolean;
    /// <summary>Deletes all points.</summary>
    procedure Clear;
    /// <summary>Point numbers, sorted.</summary>
    function SortedNumbers: TArray<Int64>;

    // Text files
    /// <summary>Saves a TXT file, APlaces decimals, sorted by number.</summary>
    procedure ExportToTXT(const FileName: string; APlaces: Integer);
    /// <summary>Saves a CSV file, APlaces decimals, sorted by number.</summary>
    procedure ExportToCSV(const FileName: string; APlaces: Integer);
    /// <summary>Reads a TXT file into APoints, returns bad lines.</summary>
    function ReadFromTXT(const FileName: string; APoints: TList<TPoint>): Integer;
    /// <summary>The same for a CSV file.</summary>
    function ReadFromCSV(const FileName: string; APoints: TList<TPoint>): Integer;

    // List files
    /// <summary>Saves a .yxz or .xyz file.</summary>
    procedure ExportToBinary(const FileName: string);
    /// <summary>Opens a .yxz or .xyz file, returns the point count.</summary>
    function LoadFromBinary(const FileName: string): Integer;
    /// <summary>Order by extension, others refused.</summary>
    class function FileOrder(const FileName: string): TCoordOrder;
  end;

implementation

var
  CommaFormat: TFormatSettings;   // files use a comma
  DotFormat: TFormatSettings;     // reading also accepts a dot

{ --- Singleton --- }

constructor TPointDictionary.Create;
begin
  if Assigned(FInstance) then
    raise Exception.Create('Seznam souřadnic může existovat jen jednou.');
  inherited Create;
  FPointDict := TDictionary<Int64, TPoint>.Create;
end;

destructor TPointDictionary.Destroy;
begin
  FPointDict.Free;
  inherited;
end;

class function TPointDictionary.GetInstance: TPointDictionary;
begin
  if not Assigned(FInstance) then
    FInstance := TPointDictionary.Create;
  Result := FInstance;
end;

{ --- Points --- }

procedure TPointDictionary.AddOrUpdatePoint(const APoint: TPoint);
var
  Old: TPoint;
begin
  if FPointDict.TryGetValue(APoint.PointNumber, Old) and
    SamePoint(Old, APoint) then
    Exit;
  FPointDict.AddOrSetValue(APoint.PointNumber, APoint);
  FModified := True;
  Inc(FChangeCount);
end;

function TPointDictionary.GetPoint(const PointNumber: Int64): TPoint;
begin
  if not FPointDict.TryGetValue(PointNumber, Result) then
    raise Exception.CreateFmt('Bod %s v seznamu není.',
      [TPointNumber.ToDisplay(PointNumber)]);
end;

procedure TPointDictionary.RemovePoint(const PointNumber: Int64);
begin
  if FPointDict.ContainsKey(PointNumber) then
  begin
    FPointDict.Remove(PointNumber);
    FModified := True;
    Inc(FChangeCount);
  end
  else
    raise Exception.CreateFmt('Bod %s v seznamu není.',
      [TPointNumber.ToDisplay(PointNumber)]);
end;

function TPointDictionary.GetCount: Integer;
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
  FModified := True;
  Inc(FChangeCount);
end;

function TPointDictionary.SortedNumbers: TArray<Int64>;
begin
  Result := FPointDict.Keys.ToArray;
  TArray.Sort<Int64>(Result);
end;

{ --- Text files --- }

procedure TPointDictionary.ExportToTXT(const FileName: string;
  APlaces: Integer);
begin
  ExportText(FileName, #9, APlaces);
end;

procedure TPointDictionary.ExportToCSV(const FileName: string;
  APlaces: Integer);
begin
  ExportText(FileName, ';', APlaces);
end;

function TPointDictionary.ReadFromTXT(const FileName: string; APoints: TList<TPoint>): Integer;
begin
  Result := ReadText(FileName, #9, APoints);
end;

function TPointDictionary.ReadFromCSV(const FileName: string; APoints: TList<TPoint>): Integer;
begin
  Result := ReadText(FileName, ';', APoints);
end;

procedure TPointDictionary.ExportText(const FileName: string;
  ADelimiter: Char; APlaces: Integer);
var
  TxtFile: TextFile;
  Key: Int64;
  P: TPoint;
  C1, C2: Double;
begin
  AssignFile(TxtFile, FileName);
  Rewrite(TxtFile);
  try
    for Key in SortedNumbers do
    begin
      P := FPointDict[Key];
      CoordRead(P, C1, C2);
      WriteLn(TxtFile,
        TPointNumber.ToText(P.PointNumber) + ADelimiter +
        FloatToStrF(C1, ffFixed, 18, APlaces, CommaFormat) + ADelimiter +
        FloatToStrF(C2, ffFixed, 18, APlaces, CommaFormat) + ADelimiter +
        FloatToStrF(P.Z, ffFixed, 18, APlaces, CommaFormat) + ADelimiter +
        IntToStr(P.Quality) + ADelimiter +
        string(P.Description));
    end;
  finally
    CloseFile(TxtFile);
  end;
end;

// Bad lines are counted
function TPointDictionary.ReadText(const FileName: string; ADelimiter: Char;
  APoints: TList<TPoint>): Integer;
var
  TxtFile: TextFile;
  Line: string;
  Fields: TStringList;
  Coords, P: TPoint;
begin
  CheckFileExists(FileName);
  Result := 0;

  AssignFile(TxtFile, FileName);
  Reset(TxtFile);
  Fields := TStringList.Create;
  try
    Fields.Delimiter := ADelimiter;
    Fields.StrictDelimiter := True;

    while not Eof(TxtFile) do
    begin
      ReadLn(TxtFile, Line);
      if Trim(Line) = '' then
        Continue;                    // empty lines are not counted

      Fields.DelimitedText := Line;
      if Fields.Count < 6 then
      begin
        Inc(Result);
        Continue;
      end;
      try
        // Y and X in file order
        CoordWrite(Coords, FileStrToFloat(Fields[1]),
          FileStrToFloat(Fields[2]));
        P := TPoint.Create(StrToInt64(Trim(Fields[0])), Coords.X, Coords.Y,
                           FileStrToFloat(Fields[3]), StrToInt(Trim(Fields[4])),
                           Fields[5]);
      except
        // Non-number marks bad line
        on EConvertError do
        begin
          Inc(Result);
          Continue;
        end;
      end;
      if P.PointNumber = 0 then      // invalid number
      begin
        Inc(Result);
        Continue;
      end;

      APoints.Add(P);
    end;
  finally
    Fields.Free;
    CloseFile(TxtFile);
  end;
end;

{ --- List files --- }

procedure TPointDictionary.ExportToBinary(const FileName: string);
var
  BinaryFile: File of TPoint;
  Key: Int64;
  Stored: TPoint;
  Order: TCoordOrder;
  TempName: string;
  Error: Cardinal;
begin
  Order := FileOrder(FileName);   // check before writing
  // Written aside first, a failed save keeps the old file
  TempName := FileName + '.tmp';
  AssignFile(BinaryFile, TempName);
  Rewrite(BinaryFile);
  try
    try
      // Sorted, every save the same file
      for Key in SortedNumbers do
      begin
        Stored := FPointDict[Key];
        if Order = coYX then
          SwapXY(Stored);
        Write(BinaryFile, Stored);
      end;
    finally
      CloseFile(BinaryFile);
    end;
  except
    DeleteFile(TempName);
    raise;
  end;
  // Only a whole file replaces the old one
  if not MoveFileEx(PChar(TempName), PChar(FileName),
    MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
  begin
    Error := GetLastError;    // DeleteFile would overwrite it
    DeleteFile(TempName);
    RaiseLastOSError(Error);
  end;
end;

// Read all first, a bad file keeps the list
function TPointDictionary.LoadFromBinary(const FileName: string): Integer;
var
  BinaryFile: File of TPoint;
  P: TPoint;
  Loaded: TList<TPoint>;
  Order: TCoordOrder;
  OldMode: Integer;
begin
  Order := FileOrder(FileName);
  CheckFileExists(FileName);
  Loaded := TList<TPoint>.Create;
  try
    AssignFile(BinaryFile, FileName);
    OldMode := FileMode;
    FileMode := fmOpenRead;      // Reset opens by the global FileMode
    try
      Reset(BinaryFile);
    finally
      FileMode := OldMode;
    end;
    try
      while not Eof(BinaryFile) do
      begin
        Read(BinaryFile, P);
        if Order = coYX then
          SwapXY(P);
        Loaded.Add(P);
      end;
    finally
      CloseFile(BinaryFile);
    end;

    Clear;
    for P in Loaded do
      AddOrUpdatePoint(P);
    FModified := False;
    Result := Loaded.Count;
  finally
    Loaded.Free;
  end;
end;

class function TPointDictionary.FileOrder(const FileName: string): TCoordOrder;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  if Ext = '.yxz' then
    Result := coYX
  else if Ext = '.xyz' then
    Result := coXY
  else
    raise Exception.Create('Neznámý formát seznamu, použijte .yxz nebo .xyz.');
end;

{ --- Helpers --- }

procedure TPointDictionary.CheckFileExists(const FileName: string);
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('Soubor %s neexistuje.', [FileName]);
end;

class procedure TPointDictionary.SwapXY(var P: TPoint);
var
  T: Double;
begin
  T   := P.X;
  P.X := P.Y;
  P.Y := T;
end;

class function TPointDictionary.SamePoint(const A, B: TPoint): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z) and
            (A.Quality = B.Quality) and (A.Description = B.Description);
end;

// ReadText counts EConvertError
class function TPointDictionary.FileStrToFloat(const AText: string): Double;
var
  S: string;
begin
  S := Trim(AText);
  if not TryStrToFloat(S, Result, CommaFormat) then
    Result := StrToFloat(S, DotFormat);
end;

initialization
  CommaFormat := FormatSettings;
  CommaFormat.DecimalSeparator  := ',';
  CommaFormat.ThousandSeparator := #0;

  DotFormat := CommaFormat;
  DotFormat.DecimalSeparator := '.';

finalization
  FreeAndNil(TPointDictionary.FInstance);

end.
