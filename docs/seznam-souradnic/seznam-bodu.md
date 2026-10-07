# Seznam bodů `TPointDictionary`

Seznam souřadnic je jediný objekt pro celý program (singleton). Vzniká
při prvním volání `TPointDictionary.GetInstance` a zaniká s koncem programu;
všechna okna a výpočty proto pracují se stejnými body.

Body jsou uloženy ve slovníku `TDictionary<Int64, TPoint>`, kde klíčem je
číslo bodu. Vyhledání bodu je okamžité, každé číslo je v seznamu nejvýše
jednou a body nemají pořadí – kdo je zobrazuje, musí je seřadit.

| metoda | účel |
|---|---|
| `AddOrUpdatePoint` | přidá bod, nebo přepíše bod se stejným číslem (jediný způsob zápisu) |
| `GetPoint`, `PointExists` | vrátí kopii bodu, ověří existenci bodu |
| `RemovePoint`, `Clear` | smaže bod, smaže všechny body |
| `GetPointCount`, `Values` | počet bodů, průchod všemi body |
| `SortedNumbers` | čísla bodů seřazená podle velikosti |
| `ChangeCount` | počítadlo změn; okno podle něj pozná, že má seznam znovu načíst |

Vlastnost `Modified` říká, zda se seznam liší od souboru. Nastavuje ji
každá změna, nuluje ji uložení nebo načtení. O přepsání existujícího bodu
rozhoduje okno, které se ptá uživatele – seznam body pouze ukládá.
