# Průsečík přímek

Úloha 3 spočítá průsečík přímky I (body I-1, I-2) s přímkou II
(body II-1, II-2).

## Co umí

- Jedna tabulka o pěti řádcích: I-1, I-2, II-1, II-2 a P. U bodů přímek
  se souřadnice a kód kvality doplní ze seznamu, do řádku P se napíše
  číslo průsečíku.
- Po každém Enteru se průsečík spočítá a pod tabulkou se ukáže, kde
  leží: na obou úsečkách, na úsečce I mimo úsečku II, na úsečce II mimo
  úsečku I, nebo na žádné.
- Výpočet uloží průsečík do seznamu, bod, který už v seznamu je, se
  přepíše s dotazem.
- Jeden zápisník je jeden průsečík.

## Kde se co počítá

| unit | výpočet |
|---|---|
| `GUI/LineIntersection.pas` | tabulka → frame, výsledek zpět, protokol, uložení bodu, zápisník |
| `GeoAlgorithms/GeoAlgorithmLineIntersection.pas` | průsečík, poloha, úhel protnutí, kód kvality |

## Matematika

### Značení

| značka | v kódu | význam |
|---|---|---|
| Y, X | `Y`, `X` | souřadnice S-JTSK |
| ΔXI, ΔYI | `DeltaXI`, `DeltaYI` | rozdíly z I-1 do I-2 |
| ΔXII, ΔYII | `DeltaXII`, `DeltaYII` | rozdíly z II-1 do II-2 |
| ΔX0, ΔY0 | `DeltaX0`, `DeltaY0` | rozdíly z I-1 do II-1 |
| D | `D` | determinant soustavy, 0 = rovnoběžky |
| t, u | `t`, `u` | poloha průsečíku na přímce I a II, 0 první bod, 1 druhý |
| ω | `omega` | úhel protnutí |

### Výpočet

```
D  = ΔXI·ΔYII − ΔYI·ΔXII
t  = (ΔX0·ΔYII − ΔY0·ΔXII) / D
u  = (ΔX0·ΔYI  − ΔY0·ΔXI)  / D
XP = XI-1 + t·ΔXI                YP = YI-1 + t·ΔYI
ω  = |arctg2(D, ΔXI·ΔXII + ΔYI·ΔYII)| · 200/π
```

Průsečík leží na úsečce I, když 0 ≤ t ≤ 1, a na úsečce II, když
0 ≤ u ≤ 1.

## Přesnost

- Kód kvality průsečíku je nejhorší ze čtyř bodů přímek.
- Úhel protnutí mimo 30 až 170 gon vypíše upozornění, průsečík se
  přesto spočítá.
- Rovnoběžné přímky, splývající body přímky a bod bez souřadnic jsou
  chyba.
