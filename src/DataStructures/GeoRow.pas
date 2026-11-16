unit GeoRow;

// One row of a task notebook, its fields and binary file.

interface

uses
  System.SysUtils, System.Math, Validation, PointNumber;

type
  /// <summary>All fields of a row.</summary>
  TGeoField = (
    Checked,
    CB,
    X, Y, Z,
    CBm,
    Xm, Ym, Zm,
    Typ,
    SH,
    SS,
    VS,
    VC,
    HZ,
    ZU,
    Sta,
    Kol,
    Popis,
    KK,
    M1,
    M2,
    M3,
    M4
  );

  /// <summary>A choice of fields, e.g. [CB, X, Y].</summary>
  TGeoFields = set of TGeoField;

  /// <summary>What a field holds, a grid picks its column type by it.</summary>
  TGeoFieldKind = (
    fkPointNumber,   // up to 15 digits and a minus sign
    fkInteger,       // whole number
    fkText,          // any text
    fkNumber,        // typed number, an expression is allowed
    fkResult         // number the program fills
  );

  /// <summary>Everything known about one field.</summary>
  TGeoFieldInfo = record
    Name:          string;    // in CSV and in ColumnFields
    Caption:       string;    // default column header
    Kind:          TGeoFieldKind;
    DecimalPlaces: Integer;   // shown, numbers only
    MaxLength:     Integer;   // characters, 0 = no limit
    HasMinValue:   Boolean;
    MinValue:      Double;
    HasMaxValue:   Boolean;
    MaxValue:      Double;
    WrapAt:        Double;    // 400 for a direction in gon
  end;

  /// <summary>One measurement of a task.</summary>
  TGeoRow = packed record
    Checked:    Boolean;                  // used in the calculation
    CB:         Int64;                    // full point number, 0 = none
    X, Y, Z:    Double;                   // global coordinates
    CBm:        Int64;                    // second point number, 0 = none
    Xm, Ym, Zm: Double;                   // local, second point or readings
    Typ:        Integer;                  // row type, meaning by task
    SH:         Double;                   // horizontal distance
    SS:         Double;                   // slope distance
    VS:         Double;                   // instrument height
    VC:         Double;                   // target height
    HZ:         Double;                   // horizontal direction [gon]
    ZU:         Double;                   // zenith angle [gon]
    Sta:        Double;                   // along the line or side, signed
    Kol:        Double;                   // across the line, signed (kolmice)
    Popis:      string[MAX_POPIS_LENGTH]; // point description
    KK:         Integer;                  // quality code, 0 = none
    M1:         Double;                   // results, meaning by task
    M2:         Double;
    M3:         Double;
    M4:         Double;
  end;

  /// <summary>Array of rows.</summary>
  TGeoRowArray = array of TGeoRow;

/// <summary>Empties the row: numbers NaN, texts '', integers 0, Checked True.</summary>
procedure ClearGeoRow(var ARow: TGeoRow);

/// <summary>Readable dump of the row, one field per line.</summary>
function PrintGeoRow(const ARow: TGeoRow; ARowIndex: Integer = -1): string; overload;
/// <summary>Readable dump of the chosen fields of the row.</summary>
function PrintGeoRow(const ARow: TGeoRow; const AFields: TGeoFields; ARowIndex: Integer = -1): string; overload;

/// <summary>Names of the fields, separated by ASep.</summary>
function PrintGeoFields(const AFields: TGeoFields; const ASep: string = ', '): string;

/// <summary>One field as text. NaN gives ''.</summary>
function GeoFieldToText(const ARow: TGeoRow; AField: TGeoField; const AFormat: string; const AFS: TFormatSettings): string;
/// <summary>Text into one field. Non-number text keeps the field.</summary>
procedure TextToGeoField(var ARow: TGeoRow; AField: TGeoField; const AText: string; const AFS: TFormatSettings);

/// <summary>Finds a field by its name. Case does not matter.</summary>
function FindGeoField(const AName: string; out AField: TGeoField): Boolean;

/// <summary>Writes one row to a file. AAppend adds it at the end.</summary>
procedure SaveRow(const AFileName: string; const ARow: TGeoRow; AAppend: Boolean = False);
/// <summary>Writes rows to a file. AAppend adds them at the end.</summary>
procedure SaveRows(const AFileName: string; const ARows: array of TGeoRow; AAppend: Boolean = False);

/// <summary>Reads row AIndex from a file, the first one by default.</summary>
function LoadRow(const AFileName: string; AIndex: Integer = 0): TGeoRow;
/// <summary>Reads all rows from a file.</summary>
function LoadRows(const AFileName: string): TGeoRowArray;

const
  /// <summary>Catalogue of the fields, in TGeoField order.</summary>
  GeoFieldInfo: array[TGeoField] of TGeoFieldInfo = (
    (Name: 'Checked'; Caption: 'Použít';            Kind: fkInteger; MaxLength: 1;
      HasMinValue: True; HasMaxValue: True; MaxValue: 1),
    (Name: 'CB';      Caption: 'Číslo bodu';        Kind: fkPointNumber),
    (Name: 'X';       Caption: 'X';                 Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'Y';       Caption: 'Y';                 Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'Z';       Caption: 'Z';                 Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'CBm';     Caption: 'Číslo bodu zdroj';  Kind: fkPointNumber),
    (Name: 'Xm';      Caption: 'Xm';                Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'Ym';      Caption: 'Ym';                Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'Zm';      Caption: 'Zm';                Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'Typ';     Caption: 'Typ';               Kind: fkInteger; MaxLength: 1),
    (Name: 'SH';      Caption: 'Vodorovná délka';   Kind: fkNumber;  DecimalPlaces: 2; HasMinValue: True),
    (Name: 'SS';      Caption: 'Šikmá délka';       Kind: fkNumber;  DecimalPlaces: 2; HasMinValue: True),
    (Name: 'VS';      Caption: 'Výška přístroje';   Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'VC';      Caption: 'Výška cíle';        Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'HZ';      Caption: 'HZ úhel [g]';       Kind: fkNumber;  DecimalPlaces: 4; WrapAt: 400),
    (Name: 'ZU';      Caption: 'Zenitový úhel [g]'; Kind: fkNumber;  DecimalPlaces: 4;
      HasMinValue: True; HasMaxValue: True; MaxValue: 400),
    (Name: 'Sta';     Caption: 'Polární doměrek';   Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'Kol';     Caption: 'Polární kolmice';   Kind: fkNumber;  DecimalPlaces: 2),
    (Name: 'Popis';   Caption: 'Popis';             Kind: fkText;    MaxLength: MAX_POPIS_LENGTH),
    (Name: 'KK';      Caption: 'Kód kvality';       Kind: fkInteger; MaxLength: 1;
      HasMinValue: True; MinValue: MIN_KK; HasMaxValue: True; MaxValue: MAX_KK),
    (Name: 'M1';      Caption: 'M1';                Kind: fkResult;  DecimalPlaces: 2),
    (Name: 'M2';      Caption: 'M2';                Kind: fkResult;  DecimalPlaces: 2),
    (Name: 'M3';      Caption: 'M3';                Kind: fkResult;  DecimalPlaces: 2),
    (Name: 'M4';      Caption: 'M4';                Kind: fkResult;  DecimalPlaces: 2)
  );

implementation

procedure ClearGeoRow(var ARow: TGeoRow);
begin
  ARow.Checked := True;     // a new row is used
  ARow.CB := 0;
  // NaN marks a value nobody filled in
  ARow.X := NaN; ARow.Y := NaN; ARow.Z := NaN;
  ARow.CBm := 0;
  ARow.Xm := NaN; ARow.Ym := NaN; ARow.Zm := NaN;
  ARow.Typ := 0;
  ARow.SH := NaN;
  ARow.SS := NaN;
  ARow.VS := NaN;
  ARow.VC := NaN;
  ARow.HZ := NaN;
  ARow.ZU := NaN;
  ARow.Sta := NaN;
  ARow.Kol := NaN;
  ARow.Popis := '';
  ARow.KK := 0;
  ARow.M1 := NaN; ARow.M2 := NaN; ARow.M3 := NaN; ARow.M4 := NaN;
end;

// All fields, no mask
function PrintGeoRow(const ARow: TGeoRow; ARowIndex: Integer): string;
begin
  Result := PrintGeoRow(ARow, [Low(TGeoField)..High(TGeoField)], ARowIndex);
end;

// Angles need more places
function PrintGeoRow(const ARow: TGeoRow; const AFields: TGeoFields; ARowIndex: Integer): string;
var
  F: TGeoField;
  Mask: string;
begin
  if ARowIndex >= 0 then
    Result := Format('--- TGeoRow %d ---', [ARowIndex]) + sLineBreak
  else
    Result := '--- TGeoRow ---' + sLineBreak;

  for F := Low(TGeoField) to High(TGeoField) do
    if F in AFields then
    begin
      if F in [HZ, ZU] then
        Mask := '0.000000'
      else
        Mask := '0.000';
      Result := Result + GeoFieldInfo[F].Name + ': ' +
        GeoFieldToText(ARow, F, Mask, FormatSettings) + sLineBreak;
    end;
end;

function PrintGeoFields(const AFields: TGeoFields; const ASep: string): string;
var
  F: TGeoField;
  First: Boolean;
begin
  Result := '';
  First := True;
  for F := Low(TGeoField) to High(TGeoField) do
    if F in AFields then
    begin
      if not First then
        Result := Result + ASep;
      Result := Result + GeoFieldInfo[F].Name;
      First := False;
    end;
end;

// NaN gives empty text
function FloatCell(const AValue: Double; const AFormat: string; const AFS: TFormatSettings): string;
begin
  if IsNan(AValue) then
    Result := ''
  else if AFormat = '' then
    Result := FloatToStr(AValue, AFS)
  else
    Result := FormatFloat(AFormat, AValue, AFS);
end;

function GeoFieldToText(const ARow: TGeoRow; AField: TGeoField; const AFormat: string; const AFS: TFormatSettings): string;
begin
  case AField of
    Checked:  Result := IntToStr(Ord(ARow.Checked));
    CB:       Result := TPointNumber.ToText(ARow.CB);
    X:        Result := FloatCell(ARow.X, AFormat, AFS);
    Y:        Result := FloatCell(ARow.Y, AFormat, AFS);
    Z:        Result := FloatCell(ARow.Z, AFormat, AFS);
    CBm:      Result := TPointNumber.ToText(ARow.CBm);
    Xm:       Result := FloatCell(ARow.Xm, AFormat, AFS);
    Ym:       Result := FloatCell(ARow.Ym, AFormat, AFS);
    Zm:       Result := FloatCell(ARow.Zm, AFormat, AFS);
    Typ:      Result := IntToStr(ARow.Typ);
    SH:       Result := FloatCell(ARow.SH, AFormat, AFS);
    SS:       Result := FloatCell(ARow.SS, AFormat, AFS);
    VS:       Result := FloatCell(ARow.VS, AFormat, AFS);
    VC:       Result := FloatCell(ARow.VC, AFormat, AFS);
    HZ:       Result := FloatCell(ARow.HZ, AFormat, AFS);
    ZU:       Result := FloatCell(ARow.ZU, AFormat, AFS);
    Sta:      Result := FloatCell(ARow.Sta, AFormat, AFS);
    Kol:      Result := FloatCell(ARow.Kol, AFormat, AFS);
    Popis:    Result := string(ARow.Popis);
    KK:       Result := IntToStr(ARow.KK);
    M1:       Result := FloatCell(ARow.M1, AFormat, AFS);
    M2:       Result := FloatCell(ARow.M2, AFormat, AFS);
    M3:       Result := FloatCell(ARow.M3, AFormat, AFS);
    M4:       Result := FloatCell(ARow.M4, AFormat, AFS);
  end;
end;

// Text that is not a number leaves the field alone, so an empty cell stays NaN
procedure TextToGeoField(var ARow: TGeoRow; AField: TGeoField; const AText: string; const AFS: TFormatSettings);
var
  S: string;
  N: Integer;
  P: Int64;
begin
  S := Trim(AText);
  case AField of
    Checked:  if (S = '0') or (S = '1') then ARow.Checked := S = '1';
    CB:       if TPointNumber.TryParse(S, P) then ARow.CB := P;
    X:        TryStrToFloat(S, ARow.X, AFS);
    Y:        TryStrToFloat(S, ARow.Y, AFS);
    Z:        TryStrToFloat(S, ARow.Z, AFS);
    CBm:      if TPointNumber.TryParse(S, P) then ARow.CBm := P;
    Xm:       TryStrToFloat(S, ARow.Xm, AFS);
    Ym:       TryStrToFloat(S, ARow.Ym, AFS);
    Zm:       TryStrToFloat(S, ARow.Zm, AFS);
    Typ:      if TryStrToInt(S, N) then ARow.Typ := N;
    SH:       TryStrToFloat(S, ARow.SH, AFS);
    SS:       TryStrToFloat(S, ARow.SS, AFS);
    VS:       TryStrToFloat(S, ARow.VS, AFS);
    VC:       TryStrToFloat(S, ARow.VC, AFS);
    HZ:       TryStrToFloat(S, ARow.HZ, AFS);
    ZU:       TryStrToFloat(S, ARow.ZU, AFS);
    Sta:      TryStrToFloat(S, ARow.Sta, AFS);
    Kol:      TryStrToFloat(S, ARow.Kol, AFS);
    Popis:    ARow.Popis := ShortString(Copy(S, 1, MAX_POPIS_LENGTH));
    KK:       if TryStrToInt(S, N) then ARow.KK := N;
    M1:       TryStrToFloat(S, ARow.M1, AFS);
    M2:       TryStrToFloat(S, ARow.M2, AFS);
    M3:       TryStrToFloat(S, ARow.M3, AFS);
    M4:       TryStrToFloat(S, ARow.M4, AFS);
  end;
end;

function FindGeoField(const AName: string; out AField: TGeoField): Boolean;
var
  F: TGeoField;
begin
  Result := False;
  for F := Low(TGeoField) to High(TGeoField) do
    if SameText(AName, GeoFieldInfo[F].Name) then
    begin
      AField := F;
      Exit(True);
    end;
end;

type
  TGeoRowFile = File of TGeoRow;

// Opens an existing file for reading only, so read-only files open too
procedure OpenForReading(var F: TGeoRowFile; const AFileName: string);
var
  OldMode: Byte;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt('Soubor "%s" neexistuje.', [AFileName]);

  AssignFile(F, AFileName);
  OldMode := FileMode;
  FileMode := fmOpenRead;      // Reset opens by the global FileMode
  try
    Reset(F);
  finally
    FileMode := OldMode;
  end;
end;

procedure SaveRow(const AFileName: string; const ARow: TGeoRow; AAppend: Boolean);
begin
  SaveRows(AFileName, [ARow], AAppend);
end;

procedure SaveRows(const AFileName: string; const ARows: array of TGeoRow; AAppend: Boolean);
var
  F: TGeoRowFile;
begin
  AssignFile(F, AFileName);
  if AAppend and FileExists(AFileName) then
    Reset(F)
  else
    Rewrite(F);
  try
    Seek(F, FileSize(F));    // write after the last row (a new file is empty)
    if Length(ARows) > 0 then
      BlockWrite(F, ARows[0], Length(ARows));
  finally
    CloseFile(F);
  end;
end;

function LoadRow(const AFileName: string; AIndex: Integer): TGeoRow;
var
  F: TGeoRowFile;
begin
  OpenForReading(F, AFileName);
  try
    if FileSize(F) = 0 then
      raise Exception.Create('Soubor je prázdný.');
    if (AIndex < 0) or (AIndex >= FileSize(F)) then
      raise Exception.CreateFmt('Index %d je mimo rozsah (0..%d).',
        [AIndex, FileSize(F) - 1]);

    Seek(F, AIndex);
    Read(F, Result);
  finally
    CloseFile(F);
  end;
end;

function LoadRows(const AFileName: string): TGeoRowArray;
var
  F: TGeoRowFile;
  Count, Done: Integer;
begin
  OpenForReading(F, AFileName);
  try
    Count := FileSize(F);
    SetLength(Result, Count);
    if Count > 0 then
    begin
      BlockRead(F, Result[0], Count, Done);
      if Done <> Count then
        raise Exception.CreateFmt('Načteno jen %d z %d záznamů.',
          [Done, Count]);
    end;
  finally
    CloseFile(F);
  end;
end;

end.
