unit GeoRow;

interface

uses
  System.SysUtils, System.Classes, System.Math;

const
  MAX_CB    = 15;   // point number length
  MAX_POPIS = 32;   // description length

type
  // Enum of all supported measurement fields
  TGeoField = (
    Uloha,
    CB,
    X, Y, Z,
    CBm,
    Xm, Ym, Zm,
    TypS,
    SH,
    SS,
    VS,
    VC,
    HZ,
    Zuhel,
    PolarD,
    PolarK,
    Poznamka,
    KK
  );

  // Set of selected fields
  TGeoFields = set of TGeoField;

  // Single measurement row record.
  // Packed on purpose: the binary file stores this record as it is,
  // so the layout must depend only on the field types, not on the compiler.
  TGeoRow = packed record
    Uloha:         Integer;     // task type
    CB:            string[MAX_CB];  // point number
    X, Y, Z:       Double;      // global coordinates
    CBm:           string[MAX_CB];  // source point number
    Xm, Ym, Zm:    Double;      // local coordinates
    TypS:          Integer;     // distance type
    SH:            Double;      // horizontal distance
    SS:            Double;      // slope distance
    VS:            Double;      // instrument height
    VC:            Double;      // target height
    HZ:            Double;      // horizontal angle [gon]
    Zuhel:         Double;      // zenith angle [gon] — named Zuhel to avoid collision with Z coordinate
    PolarD:        Double;      // polar offset (domerek)
    PolarK:        Double;      // polar perpendicular (kolmice)
    Poznamka:      string[MAX_POPIS]; // note
    KK:            Integer;     // quality code 0..8
  end;

  // Dynamic array of rows
  TGeoRowArray = array of TGeoRow;

// Resets all fields of the row to zero/empty
procedure ClearGeoRow(var ARow: TGeoRow);

// Returns a formatted dump of all fields as a string list
function PrintGeoRow(const ARow: TGeoRow; ARowIndex: Integer = -1): TStringList; overload;
// Returns a formatted dump of selected fields as a string list
function PrintGeoRow(const ARow: TGeoRow; const AFields: TGeoFields; ARowIndex: Integer = -1): TStringList; overload;

// Returns a comma-separated list of active field names
function PrintGeoFields(const Used: TGeoFields; const Asep: string = ', '): string;

// An unfilled value turns into an empty cell
function FloatCell(const V: Double): string; overload;
function FloatCell(const V: Double; const AFS: TFormatSettings): string; overload;
function FloatCell(const V: Double; const AFormat: string): string; overload;
function FloatCell(const V: Double; const AFormat: string;
  const AFS: TFormatSettings): string; overload;

// One field of a row as text, and back. These two are the only places
// that list all the fields.
function GeoFieldToText(const ARow: TGeoRow; AField: TGeoField;
  const AFormat: string; const AFS: TFormatSettings): string;
procedure TextToGeoField(var ARow: TGeoRow; AField: TGeoField;
  const AText: string; const AFS: TFormatSettings);

// Finds a field by its name from GeoFieldNames
function FindGeoField(const AName: string; out AField: TGeoField): Boolean;

// Saves one or more rows to a binary typed file
procedure SaveRow(const FileName: string; const Row: TGeoRow; Append: Boolean = False); overload;
procedure SaveRow(const FileName: string; const Rows: array of TGeoRow; Append: Boolean = False); overload;

// Loads rows from a binary typed file
function LoadRow(const FileName: string; Index: Integer = -1): TGeoRow; overload;
procedure LoadRow(const FileName: string; out Rows: TGeoRowArray); overload;

// Field name lookup table used for CSV headers
const
  GeoFieldNames: array[TGeoField] of string = (
    'Uloha','CB','X','Y','Z','CBm','Xm','Ym','Zm','TypS','SH','SS','VS','VC','HZ','Zuhel','PolarD','PolarK','Poznamka','KK'
  );

implementation

procedure ClearGeoRow(var ARow: TGeoRow);
begin
   ARow.Uloha := 0;
   ARow.CB := '';
   // NaN marks a value nobody filled in
   ARow.X := NaN ; ARow.Y := NaN; ARow.Z := NaN;
   ARow.CBm := '';
   ARow.Xm := NaN ; ARow.Ym := NaN; ARow.Zm := NaN;
   ARow.TypS := 0;
   ARow.SH := NaN;
   ARow.SS := NaN;
   ARow.VS := NaN;
   ARow.VC := NaN;
   ARow.HZ := NaN;
   ARow.Zuhel := NaN;
   ARow.PolarD := NaN;
   ARow.PolarK := NaN;
   ARow.Poznamka := '';
   ARow.KK := 0;
end;

// Overload that prints all fields — delegates to the field-mask overload
function PrintGeoRow(const ARow: TGeoRow; ARowIndex: Integer = -1): TStringList;
begin
  Result := PrintGeoRow(ARow, [Low(TGeoField)..High(TGeoField)], ARowIndex);
end;

function PrintGeoRow(const ARow: TGeoRow; const AFields: TGeoFields; ARowIndex: Integer = -1): TStringList;
var
  f: TGeoField;
  s: string;
begin
  Result := TStringList.Create;
  if ARowIndex >= 0 then
    Result.Add(Format('--- TGeoRow %d ---', [ARowIndex]))
  else
    Result.Add('--- TGeoRow ---');

  for f := Low(TGeoField) to High(TGeoField) do
    if f in AFields then
    begin
      case f of
        Uloha:    s := Format('%s: %d', [GeoFieldNames[f], ARow.Uloha]);
        CB:       s := Format('%s: %s', [GeoFieldNames[f], ARow.CB]);
        X:        s := Format('%s: %.3f', [GeoFieldNames[f], ARow.X]);
        Y:        s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Y]);
        Z:        s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Z]);
        CBm:      s := Format('%s: %s', [GeoFieldNames[f], ARow.CBm]);
        Xm:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Xm]);
        Ym:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Ym]);
        Zm:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Zm]);
        TypS:     s := Format('%s: %d', [GeoFieldNames[f], ARow.TypS]);
        SH:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.SH]);
        SS:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.SS]);
        VS:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.VS]);
        VC:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.VC]);
        HZ:       s := Format('%s: %.6f', [GeoFieldNames[f], ARow.HZ]);
        Zuhel:    s := Format('%s: %.6f', [GeoFieldNames[f], ARow.Zuhel]);
        PolarD:   s := Format('%s: %.3f', [GeoFieldNames[f], ARow.PolarD]);
        PolarK:   s := Format('%s: %.3f', [GeoFieldNames[f], ARow.PolarK]);
        Poznamka: s := Format('%s: %s', [GeoFieldNames[f], ARow.Poznamka]);
        KK:       s := Format('%s: %d', [GeoFieldNames[f], ARow.KK]);
      end;
      Result.Add(s);
    end;
end;

function PrintGeoFields(const Used: TGeoFields; const Asep: string = ', '): string;
var
  f: TGeoField;
  first: Boolean;
begin
  Result := '';
  first := True;
  for f := Low(TGeoField) to High(TGeoField) do
    if f in Used then
    begin
      if not first then
        Result := Result + Asep;
      Result := Result + GeoFieldNames[f];
      first := False;
    end;
end;

function FloatCell(const V: Double): string;
begin
  if IsNan(V) then
    Result := ''
  else
    Result := FloatToStr(V);
end;

function FloatCell(const V: Double; const AFS: TFormatSettings): string;
begin
  if IsNan(V) then
    Result := ''
  else
    Result := FloatToStr(V, AFS);
end;

function FloatCell(const V: Double; const AFormat: string): string;
begin
  if IsNan(V) then
    Result := ''
  else
    Result := FormatFloat(AFormat, V);
end;

function FloatCell(const V: Double; const AFormat: string;
  const AFS: TFormatSettings): string;
begin
  if IsNan(V) then
    Result := ''
  else if AFormat = '' then
    Result := FloatToStr(V, AFS)
  else
    Result := FormatFloat(AFormat, V, AFS);
end;

function GeoFieldToText(const ARow: TGeoRow; AField: TGeoField;
  const AFormat: string; const AFS: TFormatSettings): string;
begin
  case AField of
    Uloha:    Result := IntToStr(ARow.Uloha);
    CB:       Result := string(ARow.CB);
    X:        Result := FloatCell(ARow.X, AFormat, AFS);
    Y:        Result := FloatCell(ARow.Y, AFormat, AFS);
    Z:        Result := FloatCell(ARow.Z, AFormat, AFS);
    CBm:      Result := string(ARow.CBm);
    Xm:       Result := FloatCell(ARow.Xm, AFormat, AFS);
    Ym:       Result := FloatCell(ARow.Ym, AFormat, AFS);
    Zm:       Result := FloatCell(ARow.Zm, AFormat, AFS);
    TypS:     Result := IntToStr(ARow.TypS);
    SH:       Result := FloatCell(ARow.SH, AFormat, AFS);
    SS:       Result := FloatCell(ARow.SS, AFormat, AFS);
    VS:       Result := FloatCell(ARow.VS, AFormat, AFS);
    VC:       Result := FloatCell(ARow.VC, AFormat, AFS);
    HZ:       Result := FloatCell(ARow.HZ, AFormat, AFS);
    Zuhel:    Result := FloatCell(ARow.Zuhel, AFormat, AFS);
    PolarD:   Result := FloatCell(ARow.PolarD, AFormat, AFS);
    PolarK:   Result := FloatCell(ARow.PolarK, AFormat, AFS);
    Poznamka: Result := string(ARow.Poznamka);
    KK:       Result := IntToStr(ARow.KK);
  end;
end;

// Text that is not a number leaves the field alone, so an empty cell stays NaN
procedure TextToGeoField(var ARow: TGeoRow; AField: TGeoField;
  const AText: string; const AFS: TFormatSettings);
var
  S: string;
begin
  S := Trim(AText);
  case AField of
    Uloha:    TryStrToInt(S, ARow.Uloha);
    CB:       ARow.CB := ShortString(Copy(S, 1, MAX_CB));
    X:        TryStrToFloat(S, ARow.X, AFS);
    Y:        TryStrToFloat(S, ARow.Y, AFS);
    Z:        TryStrToFloat(S, ARow.Z, AFS);
    CBm:      ARow.CBm := ShortString(Copy(S, 1, MAX_CB));
    Xm:       TryStrToFloat(S, ARow.Xm, AFS);
    Ym:       TryStrToFloat(S, ARow.Ym, AFS);
    Zm:       TryStrToFloat(S, ARow.Zm, AFS);
    TypS:     TryStrToInt(S, ARow.TypS);
    SH:       TryStrToFloat(S, ARow.SH, AFS);
    SS:       TryStrToFloat(S, ARow.SS, AFS);
    VS:       TryStrToFloat(S, ARow.VS, AFS);
    VC:       TryStrToFloat(S, ARow.VC, AFS);
    HZ:       TryStrToFloat(S, ARow.HZ, AFS);
    Zuhel:    TryStrToFloat(S, ARow.Zuhel, AFS);
    PolarD:   TryStrToFloat(S, ARow.PolarD, AFS);
    PolarK:   TryStrToFloat(S, ARow.PolarK, AFS);
    Poznamka: ARow.Poznamka := ShortString(Copy(S, 1, MAX_POPIS));
    KK:       TryStrToInt(S, ARow.KK);
  end;
end;

function FindGeoField(const AName: string; out AField: TGeoField): Boolean;
var
  F: TGeoField;
begin
  Result := False;
  for F := Low(TGeoField) to High(TGeoField) do
    if SameText(AName, GeoFieldNames[F]) then
    begin
      AField := F;
      Exit(True);
    end;
end;

// Single-row overload — wraps the array version with one element
procedure SaveRow(const FileName: string; const Row: TGeoRow; Append: Boolean = False);
begin
  SaveRow(FileName, [Row], Append);
end;

// Writes all rows to a typed binary file; appends if Append = True
procedure SaveRow(const FileName: string; const Rows: array of TGeoRow; Append: Boolean = False);
var
  F: File of TGeoRow;
  Count: Integer;
begin
  AssignFile(F, FileName);

  // Open existing file for read/write when appending, otherwise overwrite
  if Append and FileExists(FileName) then
    Reset(F)
  else
    Rewrite(F);

  // Seek to end when appending, or to the start when overwriting
  if Append then
    Seek(F, FileSize(F))
  else
    Seek(F, 0);

  Count := Length(Rows);
  if Count > 0 then
    // BlockWrite: Rows[0] is the start of the memory block, Count is the record count
    BlockWrite(F, Rows[0], Count);

  CloseFile(F);
end;

function LoadRow(const FileName: string; Index: Integer = -1): TGeoRow;
var
  F: File of TGeoRow;  // typed file — one unit equals one TGeoRow
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('Soubor "%s" neexistuje.', [FileName]);

  AssignFile(F, FileName);
  Reset(F);

  if FileSize(F) = 0 then
    raise Exception.Create('Soubor je prázdný.');

  // Index = -1 means load the first record; otherwise validate range and seek
  if Index = -1 then
    Seek(F, 0)
  else if (Index < 0) or (Index >= FileSize(F)) then
    raise Exception.CreateFmt('Index %d je mimo rozsah (0..%d)', [Index, FileSize(F)-1])
  else
    Seek(F, Index);

  Read(F, Result);
  CloseFile(F);
end;

procedure LoadRow(const FileName: string; out Rows: TGeoRowArray);
var
  F: File of TGeoRow;
  RecCount,           // total records in file
  ReadCount: Integer; // actual records read by BlockRead
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('Soubor "%s" neexistuje.', [FileName]);

  AssignFile(F, FileName);
  Reset(F);
  try
    RecCount := FileSize(F);

    // Empty file — return an empty array
    if RecCount <= 0 then
    begin
      SetLength(Rows, 0);
      Exit;
    end;

    SetLength(Rows, RecCount);

    // Bulk read: Rows[0] is the target buffer start, RecCount is how many records to read
    BlockRead(F, Rows[0], RecCount, ReadCount);

    if ReadCount <> RecCount then
      raise Exception.CreateFmt('Načteno jen %d z %d záznamů.', [ReadCount, RecCount]);
  finally
    CloseFile(F);
  end;
end;

end.
