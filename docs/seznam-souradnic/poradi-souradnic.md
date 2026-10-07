# Pořadí souřadnic

Program zobrazuje dvojici souřadnic v pořadí Y, X nebo X, Y; výchozí je
Y, X. Pořadí se mění přepínačem na hlavním okně. Nastavení drží globální
proměnná `GCoordOrder` (unit `CoordOrderState.pas`) a platí jen do konce
běhu programu.

Přepínač mění pouze pořadí, nikdy význam: `TPoint.X` je vždy souřadnice X.
Podle přepínače se řídí sloupce tabulek, protokoly a textové soubory
TXT a CSV. Binární soubor se jím neřídí, pořadí v něm určuje přípona.

| funkce | účel |
|---|---|
| `CoordRead`, `CoordWrite` | přečte, zapíše dvojici souřadnic bodu v aktuálním pořadí |
| `CoordColY`, `CoordColX` | sloupec tabulky, ve kterém je Y, X |
| `SwapGridColumns` | prohodí dva celé sloupce tabulky |
