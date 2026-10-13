# Tabulka TGeoDataFrame

Tabulka řádků `TGeoRow` se seznamem použitých polí (`Fields`).
Výpočty do ní čtou z gridu a algoritmus z ní počítá.

## Řádky: Count a Capacity

Řádky leží v poli `Rows`. Pole má víc místa, než je řádků:

```
Rows:  [ řádek 0 | řádek 1 | řádek 2 | volno ]
         Count = 3                     Capacity = 4
```

| vlastnost | význam |
|---|---|
| `Count` | počet použitých řádků; dá se i nastavit (nové řádky jsou prázdné = NaN) |
| `Capacity` | kolik řádků se vejde bez zvětšení pole |
| `Rows[i]` | řádek `i`, platí `0 ≤ i < Count` |

!!! warning "Pozor"
    `Length(Rows)` je kapacita, ne počet řádků. Vždy používejte `Count`.

`Rows` jde jen číst. Hodnoty v řádku se mění přímo
(`Rows[0].X := 1045986.745`), řádky se přidávají přes `AddRow`.

## Zdvojnásobování kapacity

Když místo dojde, pole se nezvětší o jeden řádek, ale na dvojnásobek
(1, 2, 4, 8, …). Zvětšení znamená zkopírovat všechny řádky do nového
bloku paměti, a tak se kopíruje jen zřídka:

| 10 000 řádků | zvětšení | zkopírováno řádků |
|---|---|---|
| vždy o 1 | 10 000 | ≈ 50 000 000 |
| zdvojnásobením | 15 | 16 383 |

Při zvětšování o 1 se zkopíruje 0 + 1 + … + (n − 1) ≈ n²/2 řádků.
Při zdvojnásobování 1 + 2 + 4 + … + n/2 < n řádků, tedy méně, než kolik
se jich přidalo. Jedno přidání řádku tak v průměru stojí stejně málo,
ať je tabulka jakkoli velká. Říká se tomu **amortizovaná složitost O(1)**.

Cenou je paměť: nevyužitá je nejvýš polovina pole
(10 000 řádků → kapacita 16 384, volných ≈ 1,2 MB).

## Přidání a vymazání řádků

| metoda | co dělá |
|---|---|
| `AddRow` | přidá jeden prázdný řádek |
| `AddRow(N)` | přidá N prázdných řádků |
| `AddRow(Row)` | přidá kopii hotového řádku |
| `Count := N` | nastaví počet řádků (přidá prázdné nebo zahodí poslední) |
| `ClearData` | smaže všechny řádky a uvolní paměť; `Fields` zůstane |
