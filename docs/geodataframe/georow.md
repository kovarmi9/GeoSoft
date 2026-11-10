# Řádek TGeoRow

Řádek představuje jedno měření. Všechny úlohy používají stejný řádek
se stejnými 24 poli, liší se jen tím, která pole vyplní.
Unit `src/DataStructures/GeoRow.pas`.

## Pole

| pole | typ | význam |
|---|----|---|
| `Checked` | `Boolean` | použít ve výpočtu, nový řádek `True`, v zápisníku 1 a 0 |
| `CB` | `Int64` | úplné číslo bodu, 15 číslic se znaménkem, 0 = bez čísla |
| `X`, `Y`, `Z` | `Double` | souřadnice S-JTSK a výška [m] |
| `CBm` | `Int64` | číslo druhého bodu (kontrolní oměrné), zdrojového bodu (transformace), stanoviska (protínání ze směrů), 0 = bez čísla |
| `Xm`, `Ym`, `Zm` | `Double` | místní souřadnice, v transformaci a kontrolních oměrných souřadnice druhého bodu, v nivelaci čtení vzad, vpřed a boční [m] |
| `Typ` | `Integer` | typ řádku podle úlohy: v polární metodě typ délky (0 vodorovná, 2 šikmá); v transformaci role bodu (1 identický, 2 kontrolní, 3 určovaný) |
| `SH`, `SS` | `Double` | vodorovná a šikmá délka, jen kladná [m] |
| `VS`, `VC` | `Double` | výška přístroje a cíle [m] |
| `HZ`, `ZU` | `Double` | vodorovný směr a zenitový úhel [gon] |
| `Sta` | `Double` | vzdálenost podél přímky se znaménkem: v ortogonální metodě staničení, v polární metodě doměrek, v konstrukčních oměrných délka strany, + zatáčka vpravo, − vlevo [m] |
| `Kol` | `Double` | vzdálenost kolmo k přímce se znaménkem, vpravo kladná: kolmice v polární a ortogonální metodě a ve vyrovnání do přímky [m] |
| `Popis` | `string[32]` | popis bodu, při uložení bodu se z něj stane popis v seznamu |
| `KK` | `Integer` | kód kvality 0–8 |
| `M1` … `M4` | `Double` | výsledky výpočtu, význam podle úlohy, viz tabulka níže [m] |

Co je ve výstupních polích:

| úloha | `M1` | `M2` | `M3` | `M4` |
|---|---|---|---|---|
| transformace | dY | dX | – | Sxy |
| technická nivelace | oprava čtení vzad | – | převýšení | – |
| kontrolní oměrné | délka ze souřadnic | rozdíl | mezní rozdíl | vyhovuje (jen v tabulce) |

## Práce s řádkem

- `ClearGeoRow(Row)` vymaže řádek: čísla NaN, texty prázdné, celá čísla a čísla bodů 0, `Checked` True
- `IsNan(Row.X)` pozná nevyplněné číslo, porovnání s nulou nestačí
- `Row.CB = 0` pozná řádek bez čísla bodu, poznámka má nejvýš 32 znaků, delší se zkrátí
- `GeoFieldToText` zapíše číslo bodu jako 15 číslic (`000000000014001`), `TextToGeoField` přijme jen číslice s případným mínusem
- pořadí polí je dáno výčtem `TGeoField` (`Checked` = 0 … `M4` = 23)
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
