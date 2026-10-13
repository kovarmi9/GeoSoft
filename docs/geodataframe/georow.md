# Řádek TGeoRow

Jeden řádek měření nebo bodu, společný pro všechny výpočetní úlohy.
Řádky ukládá tabulka [TGeoDataFrame](geodataframe.md).
Unit: `src/DataStructures/GeoRow.pas`.

| typ | k čemu |
|---|---|
| `TGeoRow` | jeden řádek, 20 polí |
| `TGeoField` | jméno pole: `Uloha`, `CB`, `X`, … |
| `TGeoFields` | výběr polí, např. `[CB, X, Y]` |
| `TGeoRowArray` | pole řádků |

## Ukázky

### Vyplnění a čtení

```pascal
var
  r: TGeoRow;
begin
  ClearGeoRow(r);                       // čísla NaN, texty '', celá čísla 0
  r.Uloha := 1;
  r.CB := '751261478500012';
  r.X := 1045986.745;

  if IsNan(r.Y) then
    Writeln('Y není vyplněné');
end;
```

### Výpis

```pascal
Writeln(PrintGeoRow(r, [CB, X, Y]));
```

```
--- TGeoRow ---
CB: 751261478500012
X: 1045986,745
Y: NAN
```

### Na text a zpět

```pascal
S := GeoFieldToText(r, X, '0.000', FS);         // '1045986,745'
TextToGeoField(r, Y, '743841,459', FS);         // r.Y = 743841.459
TextToGeoField(r, Z, 'abc', FS);                // není číslo, r.Z zůstane NaN
```

### Binární soubor

```pascal
SaveRow('radek.bin', r);                // přepíše soubor jedním řádkem
SaveRow('radek.bin', r2, True);         // připíše druhý řádek

r := LoadRow('radek.bin');              // první řádek
r := LoadRow('radek.bin', 1);           // druhý řádek
Rows := LoadRows('radek.bin');          // všechny, Length(Rows) = 2
```

## Pole řádku

| pole | typ | význam |
|---|---|---|
| `Uloha` | `Integer` | kód úlohy (0 ortogonála, 1 polárka, 4 konstrukční oměrné, 9 kontrolní oměrné, 95 výměra) |
| `CB` | `string[15]` | číslo bodu |
| `X`, `Y`, `Z` | `Double` | souřadnice S-JTSK a výška [m] |
| `CBm` | `string[15]` | číslo druhého bodu (kontrolní oměrné) |
| `Xm`, `Ym`, `Zm` | `Double` | místní souřadnice, staničení a kolmice [m] |
| `TypS` | `Integer` | typ délky |
| `SH` | `Double` | vodorovná délka [m] |
| `SS` | `Double` | šikmá délka [m] |
| `VS`, `VC` | `Double` | výška přístroje a cíle [m] |
| `HZ` | `Double` | vodorovný úhel [gon] |
| `Zuhel` | `Double` | zenitový úhel [gon] |
| `PolarD`, `PolarK` | `Double` | polární doměrek a kolmice [m] |
| `Poznamka` | `string[32]` | poznámka |
| `KK` | `Integer` | kód kvality 0–8 |

## Prázdná hodnota

`ClearGeoRow(Row)` nastaví čísla `Double` na NaN, texty na `''`
a celá čísla na 0. Prázdné číslo se pozná přes `IsNan(Row.X)`.

!!! warning "Pozor"
    - `Row.X = 0` ani `Row.X = NaN` prázdnou hodnotu nepozná, vždy `IsNan`.
    - Nový lokální řádek obsahuje náhodná data, vždy nejdřív `ClearGeoRow`.
    - Seznam souřadnic (`TPoint`) má jako prázdnou hodnotu 0, ne NaN.

## Výběr polí

```pascal
Fields := [Uloha, CB, X, Y];
Include(Fields, KK);
if Z in Fields then ...
```

`PrintGeoFields(Fields)` vrátí názvy polí, např. `Uloha, CB, X, Y`.
Druhý parametr mění oddělovač (výchozí `', '`).

## Převod na text a zpět

Jediné dvě funkce, které vyjmenovávají všechna pole. Používá je
most grid ↔ tabulka i CSV. `AFS` určuje desetinný oddělovač.

`GeoFieldToText(Row, Field, AFormat, AFS)`:

- NaN → `''`
- `Double` → `FormatFloat(AFormat)`; při `AFormat = ''` plná přesnost
- `Integer` → `IntToStr`, text beze změny

`TextToGeoField(Row, Field, AText, AFS)`:

- text se ořízne o mezery
- když text není číslo (i prázdný), pole se nezmění, takže zůstane NaN
- text se zkrátí na 15 (`CB`, `CBm`) nebo 32 znaků (`Poznamka`)

`FindGeoField(AName, Field)` najde pole podle názvu (na velikosti
písmen nezáleží), jinak vrátí `False`.

## Filtry ve sloupcích gridu

Řádek hodnoty nekontroluje, kontroluje je grid podle
`GeoComponents/GeoFieldsDef.pas`. „Výraz“ = jde napsat i `50+50`.

| pole | vstup | filtr |
|---|---|---|
| `Uloha` | celé číslo | nejvýš 2 číslice |
| `CB`, `CBm` | celé číslo | nejvýš 15 číslic |
| `X`, `Y`, `Z`, `Xm`, `Ym`, `Zm`, `VS`, `VC`, `PolarD`, `PolarK` | výraz | 3 desetinná místa |
| `SH`, `SS` | výraz | ≥ 0, 3 desetinná místa |
| `HZ` | výraz | 6 desetinných míst, přepočte se do 0–400 |
| `Zuhel` | výraz | 0–400, 6 desetinných míst |
| `TypS` | celé číslo | 1 číslice |
| `KK` | celé číslo | 0–8 |
| `Poznamka` | text | nejvýš 32 znaků |

## Výpis řádku

`PrintGeoRow(Row)` vrátí čitelný text všech polí, `PrintGeoRow(Row, Fields)`
jen vybraných, třetí parametr přidá číslo řádku. Prázdné číslo je `NAN`.
Slouží k ladění a testům.

```pascal
Writeln(PrintGeoRow(Row, [CB, X, Y], 2));
```

```
--- TGeoRow 2 ---
CB: 751261478500012
X: 1045986,745
Y: NAN
```

## Binární soubor

Řádky se zapíšou tak, jak leží v paměti, jeden za druhým.

| volání | co dělá |
|---|---|
| `SaveRow(Soubor, Row)` | zapíše jeden řádek, soubor přepíše |
| `SaveRow(Soubor, Row, True)` | připíše řádek na konec (soubor nemusí existovat) |
| `SaveRows(Soubor, Pole, Append)` | totéž pro pole řádků |
| `Row := LoadRow(Soubor)` | přečte první řádek |
| `Row := LoadRow(Soubor, I)` | přečte řádek `I` (od 0) |
| `Pole := LoadRows(Soubor)` | přečte všechny řádky, prázdný soubor dá prázdné pole |

Soubor se zavře vždy, i při chybě. Nemá hlavičku, takže změna záznamu
`TGeoRow` staré soubory znečitelní.

## Výjimky

| kdy | hláška |
|---|---|
| soubor neexistuje (`LoadRow`, `LoadRows`) | Soubor "…" neexistuje. |
| soubor je prázdný (`LoadRow`) | Soubor je prázdný. |
| `I` mimo rozsah (`LoadRow`) | Index … je mimo rozsah (0..…) |
| soubor je kratší, než má být (`LoadRows`) | Načteno jen … z … záznamů. |
| soubor nejde otevřít nebo zapsat | `EInOutError` |

Ostatní funkce výjimky nevyhazují.
