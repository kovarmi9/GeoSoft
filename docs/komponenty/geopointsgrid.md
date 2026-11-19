# TGeoPointsGrid

Tabulka s filtry nastavenými v návrháři. Používá ji seznam souřadnic
a okno Přidat bod.

Proti `TGeoGrid` umí jen dvě věci:

1. **Zveřejní do návrháře** `ColumnHeaders`, `RowHeaders`
   a `ColumnFilters`. Filtry se tak nastaví v Object Inspectoru
   a uloží do `.dfm` (`ColumnFilters = < item … end >`).
2. **Hlídá počet filtrů**, aby jich bylo tolik, kolik je datových
   sloupců: po vytvoření, po změně `ColCount` (`SizeChanged`) a po
   načtení z `.dfm` (`Loaded`).

Formulář smí k filtrům v `FormCreate` přidat to, co v návrháři nejde,
například výchozí text prázdné buňky:

```pascal
  GridPoints.ColumnFilters[COL_DESC].OnGetDefaultText := GetDescriptionDefault;
```

Když se `ColCount` zmenší, poslední filtry se smažou i s tím, co v nich
bylo nastavené v návrháři.
