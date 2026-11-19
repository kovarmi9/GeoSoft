# Pořadí souřadnic

Program zobrazuje dvojici souřadnic v pořadí Y, X nebo X, Y; výchozí je
Y, X. Pořadí se mění v Nastavení na záložce Souřadnice. Nastavení drží
globální proměnná `GCoordOrder` (unit `CoordOrderState.pas`) a platí jen
do konce běhu programu.

Nastavení mění pouze pořadí, nikdy význam: `TPoint.X` je vždy souřadnice X.
Podle něj se řídí sloupce tabulek, protokoly a textové soubory
TXT a CSV. Binární soubor se jím neřídí, pořadí v něm určuje přípona.

| funkce | účel |
|---|---|
| `CoordRead`, `CoordWrite` | přečte, zapíše dvojici souřadnic bodu v aktuálním pořadí |
| `CoordColY`, `CoordColX` | sloupec tabulky, ve kterém je Y, X |
| `SwapGridColumns` | prohodí dva sousední sloupce i se šířkou a texty, u `TGeoPointsGrid` i popisky a filtry; seznam souřadnic a Přidat bod |
| `ApplyColumns` | výpočetní tabulka: sloupce v pořadí z návrháře bez skrytých polí, dvojice Y a X, Ym a Xm a jedna další dvojice úlohy v nastaveném pořadí |
| `ApplyCoordOrder` | prohodí políčka Y a X ve formuláři |
