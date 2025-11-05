unit GeoRow;

interface


uses
  System.SysUtils, Classes;

type
// Vybraná pole
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
TGeoFields = set of TGeoField;

// Record
  TGeoRow = record
    Uloha:         ShortInt;
    CB:            string;
    X, Y, Z:       Double;      // souøadnice
    Xm, Ym, Zm:    Double;      // místní souøadnice
    TypS:          ShortInt;    // typ délky S
    SH:            Double;      // vodorovná vzdálenost
    SS:            Double;      // šikmá vzdálenost
    VS:            Double;      // výška stroje
    VC:            Double;      // výška cíle
    HZ:            Double;      // HZ úhel [°]
    Zuhel:         Double;      // z (svislý) [°] – pojmenováno Zuhel kvùli kolizi se souøadnicí Z
    PolarD:        Double;      // polární domìrek
    PolarK:        Double;      // polární kolmice
    Poznamka:      string;      // poznámka
  end;

procedure ClearGeoRow(var R: TGeoRow);

function PrintGeoRow(const R: TGeoRow; RowIndex: Integer = -1): TStringList; overload; // výpis všech polí
function PrintGeoRow(const R: TGeoRow; const Fields: TGeoFields; RowIndex: Integer = -1): TStringList; overload; // výpis vybraných polí

function PrintGeoFields(const Used: TGeoFields): string;

// --- v interface èásti GeoRow.pas ---
const
  GeoFieldNames: array[TGeoField] of string = (
    'Uloha','CB','X','Y','Z','Xm','Ym','Zm','TypS','SH','SS',
    'VS','VC','HZ','Zuhel','PolarD','PolarK','Poznamka'
  );

implementation

procedure ClearGeoRow(var R: TGeoRow);
begin
   R.Uloha := 0;
   R.CB := '';
   R.X := 0 ; R.Y := 0; R.Z := 0;
   R.Xm := 0 ; R.Ym := 0; R.Zm := 0;
   R.TypS := 0;
   R.SH := 0;
   R.SS := 0;
   R.VS := 0;
   R.VC := 0;
   R.HZ := 0;
   R.Zuhel := 0;
   R.PolarD := 0;
   R.PolarK := 0;
   R.Poznamka := '';
end;

function PrintGeoRow(const R: TGeoRow; RowIndex: Integer = -1): TStringList;
begin
  Result := TStringList.Create;
  if RowIndex >= 0 then
      Result.Add(Format('--- TGeoRow %d ---', [RowIndex]))
    else
      Result.Add('--- TGeoRow ---');
  Result := TStringList.Create;
  Result.Add('--- TGeoRow ---');
  Result.Add(Format('Uloha   : %d', [R.Uloha]));
  Result.Add(Format('CB      : %s', [R.CB]));
  Result.Add(Format('X,Y,Z   : %.3f; %.3f; %.3f', [R.X, R.Y, R.Z]));
  Result.Add(Format('Xm,Ym,Zm: %.3f; %.3f; %.3f', [R.Xm, R.Ym, R.Zm]));
  Result.Add(Format('TypS    : %d', [R.TypS]));
  Result.Add(Format('SH, SS  : %.3f; %.3f', [R.SH, R.SS]));
  Result.Add(Format('VS, VC  : %.3f; %.3f', [R.VS, R.VC]));
  Result.Add(Format('HZ, Z   : %.6f; %.6f', [R.HZ, R.Zuhel]));
  Result.Add(Format('PolarD/K: %.3f; %.3f', [R.PolarD, R.PolarK]));
  Result.Add(Format('Poznámka: %s', [R.Poznamka]));
end;

function PrintGeoRow(const R: TGeoRow; const Fields: TGeoFields; RowIndex: Integer = -1): TStringList;
begin
  Result := TStringList.Create;
  if RowIndex >= 0 then
      Result.Add(Format('--- TGeoRow %d ---', [RowIndex]))
    else
      Result.Add('--- TGeoRow ---');
  if Uloha in Fields then Result.Add(Format('Uloha   : %d', [R.Uloha]));
  if CB in Fields then Result.Add(Format('CB      : %s', [R.CB]));
  if X in Fields then Result.Add(Format('X       : %.3f', [R.X]));
  if Y in Fields then Result.Add(Format('Y       : %.3f', [R.Y]));
  if Z in Fields then Result.Add(Format('Z       : %.3f', [R.Z]));
  if Xm in Fields then Result.Add(Format('Xm      : %.3f', [R.Xm]));
  if Ym in Fields then Result.Add(Format('Ym      : %.3f', [R.Ym]));
  if Zm in Fields then Result.Add(Format('Zm      : %.3f', [R.Zm]));
  if TypS in Fields then Result.Add(Format('TypS    : %d', [R.TypS]));
  if SH in Fields then Result.Add(Format('SH      : %.3f', [R.SH]));
  if SS in Fields then Result.Add(Format('SS      : %.3f', [R.SS]));
  if VS in Fields then Result.Add(Format('VS      : %.3f', [R.VS]));
  if VC in Fields then Result.Add(Format('VC      : %.3f', [R.VC]));
  if HZ in Fields then Result.Add(Format('HZ      : %.6f', [R.HZ]));
  if Zuhel in Fields then Result.Add(Format('Zuhel   : %.6f', [R.Zuhel]));
  if PolarD in Fields then Result.Add(Format('PolarD  : %.3f', [R.PolarD]));
  if PolarK in Fields then Result.Add(Format('PolarK  : %.3f', [R.PolarK]));
  if Poznamka in Fields then Result.Add(Format('Poznámka: %s', [R.Poznamka]));
end;

//function PrintGeoFields(const Used: TGeoFields): TStringList;
//var
//  f: TGeoField;
//begin
//  Result := TStringList.Create;
//  for f := Low(TGeoField) to High(TGeoField) do
//    if f in Used then
//      Result.Add(GeoFieldNames[f]);
//end;

function PrintGeoFields(const Used: TGeoFields): string;
var
  f: TGeoField;
begin
  //Result := '';
  for f := Low(TGeoField) to High(TGeoField) do
    if f in Used then
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + GeoFieldNames[f];
    end;
end;

end.
