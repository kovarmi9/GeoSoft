# Čísla bodů

Číslo bodu má 15 číslic: KÚ (6), ZPMZ (5) a vlastní číslo (4).
Uživatel obvykle píše jen vlastní číslo, zbytek se doplní z lišty.

Příklad: KÚ 123456, ZPMZ 00078, uživatel napíše `12` → `123456000780012`.
Číslo s 5 a více číslicemi se bere celé: `5000012` → `000000005000012`.

Hodnoty lišty (KÚ, ZPMZ, KK a popis) drží globální záznam `GPointPrefix`
(unit `PointPrefixState.pas`). Sdílí ho všechna okna a platí jen do konce
běhu programu.

| funkce | účel |
|---|---|
| `BuildPointIdFromPrefixState` | složí celé číslo: do 4 číslic jako KÚ + ZPMZ + číslo, delší číslo jen doplní nulami na 15 |
| `NormalizePointCell` | přepíše buňku tabulky na celé číslo bodu; text bez číslic nechá beze změny |
| `LoadPrefixToCombos`, `SavePrefixFromCombos` | přenesou hodnoty mezi `GPointPrefix` a lištou |
