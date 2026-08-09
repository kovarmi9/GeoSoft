unit GeoRow;

interface

uses
  System.SysUtils, System.Classes;

type
  // Enum of all supported measurement fields
  TGeoField = (
    Uloha,
    CB,
    X, Y, Z,
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
    Poznamka
  );

  // Set of selected fields
  TGeoFields = set of TGeoField;

  // Single measurement row record
  TGeoRow = record
    Uloha:         Integer;     // task type
    CB:            string[16];  // point number
    X, Y, Z:       Double;      // global coordinates
    Xm, Ym, Zm:    Double;      // local coordinates
    TypS:          Integer;     // distance type
    SH:            Double;      // horizontal distance
    SS:            Double;      // slope distance
    VS:            Double;      // instrument height
    VC:            Double;      // target height
    HZ:            Double;      // horizontal angle [gon]
    Zuhel:         Double;      // zenith angle [gon] — named Zuhel to avoid collision with Z coordinate
    PolarD:        Double;      // polar offset (doměrek)
    PolarK:        Double;      // polar perpendicular (kolmice)
    Poznamka:      string[128]; // note
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

// Saves one or more rows to a binary typed file
procedure SaveRow(const FileName: string; const Row: TGeoRow; Append: Boolean = False); overload;
procedure SaveRow(const FileName: string; const Rows: array of TGeoRow; Append: Boolean = False); overload;

// Loads rows from a binary typed file
function LoadRow(const FileName: string; Index: Integer = -1): TGeoRow; overload;
procedure LoadRow(const FileName: string; out Rows: TGeoRowArray); overload;

// Field name lookup table used for CSV headers
const
  GeoFieldNames: array[TGeoField] of string = (
    'Uloha','CB','X','Y','Z','Xm','Ym','Zm','TypS','SH','SS','VS','VC','HZ','Zuhel','PolarD','PolarK','Poznamka'
  );

implementation

procedure ClearGeoRow(var ARow: TGeoRow);
begin
   ARow.Uloha := 0;
   ARow.CB := '';
   ARow.X := 0 ; ARow.Y := 0; ARow.Z := 0;
   ARow.Xm := 0 ; ARow.Ym := 0; ARow.Zm := 0;
   ARow.TypS := 0;
   ARow.SH := 0;
   ARow.SS := 0;
   ARow.VS := 0;
   ARow.VC := 0;
   ARow.HZ := 0;
   ARow.Zuhel := 0;
   ARow.PolarD := 0;
   ARow.PolarK := 0;
   ARow.Poznamka := '';
end;

// Overload that prints all fields — delegates to the field-mask overload
function PrintGeoRow(const ARow: TGeoRow; ARowIndex: Integer = -1): TStringList;
begin
  Result := TStringList.Create;
  Result.AddStrings(PrintGeoRow(ARow, [Low(TGeoField)..High(TGeoField)], ARowIndex));
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
