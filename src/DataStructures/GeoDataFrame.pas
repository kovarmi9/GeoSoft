unit GeoDataFrame;

interface

uses
  System.SysUtils, System.Classes, GeoRow, Math;

type
  TGeoRowArray = GeoRow.TGeoRowArray;
  TStrArray = array of string;

  // Table-like container for measurement rows with a defined field schema
  TGeoDataFrame = class
    private
    FCount: Integer;         // number of rows currently in use
    FCapacity: Integer;      // number of rows allocated
    FFields: TGeoFields;     // active field columns
    FRows: TGeoRowArray;     // row storage

    procedure Reserve(Need: Integer);
    procedure SetCount(const Value: Integer);

    public
    constructor Create; overload;
    constructor Create(const AFields: TGeoFields); overload;
    constructor Create(const CSV: TStringList; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload;
    constructor Create(const AFileName: string; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload;

    destructor Destroy; override;

    // Exposed properties
    property Count: Integer read FCount write SetCount;
    property Capacity: Integer read FCapacity;
    property Fields: TGeoFields read FFields write FFields;
    property Rows: TGeoRowArray read FRows write FRows; // write via AddRow / Count / direct index

    // Clears the entire frame including the field schema
    procedure Clear();
    // Clears rows only; keeps the field schema
    procedure ClearData();

    // Adds one empty row
    procedure AddRow(); overload;
    // Adds N empty rows
    procedure AddRow(N: Integer); overload;
    // Adds a copy of the given row
    procedure AddRow(const ARow: TGeoRow); overload;

    // Returns a human-readable dump of the frame as a string list
    function Print(): TStringList;

    // Serialises the frame to CSV (in-memory or file)
    function ToCSV(const ACellSep: Char = ';'; const ADecSep: Char = '.'): TStringList; overload;
    procedure ToCSV(const FileName: string; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload;

    // Deserialises the frame from CSV (in-memory or file)
    procedure FromCSV(const CSV: TStringList; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload;
    procedure FromCSV(const FileName: string; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload;

    // Saves/loads the frame as a binary typed file (file of TGeoRow with a header record)
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);

  end;

implementation

// Forward declarations of private helper functions
function SplitCsvLine(const ALine: string; ASep: Char): TStrArray; forward;
function GeoFieldFromName(const AName: string; out AField: TGeoField): Boolean; forward;
function TryToInt(const ACell: string; var AOutVal: Integer): Boolean; forward;
function TryToFloat(const ACell: string; var AOutVal: Double; const FormatSettings: TFormatSettings): Boolean; forward;

function GeoFieldsToMask(const F: TGeoFields): LongWord; forward;
function MaskToGeoFields(const Mask: LongWord): TGeoFields; forward;


// -- Public --

constructor TGeoDataFrame.Create;
begin
  inherited Create;
  FCount := 0;
  FCapacity := 0;
  SetLength(FRows, 0);
  FFields := [Low(TGeoField)..High(TGeoField)];
end;

constructor TGeoDataFrame.Create(const AFields: TGeoFields);
begin
  Self.Create;
  Fields := AFields;
end;

constructor TGeoDataFrame.Create(const CSV: TStringList; const ACellSep, ADecSep: Char);
begin
  Create;
  FromCSV(CSV, ACellSep, ADecSep);
end;

constructor TGeoDataFrame.Create(const AFileName: string;
  const ACellSep, ADecSep: Char);
var
  Ext: string;
begin
  Create;

  if not FileExists(AFileName) then
    raise Exception.CreateFmt('Soubor "%s" neexistuje.', [AFileName]);

  Ext := LowerCase(ExtractFileExt(AFileName));

  if Ext = '.csv' then
  begin
    // Text CSV — use the provided separators
    FromCSV(AFileName, ACellSep, ADecSep);
  end
  else
  begin
    // Non-CSV with custom separators is suspicious
    if (ACellSep <> ';') or (ADecSep <> '.') then
      raise EArgumentException.CreateFmt(
        'Separátory ACellSep/ADecSep mají smysl jen pro CSV. ' +
        'Soubor "%s" nemá příponu .csv (Ext = "%s").',
        [AFileName, Ext]
      );

    // Binary typed file — separators are irrelevant
    LoadFromFile(AFileName);
  end;
end;

destructor TGeoDataFrame.Destroy;
begin
  SetLength(FRows, 0);
  inherited;
end;

// Doubles capacity until it covers Need; no-op if already sufficient
procedure TGeoDataFrame.Reserve(Need: Integer);
var cap: Integer;
begin
  if Need <= FCapacity then Exit;
  cap := Math.Max(1, FCapacity);
  while cap < Need do cap := cap * 2;
  SetLength(FRows, cap);
  FCapacity := cap;
end;

procedure TGeoDataFrame.SetCount(const Value: Integer);
var
  i, OldCount: Integer;
begin
  if Value < 0 then
    raise ERangeError.CreateFmt('Invalid Count: %d', [Value]);

  OldCount := FCount;

  if Value > FCapacity then
    Reserve(Value);

  // Zero-initialise newly added rows
  if Value > OldCount then
  begin
    for i := OldCount to Value - 1 do
      ClearGeoRow(FRows[i]);
  end
  else if Value < OldCount then
  begin
    // Zero-out removed slots for cleanliness
    for i := Value to OldCount - 1 do
      ClearGeoRow(FRows[i]);
  end;

  FCount := Value;
end;

procedure TGeoDataFrame.Clear;
begin
  ClearData;
  FFields := [];
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

procedure TGeoDataFrame.AddRow(N: Integer);
var
  i, need: Integer;
begin
  if N <= 0 then Exit;
  need := FCount + N;
  Reserve(need);
  for i := FCount to need - 1 do
    ClearGeoRow(FRows[i]);
  FCount := need;
end;

procedure TGeoDataFrame.AddRow(const ARow: TGeoRow);
begin
  AddRow(1);
  FRows[FCount - 1] := ARow;
end;

function TGeoDataFrame.Print(): TStringList;
var
  i: Integer;
  RowText: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('=== TGeoDataFrame ===');
  Result.Add(Format('Count    : %d', [Count]));
  Result.Add(Format('Capacity : %d', [Capacity]));
  Result.Add('Fields   : ' + PrintGeoFields(Fields));

  for i := 0 to Count - 1 do
  begin
    Result.Add('');
    RowText := PrintGeoRow(FRows[i], Fields, i);
    try
      Result.AddStrings(RowText);
    finally
      RowText.Free;
    end;
  end;
end;

function TGeoDataFrame.ToCSV(const ACellSep: Char = ';'; const ADecSep: Char = '.'): TStringList;
var
  Field: TGeoField;
  RowIndex: Integer;
  Line, s: string;
  FormatSettings: TFormatSettings;
  Row: TGeoRow;
begin
  Result := TStringList.Create;

  if ACellSep = ADecSep then
    raise EArgumentException.CreateFmt(
      'Cell separator "%s" must differ from decimal separator "%s".',
      [string(ACellSep), string(ADecSep)]
    );

  // Configure number format
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator  := ADecSep;
  FormatSettings.ThousandSeparator := #0; // disable thousands separator

  // Header row
  Result.Add(PrintGeoFields(Fields, string(ACellSep)));

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

        case Field of
          Uloha:    s := IntToStr(Row.Uloha);
          CB:       s := '"' + StringReplace(string(Row.CB), '"', '""', [rfReplaceAll]) + '"';
          X:        s := FloatToStr(Row.X, FormatSettings);
          Y:        s := FloatToStr(Row.Y, FormatSettings);
          Z:        s := FloatToStr(Row.Z, FormatSettings);
          Xm:       s := FloatToStr(Row.Xm, FormatSettings);
          Ym:       s := FloatToStr(Row.Ym, FormatSettings);
          Zm:       s := FloatToStr(Row.Zm, FormatSettings);
          TypS:     s := IntToStr(Row.TypS);
          SH:       s := FloatToStr(Row.SH, FormatSettings);
          SS:       s := FloatToStr(Row.SS, FormatSettings);
          VS:       s := FloatToStr(Row.VS, FormatSettings);
          VC:       s := FloatToStr(Row.VC, FormatSettings);
          HZ:       s := FloatToStr(Row.HZ, FormatSettings);
          Zuhel:    s := FloatToStr(Row.Zuhel, FormatSettings);
          PolarD:   s := FloatToStr(Row.PolarD, FormatSettings);
          PolarK:   s := FloatToStr(Row.PolarK, FormatSettings);
          Poznamka: s := '"' + StringReplace(string(Row.Poznamka), '"', '""', [rfReplaceAll]) + '"';
        end;

        Line := Line + s;
      end;

    Result.Add(Line);
  end;
end;

// File overload — serialises to CSV then saves to disk
procedure TGeoDataFrame.ToCSV(const FileName: string;
  const ACellSep: Char; const ADecSep: Char);
var
  CSV: TStringList;
begin
  CSV := ToCSV(ACellSep, ADecSep);
  try
    CSV.SaveToFile(FileName);
  finally
    CSV.Free;
  end;
end;

procedure TGeoDataFrame.FromCSV(const CSV: TStringList; const ACellSep: Char = ';'; const ADecSep: Char = '.');
var
  FormatSettings: TFormatSettings;
  Header: TStrArray;
  ColCount: Integer;
  ColMap: array of TGeoField;
  ColKnown: array of Boolean;
  i, j: Integer;
  Line, Value: string;
  FieldsArr: TStrArray;
  Row: TGeoRow;
  Field: TGeoField;
  UsedFields: TGeoFields;
begin

  if (CSV = nil) or (CSV.Count = 0) then
  begin
    Clear;
    Exit;
  end;

  if ACellSep = ADecSep then
    raise EArgumentException.CreateFmt(
      'Cell separator "%s" must differ from decimal separator "%s".',
      [string(ACellSep), string(ADecSep)]
    );

  // Number format for parsing
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator  := ADecSep;
  FormatSettings.ThousandSeparator := #0;

  // Parse header row to build column-to-field mapping
  Header := SplitCsvLine(CSV[0], ACellSep);
  ColCount := Length(Header);
  if ColCount = 0 then
  begin
    Clear;
    Exit;
  end;

  SetLength(ColMap, ColCount);
  SetLength(ColKnown, ColCount);
  UsedFields := [];

  for j := 0 to ColCount - 1 do
  begin
    Value := Trim(Header[j]);
    if GeoFieldFromName(Value, Field) then
    begin
      ColMap[j]   := Field;
      ColKnown[j] := True;
      Include(UsedFields, Field);
    end
    else
      ColKnown[j] := False;
  end;

  // Reset storage and apply the schema derived from the header
  SetLength(FRows, 0);
  FCapacity := 0;
  FCount := 0;
  FFields := UsedFields;

  Reserve(CSV.Count - 1);
  SetCount(CSV.Count - 1);

  // Parse data rows
  for i := 1 to CSV.Count - 1 do
  begin
    Line := CSV[i];
    Row := FRows[i - 1];

    if Line <> '' then
    begin
      FieldsArr := SplitCsvLine(Line, ACellSep);

      for j := 0 to High(FieldsArr) do
        if (j < ColCount) and ColKnown[j] then
        begin
          Field := ColMap[j];
          Value := FieldsArr[j];

          case Field of
            Uloha:    if not TryToInt(Value, Row.Uloha) then Row.Uloha := 0;
            CB:       Row.CB := ShortString(Copy(Value, 1, 16));
            X:        if not TryToFloat(Value, Row.X,  FormatSettings) then Row.X  := 0;
            Y:        if not TryToFloat(Value, Row.Y,  FormatSettings) then Row.Y  := 0;
            Z:        if not TryToFloat(Value, Row.Z,  FormatSettings) then Row.Z  := 0;
            Xm:       if not TryToFloat(Value, Row.Xm, FormatSettings) then Row.Xm := 0;
            Ym:       if not TryToFloat(Value, Row.Ym, FormatSettings) then Row.Ym := 0;
            Zm:       if not TryToFloat(Value, Row.Zm, FormatSettings) then Row.Zm := 0;
            TypS:     if not TryToInt(Value, Row.TypS) then Row.TypS := 0;
            SH:       if not TryToFloat(Value, Row.SH, FormatSettings) then Row.SH := 0;
            SS:       if not TryToFloat(Value, Row.SS, FormatSettings) then Row.SS := 0;
            VS:       if not TryToFloat(Value, Row.VS, FormatSettings) then Row.VS := 0;
            VC:       if not TryToFloat(Value, Row.VC, FormatSettings) then Row.VC := 0;
            HZ:       if not TryToFloat(Value, Row.HZ, FormatSettings) then Row.HZ := 0;
            Zuhel:    if not TryToFloat(Value, Row.Zuhel, FormatSettings) then Row.Zuhel := 0;
            PolarD:   if not TryToFloat(Value, Row.PolarD, FormatSettings) then Row.PolarD := 0;
            PolarK:   if not TryToFloat(Value, Row.PolarK, FormatSettings) then Row.PolarK := 0;
            Poznamka: Row.Poznamka := ShortString(Copy(Value, 1, 128));
          end;
        end;
    end;

    FRows[i - 1] := Row;
  end;
end;

// File overload — loads file into a string list and delegates to the in-memory version
procedure TGeoDataFrame.FromCSV(const FileName: string;
  const ACellSep: Char; const ADecSep: Char);
var
  CSV: TStringList;
begin
  CSV := TStringList.Create;
  try
    CSV.LoadFromFile(FileName);
    FromCSV(CSV, ACellSep, ADecSep);
  finally
    CSV.Free;
  end;
end;

procedure TGeoDataFrame.SaveToFile(const FileName: string);
var
  Buffer: array of TGeoRow;
  Header: TGeoRow;
  i: Integer;
begin
  // Allocate buffer for header record + data rows
  SetLength(Buffer, FCount + 1);

  // Header record at Buffer[0] encodes the active field mask
  ClearGeoRow(Header);
  Header.Uloha := -1;                                // sentinel: marks this record as a header
  Header.CB    := '__HEADER__';                      // readable marker for verification
  Header.TypS  := Integer(GeoFieldsToMask(FFields)); // bitmask of active fields

  Buffer[0] := Header;

  // Copy data rows into Buffer[1..FCount]
  for i := 0 to FCount - 1 do
    Buffer[i + 1] := FRows[i];

  SaveRow(FileName, Buffer, False);
end;

procedure TGeoDataFrame.LoadFromFile(const FileName: string);
var
  AllRows: TGeoRowArray;
  Header: TGeoRow;
  UsedFields: TGeoFields;
  mask: LongWord;
  DataCount, i: Integer;
begin
  LoadRow(FileName, AllRows);

  // Empty file — reset and exit
  if Length(AllRows) = 0 then
  begin
    Clear;
    Exit;
  end;

  // Default: all fields active (used when no header record is present)
  UsedFields := [Low(TGeoField)..High(TGeoField)];

  Header := AllRows[0];

  if (Header.Uloha = -1) and SameText(String(Header.CB), '__HEADER__') then
  begin
    // Header record found — decode the field mask
    mask := LongWord(Header.TypS);
    UsedFields := MaskToGeoFields(mask);

    DataCount := Length(AllRows) - 1;

    ClearData;
    FFields := UsedFields;
    SetCount(DataCount);

    // Data starts at AllRows[1]
    for i := 0 to DataCount - 1 do
      FRows[i] := AllRows[i + 1];
  end
  else
  begin
    // No header — treat the entire file as data rows
    DataCount := Length(AllRows);

    ClearData;
    FFields := UsedFields;
    SetCount(DataCount);

    for i := 0 to DataCount - 1 do
      FRows[i] := AllRows[i];
  end;
end;


////////////////////////////////////////////////////////////////////////////////

// Helper functions

// Splits one CSV line into cells, respecting quoted strings and escaped quotes ("")
function SplitCsvLine(const ALine: string; ASep: Char): TStrArray;
var
  i, n: Integer;     // i = current char index; n = number of stored cells
  inQuotes: Boolean; // True while inside a quoted field
  ch: Char;          // current character
  buf: string;       // accumulation buffer for the current cell
begin
  SetLength(Result, 0);
  buf := '';
  inQuotes := False;
  n := 0;
  i := 1;

  while i <= Length(ALine) do
  begin
    ch := ALine[i];

    // Handle double-quote characters
    if ch = '"' then
    begin
      // "" inside a quoted field is an escaped quote — emit a single " and skip both chars
      if inQuotes and (i < Length(ALine)) and (ALine[i+1] = '"') then
      begin
        buf := buf + '"';
        i := i + 2;
        Continue;
      end
      else
      begin
        // Toggle in/out of quoted mode
        inQuotes := not inQuotes;
        i := i + 1;
        Continue;
      end;
    end;

    // Unquoted separator — close the current cell and start a new one
    if (not inQuotes) and (ch = ASep) then
    begin
      SetLength(Result, n + 1);
      Result[n] := buf;
      n := n + 1;
      buf := '';
      i := i + 1;
      Continue;
    end;

    // Regular character — append to current cell
    buf := buf + ch;
    i := i + 1;
  end;

  // Store the last cell
  SetLength(Result, n + 1);
  Result[n] := buf;
end;

// Maps a CSV header name to a TGeoField enum value; returns True on match
function GeoFieldFromName(const AName: string; out AField: TGeoField): Boolean;
var
  f: TGeoField;
begin
  Result := False;
  for f := Low(TGeoField) to High(TGeoField) do
    if SameText(AName, GeoFieldNames[f]) then
    begin
      AField := f;
      Exit(True);
    end;
end;

// Tries to parse a trimmed cell string as an integer; updates AOutVal only on success
function TryToInt(const ACell: string; var AOutVal: Integer): Boolean;
var
  tmp: Integer;
begin
  Result := TryStrToInt(Trim(ACell), tmp);
  if Result then
    AOutVal := tmp;
end;

// Tries to parse a trimmed cell string as a float using the given format settings
function TryToFloat(const ACell: string; var AOutVal: Double; const FormatSettings: TFormatSettings): Boolean;
var
  tmp: Double;
begin
  Result := TryStrToFloat(Trim(ACell), tmp, FormatSettings);
  if Result then
    AOutVal := tmp;
end;

// Converts a TGeoFields set to a bitmask (one bit per enum ordinal)
function GeoFieldsToMask(const F: TGeoFields): LongWord;
var
  fld: TGeoField;
begin
  Result := 0;
  for fld := Low(TGeoField) to High(TGeoField) do
    if fld in F then
      Result := Result or (LongWord(1) shl Ord(fld));
end;

// Converts a bitmask back to a TGeoFields set
function MaskToGeoFields(const Mask: LongWord): TGeoFields;
var
  fld: TGeoField;
begin
  Result := [];
  for fld := Low(TGeoField) to High(TGeoField) do
    if (Mask and (LongWord(1) shl Ord(fld))) <> 0 then
      Include(Result, fld);
end;


end.
