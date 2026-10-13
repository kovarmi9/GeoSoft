# Tabulka TGeoDataFrame

Tabulka řádků `TGeoRow` se seznamem použitých polí (`Fields`).
Výpočty do ní čtou z gridu a algoritmus z ní počítá.

## Ukázky

### Vytvoření a uvolnění

```pascal
gdf := TGeoDataFrame.Create([Uloha, CB, X, Y, Z]);   // prázdná tabulka s vybranými poli
...
gdf.Free;
```

`TGeoDataFrame.Create` bez závorky vytvoří tabulku se všemi poli.

### Přidání řádků

```pascal
gdf.AddRow(2);                          // dva prázdné řádky (čísla NaN)
gdf.Rows[0].Uloha := 1;
gdf.Rows[0].CB := '751261478500012';
gdf.Rows[0].X := 1045986.745;

gdf.AddRow(r1);                         // kopie hotového řádku r1

Writeln(gdf.Count);                     // 3
Writeln(gdf.Capacity);                  // 4
```

### Čtení

```pascal
Writeln(gdf.Rows[2].Uloha);             // 1

for I := 0 to gdf.Count - 1 do
  Writeln(gdf.Rows[I].CB);
```

### Výpis

```pascal
Writeln(gdf.Print);
```

```
=== TGeoDataFrame ===
Count    : 3
Capacity : 4
Fields   : Uloha, CB, X, Y, Z

--- TGeoRow 0 ---
Uloha: 1
CB: 751261478500012
X: 1045986,745
Y: 743841,459
Z: 450,485
...
```

### CSV jako text

```pascal
Writeln(gdf.ToCSV);                     // oddělovač ';', desetinná tečka
```

```
Uloha;CB;X;Y;Z
1;"751261478500012";1045986.745;743841.459;450.485
2;"751261478500013";1045746.745;743911.459;450.79
```

Z textu zpět do nové tabulky:

```pascal
csv := TStringList.Create;
csv.Text := gdf.ToCSV;
gdf2 := TGeoDataFrame.Create;
gdf2.FromCSV(csv);                      // Fields podle hlavičky: Uloha, CB, X, Y, Z
csv.Free;
```

### CSV soubor

```pascal
gdf.ToCSV('gdf1.csv', ';', '.');        // uloží
gdf.ClearData;                          // Count = 0, Fields zůstane
gdf.FromCSV('gdf1.csv', ';', '.');      // načte, Count = 3
```

Výpočty ukládají se středníkem a desetinnou čárkou: `ToCSV(Soubor, ';', ',')`.

### Binární soubor

```pascal
gdf.SaveToFile('soubor.gdf');           // uloží řádky i Fields

gdf3 := TGeoDataFrame.Create;
gdf3.LoadFromFile('soubor.gdf');        // Count = 3, Fields: Uloha, CB, X, Y, Z
```

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

## Výpis a CSV

| metoda | co dělá |
|---|---|
| `Print` | vrátí čitelný text: Count, Capacity, Fields a všechny řádky |
| `ToCSV(';', ',')` | vrátí tabulku jako text CSV |
| `ToCSV(Soubor, ';', ',')` | uloží CSV do souboru |
| `FromCSV(Seznam)`, `FromCSV(Soubor)` | načte CSV, dosavadní řádky smaže |

```pascal
Writeln(Frame.Print);
Memo1.Text := Frame.ToCSV(';', ',');
```

### Zápis

```
Uloha;CB;X;Y
1;"751261478500012";1045986,745;743841,459
1;"751261478500013";;
```

- první řádek jsou názvy polí z `Fields`, v pořadí podle `TGeoField`
- nevyplněné číslo (NaN) je prázdná buňka
- `CB`, `CBm` a `Poznamka` jsou v uvozovkách, uvozovka uvnitř se zdvojí (`""`)
- oddělovač buněk a desetinný oddělovač se musí lišit, jinak chyba
- výpočty ukládají se středníkem a desetinnou čárkou

### Načtení

- `Fields` se nastaví podle hlavičky, neznámé sloupce se přeskočí
- na velikosti písmen v názvech nezáleží
- buňka, která není číslo, nechá v poli NaN
- prázdný řádek souboru dá prázdný řádek tabulky

## Binární soubor

`SaveToFile(Soubor)` uloží tabulku, `LoadFromFile(Soubor)` ji načte
zpět i s `Fields`. Soubor je řada záznamů [TGeoRow](georow.md),
první záznam je hlavička:

| pole hlavičky | hodnota |
|---|---|
| `Uloha` | −1 |
| `CB` | `__HEADER__` |
| `TypS` | `Fields` jako bitová maska (bit číslo = pořadí pole v `TGeoField`) |

- uloží se jen `Count` řádků, volné místo kapacity ne
- soubor bez hlavičky se načte celý jako data se všemi poli
- prázdný soubor dá prázdnou tabulku
