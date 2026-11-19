unit GeoDataFrame;

// Rows of one task, CSV and binary file

interface

uses
  System.SysUtils, System.Classes, System.Math, GeoRow;

type
  /// <summary>Rows of one task and the fields it uses.</summary>
  TGeoDataFrame = class
  private
    FCount: Integer;         // number of rows currently in use
    FCapacity: Integer;      // number of rows allocated
    FFields: TGeoFields;     // active field columns
    FRows: TGeoRowArray;     // row storage

    procedure Reserve(ANeed: Integer);
    procedure SetCount(const Value: Integer);

  public
    /// <summary>Empty table with the given fields, all by default.</summary>
    constructor Create(const AFields: TGeoFields = [Low(TGeoField)..High(TGeoField)]);

    /// <summary>Number of rows. Setting it adds or drops rows.</summary>
    property Count: Integer read FCount write SetCount;
    /// <summary>Rows that fit before the array has to grow.</summary>
    property Capacity: Integer read FCapacity;
    /// <summary>Fields written by Print and ToCSV.</summary>
    property Fields: TGeoFields read FFields write FFields;
    /// <summary>The rows. Use Count, not Length(Rows).</summary>
    property Rows: TGeoRowArray read FRows;

    /// <summary>Deletes all rows. Fields stay.</summary>
    procedure ClearData;

    /// <summary>Adds ACount empty rows, one by default.</summary>
    procedure AddRow(ACount: Integer = 1); overload;
    /// <summary>Adds a copy of the row.</summary>
    procedure AddRow(const ARow: TGeoRow); overload;
    /// <summary>Č. of row I, its order when it has no Line.</summary>
    function LineOf(I: Integer): Integer;

    /// <summary>Readable dump of the frame.</summary>
    function Print: string;

    /// <summary>The frame as CSV text.</summary>
    function ToCSV(const ACellSep: Char = ';'; const ADecSep: Char = ','): string; overload;
    /// <summary>Saves the frame to a CSV file.</summary>
    procedure ToCSV(const AFileName: string; const ACellSep: Char = ';'; const ADecSep: Char = ','); overload;

    /// <summary>Reads CSV lines, fields from the header, bad to ABad.</summary>
    procedure FromCSV(const ACSV: TStrings; const ACellSep: Char = ';'; const ADecSep: Char = ',';
      ABad: TStrings = nil); overload;
    /// <summary>Reads a CSV file. Fields come from the header.</summary>
    procedure FromCSV(const AFileName: string; const ACellSep: Char = ';'; const ADecSep: Char = ',';
      ABad: TStrings = nil); overload;

    /// <summary>Saves rows and Fields to a binary file.</summary>
    procedure SaveToFile(const AFileName: string);
    /// <summary>Loads a file written by SaveToFile.</summary>
    procedure LoadFromFile(const AFileName: string);

  end;

implementation

type
  TStrArray = array of string;

// Number format for CSV. The two separators must differ
function CsvFormat(ACellSep, ADecSep: Char): TFormatSettings;
begin
  if ACellSep = ADecSep then
    raise EArgumentException.CreateFmt(
      'Oddělovač buněk "%s" se musí lišit ' +
      'od desetinného oddělovače "%s".',
      [string(ACellSep), string(ADecSep)]);
  Result := TFormatSettings.Create;
  Result.DecimalSeparator := ADecSep;
  Result.ThousandSeparator := #0;   // no thousands separator
end;

// Splits one CSV line into cells, handles quotes and ""
function SplitCsvLine(const ALine: string; ASep: Char): TStrArray;
var
  Ch, Previous: Char;
  InQuotes: Boolean;
  Buf: string;
begin
  Result := nil;
  Buf := '';
  InQuotes := False;
  Previous := #0;
  for Ch in ALine do
  begin
    if Ch = '"' then
    begin
      InQuotes := not InQuotes;
      if InQuotes and (Previous = '"') then
        Buf := Buf + '"';      // "" is one " in the cell
    end
    else if (Ch = ASep) and not InQuotes then
    begin
      Result := Result + [Buf];
      Buf := '';
    end
    else
      Buf := Buf + Ch;
    Previous := Ch;
  end;
  Result := Result + [Buf];
end;

// Converts a TGeoFields set to a bitmask (one bit per enum ordinal)
function GeoFieldsToMask(const AFields: TGeoFields): LongWord;
var
  F: TGeoField;
begin
  Result := 0;
  for F := Low(TGeoField) to High(TGeoField) do
    if F in AFields then
      Result := Result or (LongWord(1) shl Ord(F));
end;

// Converts a bitmask back to a TGeoFields set
function MaskToGeoFields(const AMask: LongWord): TGeoFields;
var
  F: TGeoField;
begin
  Result := [];
  for F := Low(TGeoField) to High(TGeoField) do
    if (AMask and (LongWord(1) shl Ord(F))) <> 0 then
      Include(Result, F);
end;

// Count, Capacity and Rows start empty: Delphi zeroes every new object
constructor TGeoDataFrame.Create(const AFields: TGeoFields);
begin
  inherited Create;
  FFields := AFields;
end;

// Doubles capacity until it covers ANeed. Does nothing if it already does
procedure TGeoDataFrame.Reserve(ANeed: Integer);
var
  Cap: Integer;
begin
  if ANeed <= FCapacity then Exit;
  Cap := Max(1, FCapacity);
  while Cap < ANeed do Cap := Cap * 2;
  SetLength(FRows, Cap);
  FCapacity := Cap;
end;

procedure TGeoDataFrame.SetCount(const Value: Integer);
var
  I: Integer;
begin
  if Value < 0 then
    raise ERangeError.CreateFmt('Neplatný počet řádků: %d', [Value]);

  Reserve(Value);
  // New rows start empty, dropped rows are emptied too
  for I := Min(Value, FCount) to Max(Value, FCount) - 1 do
    ClearGeoRow(FRows[I]);
  FCount := Value;
end;

procedure TGeoDataFrame.ClearData;
begin
  SetLength(FRows, 0);
  FCount := 0;
  FCapacity := 0;
  // FFields is intentionally kept
end;

procedure TGeoDataFrame.AddRow(ACount: Integer);
begin
  if ACount > 0 then
    Count := FCount + ACount;
end;

procedure TGeoDataFrame.AddRow(const ARow: TGeoRow);
var
  Row: TGeoRow;
begin
  Row := ARow;     // ARow may point into FRows, which AddRow(1) can move
  AddRow(1);
  FRows[FCount - 1] := Row;
end;

// Built in code, no lines
function TGeoDataFrame.LineOf(I: Integer): Integer;
begin
  Result := FRows[I].Line;
  if Result = 0 then
    Result := I + 1;
end;

function TGeoDataFrame.Print: string;
var
  I: Integer;
begin
  Result := '=== TGeoDataFrame ===' + sLineBreak +
    Format('Count    : %d', [Count]) + sLineBreak +
    Format('Capacity : %d', [Capacity]) + sLineBreak +
    'Fields   : ' + PrintGeoFields(Fields) + sLineBreak;

  for I := 0 to Count - 1 do
    Result := Result + sLineBreak + PrintGeoRow(FRows[I], Fields, I);
end;

function TGeoDataFrame.ToCSV(const ACellSep: Char; const ADecSep: Char): string;
var
  Field: TGeoField;
  RowIndex: Integer;
  Line, S: string;
  FS: TFormatSettings;
  Row: TGeoRow;
  CSV: TStringList;
begin
  FS := CsvFormat(ACellSep, ADecSep);

  CSV := TStringList.Create;
  try
    CSV.Add(PrintGeoFields(Fields, string(ACellSep)));

    for RowIndex := 0 to Count - 1 do
    begin
      Line := '';
      Row := FRows[RowIndex];

      for Field := Low(TGeoField) to High(TGeoField) do
        if Field in Fields then
        begin
          if Line <> '' then
            Line := Line + ACellSep;

          S := GeoFieldToText(Row, Field, '', FS);
          if Field in [CB, CBm, Popis] then
            S := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"';

          Line := Line + S;
        end;

      CSV.Add(Line);
    end;

    Result := CSV.Text;
  finally
    CSV.Free;
  end;
end;

// File overload - builds the CSV text and saves it
procedure TGeoDataFrame.ToCSV(const AFileName: string; const ACellSep: Char; const ADecSep: Char);
var
  CSV: TStringList;
begin
  CSV := TStringList.Create;
  try
    CSV.Text := ToCSV(ACellSep, ADecSep);
    CSV.SaveToFile(AFileName);
  finally
    CSV.Free;
  end;
end;

procedure TGeoDataFrame.FromCSV(const ACSV: TStrings; const ACellSep: Char; const ADecSep: Char; ABad: TStrings);
var
  FS: TFormatSettings;
  Header, Cells: TStrArray;
  ColCount: Integer;
  ColMap: array of TGeoField;
  ColKnown: array of Boolean;
  I, J: Integer;
  UsedFields: TGeoFields;
  S, Bad: string;
begin
  if (ACSV = nil) or (ACSV.Count = 0) then
  begin
    ClearData;
    Exit;
  end;

  FS := CsvFormat(ACellSep, ADecSep);

  Header := SplitCsvLine(ACSV[0], ACellSep);
  ColCount := Length(Header);

  SetLength(ColMap, ColCount);
  SetLength(ColKnown, ColCount);
  UsedFields := [];

  for J := 0 to ColCount - 1 do
  begin
    ColKnown[J] := FindGeoField(Trim(Header[J]), ColMap[J]);
    if ColKnown[J] then
      Include(UsedFields, ColMap[J]);
  end;

  // A wrong cell separator leaves the whole header as one unknown name
  if UsedFields = [] then
    raise Exception.Create('Hlavička CSV neobsahuje žádné známé pole. ' +
      'Zkontrolujte oddělovač buněk.');

  // Reset storage and apply the schema derived from the header
  ClearData;
  FFields := UsedFields;
  Reserve(ACSV.Count - 1);   // room for all lines at once

  for I := 1 to ACSV.Count - 1 do
    if Trim(ACSV[I]) <> '' then
    begin
      AddRow;
      FRows[FCount - 1].Line := I + 1;   // the header is line 1
      Bad := '';
      Cells := SplitCsvLine(ACSV[I], ACellSep);
      for J := 0 to High(Cells) do
        if (J < ColCount) and ColKnown[J] then
        begin
          S := Cells[J];
          // Accept a dot too, not in the note
          if ColMap[J] <> Popis then
            S := StringReplace(S, '.', ADecSep, [rfReplaceAll]);
          if not TextToGeoField(FRows[FCount - 1], ColMap[J], S, FS) and
            (Bad = '') then
            Bad := GeoFieldInfo[ColMap[J]].Name + ' = ' + Trim(Cells[J]);
        end;

      // A cell that is no number leaves the whole row out
      if Bad <> '' then
      begin
        Count := Count - 1;
        if Assigned(ABad) then
          ABad.Add(Format('řádek %d: %s', [I + 1, Bad]));
      end;
    end;
end;

// File overload - loads the file and calls the version above
procedure TGeoDataFrame.FromCSV(const AFileName: string; const ACellSep: Char; const ADecSep: Char; ABad: TStrings);
var
  CSV: TStringList;
begin
  CSV := TStringList.Create;
  try
    CSV.LoadFromFile(AFileName);
    FromCSV(CSV, ACellSep, ADecSep, ABad);
  finally
    CSV.Free;
  end;
end;

procedure TGeoDataFrame.SaveToFile(const AFileName: string);
var
  Header: TGeoRow;
begin
  // The first record is the header with the field mask
  ClearGeoRow(Header);
  Header.Typ := Integer(GeoFieldsToMask(FFields));
  SaveRow(AFileName, Header);
  SaveRows(AFileName, Copy(FRows, 0, FCount), True);
end;

procedure TGeoDataFrame.LoadFromFile(const AFileName: string);
var
  AllRows: TGeoRowArray;
  I: Integer;
begin
  AllRows := LoadRows(AFileName);
  ClearData;
  if Length(AllRows) = 0 then
    Exit;

  // The first record is the header with the field mask
  FFields := MaskToGeoFields(LongWord(AllRows[0].Typ));
  Count := Length(AllRows) - 1;
  for I := 0 to Count - 1 do
    FRows[I] := AllRows[I + 1];
end;

end.
