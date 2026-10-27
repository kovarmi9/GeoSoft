# Protínání z délek

Úloha 5 určí nový bod z délek měřených z bodů 1 a 2.

## Co umí

- Jedna tabulka o třech řádcích, zadávání jako v GEUSu:
    - řádek 1 a 2: výchozí bod a měřená délka z něj na nový bod,
      souřadnice a kód kvality se doplní ze seznamu,
    - řádek 3: číslo nového bodu a kontrolní délka 1-2.
- Znaménko kontrolní délky určuje stranu: kladná znamená nový bod
  vpravo od směru 1→2, záporná vlevo. Délka 0 nebo prázdná znamená
  vpravo, −1 vlevo, v obou případech bez kontroly.
- Pod tabulkou se ukáže strana a jak sedí kontrolní délka.
- Výpočet uloží nový bod do seznamu, bod, který už v seznamu je, se
  přepíše s dotazem.
- Jeden zápisník je jeden bod.

## Kde se co počítá

| unit | výpočet |
|---|---|
| `GUI/DistanceIntersection.pas` | tabulka → frame, výsledek zpět, protokol, uložení bodu, zápisník |
| `GeoAlgorithms/GeoAlgorithmDistanceIntersection.pas` | nový bod, strana, kontrolní délka, úhel protnutí, kód kvality |

## Matematika

### Značení

| značka | v kódu | význam |
|---|---|---|
| Y, X | `Y`, `X` | souřadnice S-JTSK |
| ΔX12, ΔY12 | `DeltaX12`, `DeltaY12` | rozdíly z bodu 1 do 2 |
| s12 | `s12` | délka 1-2 ze souřadnic |
| s1, s2 | `s1`, `s2` | měřené délky × měřítko |
| p | `p` | pata výšky trojúhelníku na spojnici 1-2, od bodu 1 |
| h | `h` | výška trojúhelníku |
| ε | `epsilon` | +1 vpravo od 1→2, −1 vlevo |
| ω | `omega` | úhel protnutí v novém bodě |

### Výpočet

```
s12 = √(ΔX12² + ΔY12²)
p   = (s1² − s2² + s12²) / (2·s12)
h   = √(s1² − p²)
XP  = X1 + (p·ΔX12 − ε·h·ΔY12) / s12
YP  = Y1 + (p·ΔY12 + ε·h·ΔX12) / s12
```

Záporné číslo pod odmocninou znamená, že se délky neprotnou.

Úhel protnutí je úhel mezi spojnicemi nového bodu s body 1 a 2
(0 až 200 gon).

## Přesnost

- Kód kvality nového bodu je horší z bodů 1 a 2.
- Měřená kontrolní délka × měřítko se porovná s délkou 1-2 ze
  souřadnic. Rozdíl musí být menší než ud podle KatV, body přílohy
  13.5 a 13.6, z horšího kódu kvality bodů 1 a 2. Jinak se vypíše
  upozornění.
- Neměřená kontrolní délka vypíše upozornění, že délka 1-2 je jen ze
  souřadnic.
- Úhel protnutí mimo 30 až 170 gon vypíše upozornění.
- Délky, které se neprotnou, splývající body 1 a 2, bod bez souřadnic
  a chybějící délka jsou chyba.
