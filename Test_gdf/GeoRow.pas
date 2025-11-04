unit GeoRow;

interface


uses
  System.SysUtils;

type
// Pole v masce
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

//    procedure Clear;
  end;

procedure ClearGeoRow(var R: TGeoRow);

procedure PrintGeoRow(const R: TGeoRow); overload; // výpis všech polí

procedure PrintGeoRow(const R: TGeoRow; const Fields: TGeoFields); overload;  // výpis vybraných polí

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


//procedure TGeoRow.Clear;
//begin
//   Uloha := 0;
//   CB := '';
//   X := 0 ; Y := 0; Z := 0;
//   Xm := 0 ; Ym := 0; Zm := 0;
//   TypS := 0;
//   SH := 0;
//   SS := 0;
//   VS := 0;
//   VC := 0;
//   HZ := 0;
//   Zuhel := 0;
//   PolarD := 0;
//   PolarK := 0;
//   Poznamka := '';
//end;

procedure PrintGeoRow(const R: TGeoRow);
begin
  Writeln('--- TGeoRow ---');
  Writeln(Format('Uloha   : %d', [R.Uloha]));
  Writeln(Format('CB      : %s', [R.CB]));
  Writeln(Format('X,Y,Z   : %.3f; %.3f; %.3f', [R.X, R.Y, R.Z]));
  Writeln(Format('Xm,Ym,Zm: %.3f; %.3f; %.3f', [R.Xm, R.Ym, R.Zm]));
  Writeln(Format('TypS    : %d', [R.TypS]));
  Writeln(Format('SH, SS  : %.3f; %.3f', [R.SH, R.SS]));
  Writeln(Format('VS, VC  : %.3f; %.3f', [R.VS, R.VC]));
  Writeln(Format('HZ, Z   : %.6f; %.6f', [R.HZ, R.Zuhel]));
  Writeln(Format('PolarD/K: %.3f; %.3f', [R.PolarD, R.PolarK]));
  Writeln(Format('Poznámka: %s', [R.Poznamka]));
  Writeln;
end;


procedure PrintGeoRow(const R: TGeoRow; const Fields: TGeoFields);
begin
  Writeln('--- TGeoRow ---');
  if Uloha in Fields then Writeln(Format('Uloha   : %d', [R.Uloha]));
  if CB in Fields then Writeln(Format('CB      : %s', [R.CB]));
  if X in Fields then Writeln(Format('X       : %.3f', [R.X]));
  if Y in Fields then Writeln(Format('Y       : %.3f', [R.Y]));
  if Z in Fields then Writeln(Format('Z       : %.3f', [R.Z]));
  if Xm in Fields then Writeln(Format('Xm      : %.3f', [R.Xm]));
  if Ym in Fields then Writeln(Format('Ym      : %.3f', [R.Ym]));
  if Zm in Fields then Writeln(Format('Zm      : %.3f', [R.Zm]));
  if TypS in Fields then Writeln(Format('TypS    : %d', [R.TypS]));
  if SH in Fields then Writeln(Format('SH      : %.3f', [R.SH]));
  if SS in Fields then Writeln(Format('SS      : %.3f', [R.SS]));
  if VS in Fields then Writeln(Format('VS      : %.3f', [R.VS]));
  if VC in Fields then Writeln(Format('VC      : %.3f', [R.VC]));
  if HZ in Fields then Writeln(Format('HZ      : %.6f', [R.HZ]));
  if Zuhel in Fields then Writeln(Format('Zuhel   : %.6f', [R.Zuhel]));
  if PolarD in Fields then Writeln(Format('PolarD  : %.3f', [R.PolarD]));
  if PolarK in Fields then Writeln(Format('PolarK  : %.3f', [R.PolarK]));
  if Poznamka in Fields then Writeln(Format('Poznámka: %s', [R.Poznamka]));
  Writeln;
end;


end.
