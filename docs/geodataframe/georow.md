# Řádek TGeoRow

Řádek představuje jedno měření. Všechny úlohy používají stejný řádek
se stejnými 20 poli, liší se jen kódem úlohy (`Uloha`) a tím, která pole vyplní.
Unit `src/DataStructures/GeoRow.pas`.

## Pole

| pole | typ | význam |
|---|----|---|
| `Uloha` | `Integer` | kód úlohy|
| `CB` | `string[16]` | číslo bodu (15 číslic a znaménko) |
| `X`, `Y`, `Z` | `Double` | souřadnice S-JTSK a výška [m] |
| `CBm` | `string[16]` | číslo druhého bodu (kontrolní oměrné) |
| `Xm`, `Ym`, `Zm` | `Double` | místní souřadnice, staničení a kolmice [m] |
| `TypS` | `Integer` | typ délky |
| `SH`, `SS` | `Double` | vodorovná a šikmá délka [m] |
| `VS`, `VC` | `Double` | výška přístroje a cíle [m] |
| `HZ`, `Zuhel` | `Double` | vodorovný a zenitový úhel [gon] |
| `PolarD` | `Double` | polární doměrek [m] |
| `PolarK` | `Double` | polární kolmice [m] |
| `Poznamka` | `string[32]` | poznámka |
| `KK` | `Integer` | kód kvality 0–8 |

## Práce s řádkem

- `ClearGeoRow(Row)` vymaže řádek: čísla NaN, texty prázdné, celá čísla 0
- `IsNan(Row.X)` pozná nevyplněné číslo, porovnání s nulou nestačí
- číslo bodu má nejvýš 16 znaků, poznámka 32, delší text se zkrátí
- pořadí polí je dáno výčtem `TGeoField` (`Uloha` = 0 … `KK` = 19)
- `GeoFieldToText(Row, X, '0.000', FS)` vrátí pole jako text, NaN dá prázdný text
- `TextToGeoField(Row, Y, '743841,459', FS)` zapíše text do pole, co není číslo, pole nezmění
- `FindGeoField('x', F)` najde pole podle názvu, na velikosti písmen nezáleží
- `PrintGeoRow(Row)` vypíše řádek pro ladění, nevyplněné číslo jako `NAN`
- řádek hodnoty nekontroluje, kontroluje je grid při psaní

## Soubor

- `SaveRow(Soubor, Row)` zapíše řádek a soubor přepíše, `SaveRow(Soubor, Row, True)` připíše na konec
- `SaveRows(Soubor, Pole)` totéž pro více řádků
- `LoadRow(Soubor, I)` přečte řádek `I` (od 0), `LoadRows(Soubor)` všechny
- soubor se vždy zavře, i při chybě, chyba má českou hlášku
