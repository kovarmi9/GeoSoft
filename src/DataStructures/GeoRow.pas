unit GeoRow;

interface

uses
  System.SysUtils, System.Math;

const
  MAX_CB    = 16;   // point number length: 15 digits and a minus sign
  MAX_POPIS = 32;   // description length

type
  /// <summary>All fields of a row.</summary>
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

  /// <summary>A choice of fields, e.g. [CB, X, Y].</summary>
  TGeoFields = set of TGeoField;

  /// <summary>One measurement of a task.</summary>
  TGeoRow = packed record
    Uloha:         Integer;           // task type
    CB:            string[MAX_CB];    // point number
    X, Y, Z:       Double;            // global coordinates
    CBm:           string[MAX_CB];    // source point number
    Xm, Ym, Zm:    Double;            // local coordinates
    TypS:          Integer;           // distance type
    SH:            Double;            // horizontal distance
    SS:            Double;            // slope distance
    VS:            Double;            // instrument height
    VC:            Double;            // target height
    HZ:            Double;            // horizontal angle [gon]
    Zuhel:         Double;            // zenith angle [gon]
    PolarD:        Double;            // polar offset (domerek)
    PolarK:        Double;            // polar perpendicular (kolmice)
    Poznamka:      string[MAX_POPIS]; // note
    KK:            Integer;           // quality code 0..8
  end;

  /// <summary>Array of rows.</summary>
  TGeoRowArray = array of TGeoRow;

/// <summary>Empties the row: numbers NaN, texts '', integers 0.</summary>
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
  /// <summary>Field names for CSV and printouts, in TGeoField order.</summary>
  GeoFieldNames: array[TGeoField] of string = (
    'Uloha','CB','X','Y','Z','CBm','Xm','Ym','Zm','TypS','SH','SS','VS','VC','HZ','Zuhel','PolarD','PolarK','Poznamka','KK'
  );

implementation

procedure ClearGeoRow(var ARow: TGeoRow);
begin
  ARow.Uloha := 0;
  ARow.CB := '';
  // NaN marks a value nobody filled in
  ARow.X := NaN; ARow.Y := NaN; ARow.Z := NaN;
  ARow.CBm := '';
  ARow.Xm := NaN; ARow.Ym := NaN; ARow.Zm := NaN;
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

// Overload that prints all fields - calls the field-mask overload
function PrintGeoRow(const ARow: TGeoRow; ARowIndex: Integer): string;
begin
  Result := PrintGeoRow(ARow, [Low(TGeoField)..High(TGeoField)], ARowIndex);
end;

function PrintGeoRow(const ARow: TGeoRow; const AFields: TGeoFields; ARowIndex: Integer): string;
var
  F: TGeoField;
  S: string;
begin
  if ARowIndex >= 0 then
    Result := Format('--- TGeoRow %d ---', [ARowIndex]) + sLineBreak
  else
    Result := '--- TGeoRow ---' + sLineBreak;

  for F := Low(TGeoField) to High(TGeoField) do
    if F in AFields then
    begin
      case F of
        Uloha:    S := Format('%s: %d', [GeoFieldNames[F], ARow.Uloha]);
        CB:       S := Format('%s: %s', [GeoFieldNames[F], ARow.CB]);
        X:        S := Format('%s: %.3f', [GeoFieldNames[F], ARow.X]);
        Y:        S := Format('%s: %.3f', [GeoFieldNames[F], ARow.Y]);
        Z:        S := Format('%s: %.3f', [GeoFieldNames[F], ARow.Z]);
        CBm:      S := Format('%s: %s', [GeoFieldNames[F], ARow.CBm]);
        Xm:       S := Format('%s: %.3f', [GeoFieldNames[F], ARow.Xm]);
        Ym:       S := Format('%s: %.3f', [GeoFieldNames[F], ARow.Ym]);
        Zm:       S := Format('%s: %.3f', [GeoFieldNames[F], ARow.Zm]);
        TypS:     S := Format('%s: %d', [GeoFieldNames[F], ARow.TypS]);
        SH:       S := Format('%s: %.3f', [GeoFieldNames[F], ARow.SH]);
        SS:       S := Format('%s: %.3f', [GeoFieldNames[F], ARow.SS]);
        VS:       S := Format('%s: %.3f', [GeoFieldNames[F], ARow.VS]);
        VC:       S := Format('%s: %.3f', [GeoFieldNames[F], ARow.VC]);
        HZ:       S := Format('%s: %.6f', [GeoFieldNames[F], ARow.HZ]);
        Zuhel:    S := Format('%s: %.6f', [GeoFieldNames[F], ARow.Zuhel]);
        PolarD:   S := Format('%s: %.3f', [GeoFieldNames[F], ARow.PolarD]);
        PolarK:   S := Format('%s: %.3f', [GeoFieldNames[F], ARow.PolarK]);
        Poznamka: S := Format('%s: %s', [GeoFieldNames[F], ARow.Poznamka]);
        KK:       S := Format('%s: %d', [GeoFieldNames[F], ARow.KK]);
      end;
      Result := Result + S + sLineBreak;
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
      Result := Result + GeoFieldNames[F];
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
procedure TextToGeoField(var ARow: TGeoRow; AField: TGeoField; const AText: string; const AFS: TFormatSettings);
var
  S: string;
  N: Integer;
begin
  S := Trim(AText);
  case AField of
    Uloha:    if TryStrToInt(S, N) then ARow.Uloha := N;
    CB:       ARow.CB := ShortString(Copy(S, 1, MAX_CB));
    X:        TryStrToFloat(S, ARow.X, AFS);
    Y:        TryStrToFloat(S, ARow.Y, AFS);
    Z:        TryStrToFloat(S, ARow.Z, AFS);
    CBm:      ARow.CBm := ShortString(Copy(S, 1, MAX_CB));
    Xm:       TryStrToFloat(S, ARow.Xm, AFS);
    Ym:       TryStrToFloat(S, ARow.Ym, AFS);
    Zm:       TryStrToFloat(S, ARow.Zm, AFS);
    TypS:     if TryStrToInt(S, N) then ARow.TypS := N;
    SH:       TryStrToFloat(S, ARow.SH, AFS);
    SS:       TryStrToFloat(S, ARow.SS, AFS);
    VS:       TryStrToFloat(S, ARow.VS, AFS);
    VC:       TryStrToFloat(S, ARow.VC, AFS);
    HZ:       TryStrToFloat(S, ARow.HZ, AFS);
    Zuhel:    TryStrToFloat(S, ARow.Zuhel, AFS);
    PolarD:   TryStrToFloat(S, ARow.PolarD, AFS);
    PolarK:   TryStrToFloat(S, ARow.PolarK, AFS);
    Poznamka: ARow.Poznamka := ShortString(Copy(S, 1, MAX_POPIS));
    KK:       if TryStrToInt(S, N) then ARow.KK := N;
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
