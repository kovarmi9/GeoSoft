unit GeoRow;

interface

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

procedure GeoRowClear(var R: TGeoRow);

implementation

procedure GeoRowClear(var R: TGeoRow);
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

end.
