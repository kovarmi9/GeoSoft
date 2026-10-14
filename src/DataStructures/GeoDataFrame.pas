unit GeoDataFrame;

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
    /// <summary>Empty table with all fields.</summary>
    constructor Create; overload;
    /// <summary>Empty table with the given fields.</summary>
    constructor Create(const AFields: TGeoFields); overload;

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

    /// <summary>Adds one empty row.</summary>
    procedure AddRow; overload;
    /// <summary>Adds ACount empty rows.</summary>
    procedure AddRow(ACount: Integer); overload;
    /// <summary>Adds a copy of the row.</summary>
    procedure AddRow(const ARow: TGeoRow); overload;

    /// <summary>Readable dump of the frame.</summary>
    function Print: string;

    /// <summary>The frame as CSV text.</summary>
    function ToCSV(const ACellSep: Char = ';'; const ADecSep: Char = ','): string; overload;
    /// <summary>Saves the frame to a CSV file.</summary>
    procedure ToCSV(const AFileName: string; const ACellSep: Char = ';'; const ADecSep: Char = ','); overload;

    /// <summary>Reads CSV lines. Fields come from the header.
    /// Takes any TStrings, e.g. a TStringList or Memo1.Lines.</summary>
    procedure FromCSV(const ACSV: TStrings; const ACellSep: Char = ';'; const ADecSep: Char = ','); overload;
    /// <summary>Reads a CSV file. Fields come from the header.</summary>
    procedure FromCSV(const AFileName: string; const ACellSep: Char = ';'; const ADecSep: Char = ','); overload;

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
  I, N: Integer;     // I = current char index, N = number of stored cells
  InQuotes: Boolean; // True while inside a quoted field
  Ch: Char;          // current character
  Buf: string;       // the current cell
begin
  SetLength(Result, 0);
  Buf := '';
  InQuotes := False;
  N := 0;
  I := 1;

  while I <= Length(ALine) do
  begin
    Ch := ALine[I];

    // Handle double-quote characters
    if Ch = '"' then
    begin
      // "" inside quotes means one " in the cell
      if InQuotes and (I < Length(ALine)) and (ALine[I + 1] = '"') then
      begin
        Buf := Buf + '"';
        I := I + 2;
        Continue;
      end
      else
      begin
        // Toggle in/out of quoted mode
        InQuotes := not InQuotes;
        I := I + 1;
        Continue;
      end;
    end;

    // Unquoted separator - close the current cell and start a new one
    if (not InQuotes) and (Ch = ASep) then
    begin
      SetLength(Result, N + 1);
      Result[N] := Buf;
      N := N + 1;
      Buf := '';
      I := I + 1;
      Continue;
    end;

    // Regular character - append to current cell
    Buf := Buf + Ch;
    I := I + 1;
  end;

  // Store the last cell
  SetLength(Result, N + 1);
  Result[N] := Buf;
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
constructor TGeoDataFrame.Create;
begin
  inherited Create;
  FFields := [Low(TGeoField)..High(TGeoField)];
end;

constructor TGeoDataFrame.Create(const AFields: TGeoFields);
begin
  Self.Create;
  Fields := AFields;
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
  I, OldCount: Integer;
begin
  if Value < 0 then
    raise ERangeError.CreateFmt('Neplatný počet řádků: %d', [Value]);

  OldCount := FCount;

  if Value > FCapacity then
    Reserve(Value);

  // New rows start empty
  if Value > OldCount then
  begin
    for I := OldCount to Value - 1 do
      ClearGeoRow(FRows[I]);
  end
  else if Value < OldCount then
  begin
    // Empty the dropped rows too
    for I := Value to OldCount - 1 do
      ClearGeoRow(FRows[I]);
  end;

  FCount := Value;
end;

procedure TGeoDataFrame.ClearData;
begin
  SetLength(FRows, 0);
  FCount := 0;
  FCapacity := 0;
  // FFields is intentionally kept
end;

procedure TGeoDataFrame.AddRow;
begin
  AddRow(1);
end;

procedure TGeoDataFrame.AddRow(ACount: Integer);
var
  I, NewCount: Integer;
begin
  if ACount <= 0 then Exit;
  NewCount := FCount + ACount;
  Reserve(NewCount);
  for I := FCount to NewCount - 1 do
    ClearGeoRow(FRows[I]);
  FCount := NewCount;
end;

procedure TGeoDataFrame.AddRow(const ARow: TGeoRow);
var
  Row: TGeoRow;
begin
  Row := ARow;     // ARow may point into FRows, which AddRow(1) can move
  AddRow(1);
  FRows[FCount - 1] := Row;
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
    // Header row
    CSV.Add(PrintGeoFields(Fields, string(ACellSep)));

    // Data rows
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
          if Field in [CB, CBm, Poznamka] then
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

procedure TGeoDataFrame.FromCSV(const ACSV: TStrings; const ACellSep: Char; const ADecSep: Char);
var
  FS: TFormatSettings;
  Header, Cells: TStrArray;
  ColCount: Integer;
  ColMap: array of TGeoField;
  ColKnown: array of Boolean;
  I, J: Integer;
  Field: TGeoField;
  UsedFields: TGeoFields;
begin
  if (ACSV = nil) or (ACSV.Count = 0) then
  begin
    ClearData;
    Exit;
  end;

  FS := CsvFormat(ACellSep, ADecSep);

  // Parse header row to build column-to-field mapping
  Header := SplitCsvLine(ACSV[0], ACellSep);
  ColCount := Length(Header);

  SetLength(ColMap, ColCount);
  SetLength(ColKnown, ColCount);
  UsedFields := [];

  for J := 0 to ColCount - 1 do
  begin
    if FindGeoField(Trim(Header[J]), Field) then
    begin
      ColMap[J]   := Field;
      ColKnown[J] := True;
      Include(UsedFields, Field);
    end
    else
      ColKnown[J] := False;
  end;

  // A wrong cell separator leaves the whole header as one unknown name
  if UsedFields = [] then
    raise Exception.Create('Hlavička CSV neobsahuje žádné známé pole. ' +
      'Zkontrolujte oddělovač buněk.');

  // Reset storage and apply the schema derived from the header
  ClearData;
  FFields := UsedFields;
  Reserve(ACSV.Count - 1);   // room for all lines at once

  // Parse data rows, skip empty lines
  for I := 1 to ACSV.Count - 1 do
    if Trim(ACSV[I]) <> '' then
    begin
      AddRow;
      Cells := SplitCsvLine(ACSV[I], ACellSep);
      for J := 0 to High(Cells) do
        if (J < ColCount) and ColKnown[J] then
          TextToGeoField(FRows[FCount - 1], ColMap[J], Cells[J], FS);
    end;
end;

// File overload - loads the file and calls the version above
procedure TGeoDataFrame.FromCSV(const AFileName: string; const ACellSep: Char; const ADecSep: Char);
var
  CSV: TStringList;
begin
  CSV := TStringList.Create;
  try
    CSV.LoadFromFile(AFileName);
    FromCSV(CSV, ACellSep, ADecSep);
  finally
    CSV.Free;
  end;
end;

procedure TGeoDataFrame.SaveToFile(const AFileName: string);
var
  Buffer: TGeoRowArray;
  Header: TGeoRow;
  I: Integer;
begin
  // Allocate buffer for header record + data rows
  SetLength(Buffer, FCount + 1);

  // Header record at Buffer[0] encodes the active field mask
  ClearGeoRow(Header);
  Header.Uloha := -1;                                // marks the header
  Header.CB    := '__HEADER__';                      // readable marker
  Header.TypS  := Integer(GeoFieldsToMask(FFields)); // bitmask of active fields

  Buffer[0] := Header;

  // Copy data rows into Buffer[1..FCount]
  for I := 0 to FCount - 1 do
    Buffer[I + 1] := FRows[I];

  SaveRows(AFileName, Buffer);
end;

procedure TGeoDataFrame.LoadFromFile(const AFileName: string);
var
  AllRows: TGeoRowArray;
  Header: TGeoRow;
  UsedFields: TGeoFields;
  First, I: Integer;
begin
  AllRows := LoadRows(AFileName);

  // Empty file - reset and exit
  if Length(AllRows) = 0 then
  begin
    ClearData;
    Exit;
  end;

  // A header record carries Fields. A file without it has all fields
  Header := AllRows[0];
  if (Header.Uloha = -1) and SameText(string(Header.CB), '__HEADER__') then
  begin
    UsedFields := MaskToGeoFields(LongWord(Header.TypS));
    First := 1;            // data start after the header
  end
  else
  begin
    UsedFields := [Low(TGeoField)..High(TGeoField)];
    First := 0;
  end;

  ClearData;
  FFields := UsedFields;
  SetCount(Length(AllRows) - First);
  for I := 0 to Count - 1 do
    FRows[I] := AllRows[I + First];
end;

end.
