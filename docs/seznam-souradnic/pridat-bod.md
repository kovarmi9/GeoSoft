# Přidat bod

Okno Přidat bod (unit `AddPoint.pas`) se otevře, když výpočet potřebuje bod,
který v seznamu není. Výpočet zavolá `Execute` s číslem bodu; okno doplní
číslo o KÚ a ZPMZ a nabídne zadání souřadnic, výšky, kódu kvality a popisu.

Souřadnice Y a X jsou povinné – tlačítko OK okno nezavře, dokud nejsou
platnými čísly. Prázdný kód kvality a popis se doplní z lišty. Pokud bod
v seznamu už je, okno se zeptá na přepsání.

Po OK se bod uloží do seznamu (`AddOrUpdatePoint`) a `Execute` ho vrátí
výpočtu, který pokračuje. Po Zrušit vrátí `False` a výpočet bod nemá.
