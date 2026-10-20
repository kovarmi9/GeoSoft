# TGeoGrid

## Zobrazení čísel

`Cells` drží vždy celé číslo. Zaokrouhluje se jen při kreslení:

- `DisplayText(ACol, ARow)` vrátí text buňky tak, jak se ukazuje: číslo
  zaokrouhlené podle `DecimalPlaces` filtru sloupce. `Cells` nemění,
- `DrawCell` kreslí `DisplayText`, Delphi při tom nepíše text
  (`DefaultTextDrawing`),
- `CellFilter(ACol)` vrátí filtr sloupce, potomci ji přepisují,
- formulář, který si buňky kreslí sám (`OnDrawCell`), má sám volat
  `DisplayText`.

Počet míst nastavuje program: `TGeoFieldsGrid.SetFieldDecimals(pole,
místa)` u výpočtů, `ColumnFilters[i].DecimalPlaces` u ostatních gridů.
