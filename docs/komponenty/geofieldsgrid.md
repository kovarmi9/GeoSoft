# TGeoFieldsGrid

Tabulka, jejíž sloupce jsou pole `TGeoRow` (CB, Y, X, HZ, SH…). Řádek
tabulky se dá přečíst do `TGeoRow` a zpět, každý sloupec kontroluje
zadávání podle svého pole. Používají ji všechna výpočetní okna.

## Sloupce

| vlastnost | co určuje |
|---|---|
| `ColumnFields` | které sloupce tabulka má a v jakém pořadí, jeden řádek `Pole=Popisek` na sloupec. Nastavuje se v Object Inspectoru. |
| `GeoFields` | množina polí, která jsou právě vidět. Tabulka bez `ColumnFields` z ní bere sloupce v pořadí výčtu. |
| `ReadOnlyFields` | pole, která plní program (výsledky). Kurzor je přeskočí, kód do nich píše dál. |

Popisek bez `=` se vezme z katalogu polí (`GeoFieldInfo`
v `GeoRow.pas`). Desetinná místa pole nastaví `SetFieldDecimals`,
sloupec pole najde `FieldToCol`, pole sloupce `ColToField`.

## Skrytí sloupců a pořadí Y a X

`ColumnFields` je úplný seznam, sloupce se neodebírají. Co se nemá
ukázat, okno skryje funkcí `ApplyColumns(Grid, Skryté)`
z `CoordOrderState.pas`. Ta

1. vezme pořadí z `ColumnFields` bez skrytých polí,
2. seřadí dvojice Y a X a Ym a Xm podle Nastavení (`GCoordOrder`),
   a stejně i dvojici, kterou předá úloha, například transformace
   `ApplyColumns(Grid, [], M1, M2)` pro dY a dX,
3. předá pořadí tabulce (`SetColumns`). Tabulka sloupce přestaví
   a texty buněk nechá pod jejich poli, takže zadané hodnoty se
   neztratí.

Když se nic nezměnilo, tabulku nepřestavuje.

```mermaid
flowchart LR
  A["okno se aktivuje<br/>(i po Nastavení)"] --> B["ApplySettings<br/>co skrýt"]
  B --> C["ApplyCoordOrderToGrids"]
  C --> D["ApplyColumns(Grid, Skryté)<br/>CoordOrderState.pas"]
  D --> E["SetColumns<br/>TGeoFieldsGrid"]
```

Příklad z polární metody: sloupce, které výpočet zatím nepoužívá,
jsou skryté vždy, výška cíle a popis podle Nastavení.

```pascal
  Hidden := [SS, ZU, Sta, Kol];
  if not GSettings.Polar.ShowTargetHeight then
    Include(Hidden, VC);
  if not GSettings.Polar.ShowDescription then
    Include(Hidden, Popis);
  ApplyColumns(GridOrientation, Hidden);
  ApplyColumns(GridDetail, Hidden);
```

Ostatní okna volají `ApplyColumns(Grid, [])`, nic neskrývají a jen
řadí Y a X.

## Na co dát pozor

- Sloupce se mění přes `SetColumns` (pole v pořadí). Texty buněk
  zůstanou pod svým polem, šířky sloupců zůstávají podle pozice.
- Nový sloupec se přidá do `ColumnFields` v návrháři, ne v kódu. Při
  ruční úpravě `.dfm` musí sedět `ColCount` a počet `ColWidths`.
- Seznam souřadnic používá jiný grid (`TGeoPointsGrid`) a pořadí Y a X
  řeší sám, viz [Pořadí souřadnic](../seznam-souradnic/poradi-souradnic.md).
