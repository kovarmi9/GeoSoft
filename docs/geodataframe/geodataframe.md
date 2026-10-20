# Tabulka TGeoDataFrame

Tabulka drží řádky [TGeoRow](georow.md) jedné úlohy a výběr polí, která úloha
používá. Unit `src/DataStructures/GeoDataFrame.pas`.

## Vlastnosti

| vlastnost | význam |
|---|---|
| `Count` | počet řádků |
| `Capacity` | kolik řádků se vejde bez zvětšení pole |
| `Fields` | pole, která úloha používá |
| `Rows` | řádky, `Rows[I]` pro `I` od 0 do `Count - 1` |

## Řádky a kapacita

- pole řádků má obvykle víc místa, než je řádků, když místo dojde, zdvojnásobí se (1, 2, 4, 8 …)
- přidání řádku je tak rychlé i u desetitisíců bodů (amortizovaná složitost O(1))
- řádky se proto procházejí `for I := 0 to Count - 1`, ne podle délky pole

## Práce s tabulkou

- `Create([Uloha, CB, X, Y])` vytvoří prázdnou tabulku s vybranými poli, `Free` ji uvolní
- `AddRow(Row)` přidá kopii řádku, `ClearData` smaže všechny řádky
- `Rows[I].X := 1045986.745` změní hodnotu v řádku
- řádek má vždy všech 24 polí, do CSV a výpisu jdou jen pole z `Fields`
- `Print` vypíše tabulku pro ladění

## CSV a soubor

- `ToCSV(Soubor)` uloží tabulku do CSV se středníkem a desetinnou čárkou (český Excel)
- `FromCSV(Soubor)` ji načte zpět a `Fields` nastaví podle hlavičky, neznámé sloupce a prázdné řádky přeskočí
- `SaveToFile(Soubor)` a `LoadFromFile(Soubor)` uloží a načtou tabulku i s výběrem polí do binárního souboru
