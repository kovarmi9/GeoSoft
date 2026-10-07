unit PointsUtilsSingleton;

interface

uses
  Winapi.Windows, System.Generics.Collections, System.SysUtils, System.Classes,
  Vcl.Forms, Point, CoordOrderState;

type
  /// <summary>
  /// The one point list. The form asks before overwriting.
  /// </summary>
  TPointDictionary = class
  private
    FPointDict: TDictionary<Int64, TPoint>;
    FModified: Boolean;
    FChangeCount: Integer;
    class var FInstance: TPointDictionary;
    procedure CheckFileError(const FileName: string);
    procedure ReportImport(AImported, AUpdated, ASkipped: Integer);
    // .yxz keeps Y first
    class procedure SwapXY(var P: TPoint); static;
    // True when nothing changed
    class function SamePoint(const A, B: TPoint): Boolean; static;
    // Reads 1,5 and 1.5
    class function FileStrToFloat(const AText: string): Double; static;
    // TXT and CSV, one point per line
    procedure ImportText(const FileName: string; ADelimiter: Char);
    procedure ExportText(const FileName: string; ADelimiter: Char);

    function GetValues: TEnumerable<TPoint>;
  public
    /// <summary>Use GetInstance instead.</summary>
    constructor Create;
    destructor Destroy; override;

    /// <summary>True when the list is not saved.</summary>
    property Modified: Boolean read FModified write FModified;
    /// <summary>Grows with every change.</summary>
    property ChangeCount: Integer read FChangeCount;

    /// <summary>The one point list.</summary>
    class function GetInstance: TPointDictionary;

    // Point access
    /// <summary>Adds or overwrites a point. The only way to write.</summary>
    procedure AddOrUpdatePoint(const APoint: TPoint);
    /// <summary>Copy of the point, error if missing.</summary>
    function GetPoint(const PointNumber: Int64): TPoint;
    /// <summary>Deletes the point, error if missing.</summary>
    procedure RemovePoint(const PointNumber: Int64);
    /// <summary>Number of points.</summary>
    function GetPointCount: Integer;
    /// <summary>True if the point is in the list.</summary>
    function PointExists(const PointNumber: Int64): Boolean;
    /// <summary>Deletes all points.</summary>
    procedure Clear;
    /// <summary>Point numbers, sorted.</summary>
    function SortedNumbers: TArray<Int64>;

    // File import and export
    /// <summary>Saves a TXT file, sorted by number.</summary>
    procedure ExportToTXT(const FileName: string);
    /// <summary>Saves a CSV file, sorted by number.</summary>
    procedure ExportToCSV(const FileName: string);
    /// <summary>Adds points from a TXT file, skips bad lines.</summary>
    procedure ImportFromTXT(const FileName: string);
    /// <summary>Adds points from a CSV file, skips bad lines.</summary>
    procedure ImportFromCSV(const FileName: string);
    /// <summary>Saves a .yxz or .xyz file.</summary>
    procedure ExportToBinary(const FileName: string);
    /// <summary>Opens a .yxz or .xyz file; a bad file keeps the list.</summary>
    procedure LoadFromBinary(const FileName: string);

    /// <summary>Order by extension, others refused.</summary>
    class function FileOrder(const FileName: string): TCoordOrder;

    /// <summary>All points.</summary>
    property Values: TEnumerable<TPoint> read GetValues;
  end;

implementation

var
  CommaFormat: TFormatSettings;   // files use a comma
  DotFormat: TFormatSettings;     // reading also accepts a dot

class function TPointDictionary.FileStrToFloat(const AText: string): Double;
var
  S: string;
begin
  S := Trim(AText);
  if not TryStrToFloat(S, Result, CommaFormat) then
    Result := StrToFloat(S, DotFormat);
end;

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

class function TPointDictionary.SamePoint(const A, B: TPoint): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z) and
            (A.Quality = B.Quality) and (A.Description = B.Description);
end;

procedure TPointDictionary.AddOrUpdatePoint(const APoint: TPoint);
var
  Old: TPoint;
begin
  if FPointDict.TryGetValue(APoint.PointNumber, Old) and SamePoint(Old, APoint) then
    Exit;
  FPointDict.AddOrSetValue(APoint.PointNumber, APoint);
  FModified := True;
  Inc(FChangeCount);
end;

function TPointDictionary.GetPoint(const PointNumber: Int64): TPoint;
begin
  if not FPointDict.TryGetValue(PointNumber, Result) then
    raise Exception.CreateFmt('Bod %.15d v seznamu není.', [PointNumber]);
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
    raise Exception.CreateFmt('Bod %.15d v seznamu není.', [PointNumber]);
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
  FModified := True;
  Inc(FChangeCount);
end;

function TPointDictionary.SortedNumbers: TArray<Int64>;
begin
  Result := FPointDict.Keys.ToArray;
  TArray.Sort<Int64>(Result);
end;

// Text files
procedure TPointDictionary.ExportToTXT(const FileName: string);
begin
  ExportText(FileName, #9);
end;

procedure TPointDictionary.ExportToCSV(const FileName: string);
begin
  ExportText(FileName, ';');
end;

procedure TPointDictionary.ImportFromTXT(const FileName: string);
begin
  ImportText(FileName, #9);
end;

procedure TPointDictionary.ImportFromCSV(const FileName: string);
begin
  ImportText(FileName, ';');
end;

procedure TPointDictionary.ExportText(const FileName: string; ADelimiter: Char);
var
  TxtFile: TextFile;
  Key: Int64;
  P: TPoint;
  C1, C2: Double;
begin
  AssignFile(TxtFile, FileName);
  Rewrite(TxtFile);
  try
    for Key in SortedNumbers do      // sorted by number
    begin
      P := FPointDict[Key];
      CoordRead(P, C1, C2);
      WriteLn(TxtFile,
        Format('%.15d', [P.PointNumber]) + ADelimiter +
        Format('%.3f', [C1], CommaFormat) + ADelimiter +
        Format('%.3f', [C2], CommaFormat) + ADelimiter +
        Format('%.3f', [P.Z], CommaFormat) + ADelimiter +
        IntToStr(P.Quality) + ADelimiter +
        string(P.Description));
    end;
  finally
    CloseFile(TxtFile);
  end;
end;

procedure TPointDictionary.ImportText(const FileName: string; ADelimiter: Char);
var
  TxtFile: TextFile;
  Line: string;
  Fields: TStringList;
  Tmp, P: TPoint;
  Imported, Updated, Skipped: Integer;
begin
  CheckFileError(FileName);
  Imported := 0;
  Updated := 0;
  Skipped := 0;

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

      // Bad lines are counted
      Fields.DelimitedText := Line;
      if Fields.Count < 6 then
      begin
        Inc(Skipped);
        Continue;
      end;
      try
        CoordWrite(Tmp, FileStrToFloat(Fields[1]), FileStrToFloat(Fields[2]));
        P := TPoint.Create(StrToInt64(Trim(Fields[0])), Tmp.X, Tmp.Y,
                           FileStrToFloat(Fields[3]), StrToInt(Trim(Fields[4])),
                           Fields[5]);
      except
        on EConvertError do
        begin
          Inc(Skipped);
          Continue;
        end;
      end;
      if P.PointNumber = 0 then      // invalid number
      begin
        Inc(Skipped);
        Continue;
      end;

      if PointExists(P.PointNumber) then
        Inc(Updated);
      AddOrUpdatePoint(P);
      Inc(Imported);
    end;
  finally
    Fields.Free;
    CloseFile(TxtFile);
  end;
  ReportImport(Imported, Updated, Skipped);
end;

procedure TPointDictionary.ExportToBinary(const FileName: string);
var
  BinaryFile: File of TPoint;
  P: TPoint;
  R: TPoint;
  Order: TCoordOrder;
begin
  Order := FileOrder(FileName);   // check before writing
  AssignFile(BinaryFile, FileName);
  Rewrite(BinaryFile);
  try
    for P in FPointDict.Values do
    begin
      R := P;
      if Order = coYX then
        SwapXY(R);   // .yxz keeps Y first
      Write(BinaryFile, R);
    end;
  finally
    CloseFile(BinaryFile);
  end;
end;

procedure TPointDictionary.LoadFromBinary(const FileName: string);
var
  BinaryFile: File of TPoint;
  P: TPoint;
  Loaded: TList<TPoint>;
  Order: TCoordOrder;
  Count: Integer;
begin
  Order := FileOrder(FileName);
  CheckFileError(FileName);
  Loaded := TList<TPoint>.Create;
  try
    // Read all first, a bad file keeps the list
    AssignFile(BinaryFile, FileName);
    Reset(BinaryFile);
    try
      while not Eof(BinaryFile) do
      begin
        Read(BinaryFile, P);
        if Order = coYX then
          SwapXY(P);   // .yxz keeps Y first
        Loaded.Add(P);
      end;
    finally
      CloseFile(BinaryFile);
    end;

    Clear;
    for P in Loaded do
      AddOrUpdatePoint(P);
    FModified := False;
    Count := Loaded.Count;
  finally
    Loaded.Free;
  end;
  ReportImport(Count, 0, 0);
end;

class procedure TPointDictionary.SwapXY(var P: TPoint);
var
  T: Double;
begin
  T   := P.X;
  P.X := P.Y;
  P.Y := T;
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

// Message after import
procedure TPointDictionary.ReportImport(AImported, AUpdated, ASkipped: Integer);
var
  Msg: string;
begin
  Msg := Format('Importováno %d bodů.', [AImported]);
  if AUpdated > 0 then
    Msg := Msg + Format(' Z toho přepsáno: %d.', [AUpdated]);
  if ASkipped > 0 then
    Msg := Msg + Format(' Přeskočeno chybných řádků: %d.', [ASkipped]);
  Application.MessageBox(PChar(Msg), 'Informace', MB_OK or MB_ICONINFORMATION);
end;

// Error if the file is missing
procedure TPointDictionary.CheckFileError(const FileName: string);
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('Soubor %s neexistuje.', [FileName]);
end;

// Getter of Values
function TPointDictionary.GetValues: TEnumerable<TPoint>;
begin
  Result := FPointDict.Values;
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

