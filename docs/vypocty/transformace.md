# Transformace

Úloha 65 převede body ze zdrojové soustavy do cílové podle identických
bodů. S nadbytkem bodů se klíč vyrovná metodou nejmenších čtverců (MNČ).
Transformace je rovinná, výšky se netransformují.

## Co umí

| typ | parametry | min. bodů |
|---|---|---|
| shodnostní | posun, otočení (3) | 2 |
| podobnostní (Helmertova) | + měřítko (4) | 2 |
| afinní | 6 | 3 |

- Shodnostní má nadbytek vždy, ostatní s minimem bodů vyjdou přesně.
- Role bodu podle seznamu souřadnic a zaškrtnutí ve sloupci Klíč:
  **identický** (je v seznamu, zaškrtnutý, jde do klíče), **kontrolní**
  (je v seznamu, nezaškrtnutý, jen odchylky), **určovaný** (není
  v seznamu, dopočte se a uloží).
- Na začátku je zaškrtnuté vše. Zaškrtnutí v hlavičce přepne všechny
  řádky, mezerník přepne řádek pod kurzorem.
- Určovaný bod dostane jen Y a X. Nový bod se uloží s výškou 0, bod,
  který už v seznamu je, si svou výšku ponechá.

## Kde se co počítá

| unit | výpočet |
|---|---|
| `GUI/Transformation.pas` | tabulka → frame (role v `TypS`: 1, 2, 3), výsledky zpět, uložení bodů, zápisník |
| `GeoAlgorithms/GeoAlgorithmTransformation.pas` | řízení výpočtu, kontrolní a určované body |
| `GeoAlgorithms/GeoAlgorithmTransformBase.pas` | předek klíčů: těžiště, posuny, transformace bodů, opravy |
| `GeoAlgorithms/GeoAlgorithmTransformSimilarity.pas` | podobnostní, λ1 a λ2 |
| `GeoAlgorithms/GeoAlgorithmTransformCongruent.pas` | shodnostní, potomek podobnostní |
| `GeoAlgorithms/GeoAlgorithmTransformAffine.pas` | afinní |
| `Utils/ProtocolTransformation.pas` | protokol |
| `Utils/ValidationUtils.pas` | Mxy kódu kvality a pásma |

## Matematika

### Značení

- Soustava II (místní, zdrojová): x, y. Soustava I (cílová, S-JTSK):
  X, Y.
- n identických bodů, T jejich těžiště, index r souřadnice redukované
  k těžišti.
- [ ] Gaussův součet redukovaných souřadnic přes identické body,
  např. [xX] = Σ xr·Xr, [xx] = Σ xr².
- Opravy v = transformovaná − daná.

### Redukce k těžišti

Společná všem transformacím:

```
xT = Σx / n     yT = Σy / n     XT = ΣX / n     YT = ΣY / n
xr = x − xT     yr = y − yT     Xr = X − XT     Yr = Y − YT
```

Klíč se určí z podmínky MNČ [vX·vX + vY·vY] = min. Podmínky pro posuny
X0, Y0 vedou vždy k tomu, že se těžiště soustavy II zobrazí na těžiště
soustavy I, posuny se proto počítají až nakonec z těžišť. Redukce navíc
drží přesnost, souřadnice v milionech metrů by v součtech ztratily
platné číslice.

### Podobnostní (Helmertova)

Transformační rovnice:

```
X = X0 + λ1·x − λ2·y
Y = Y0 + λ1·y + λ2·x
```

Rovnice oprav identického bodu:

```
vX = λ1·xr − λ2·yr − Xr
vY = λ1·yr + λ2·xr − Yr
```

Z podmínek ∂[vv]/∂λ1 = 0 a ∂[vv]/∂λ2 = 0 vzniknou normální rovnice.
Smíšený součet [xy] se v nich vyruší a soustava je diagonální:

```
λ1·([xx] + [yy]) = [xX] + [yY]
λ2·([xx] + [yy]) = [xY] − [yX]
```

Transformační klíč:

```
λ1 = ([xX] + [yY]) / ([xx] + [yy]) = Σ(xr·Xr + yr·Yr) / Σ(xr² + yr²)
λ2 = ([xY] − [yX]) / ([xx] + [yy]) = Σ(xr·Yr − yr·Xr) / Σ(xr² + yr²)

X0 = XT − λ1·xT + λ2·yT
Y0 = YT − λ1·yT − λ2·xT

q = √(λ1² + λ2²)      tg ω = λ2 / λ1   (kvadrant podle znamének λ1, λ2)
```

- 4 parametry, minimum 2 body.
- [xx] + [yy] = 0 znamená, že identické body splývají.

### Shodnostní

Měřítko q = 1, transformační rovnice:

```
X = X0 + x·cos ω − y·sin ω
Y = Y0 + y·cos ω + x·sin ω
```

Otočení nemění délky, (xr·cos ω − yr·sin ω)² + (yr·cos ω + xr·sin ω)²
= xr² + yr², a proto podmínka MNČ přejde na

```
[vv] = konst − 2·[cos ω·([xX] + [yY]) + sin ω·([xY] − [yX])] = min
```

Minimum nastane pro stejný úhel ω jako u podobnostní transformace.
Transformační klíč:

```
cos ω = λ1 / q      sin ω = λ2 / q

X0 = XT − xT·cos ω + yT·sin ω
Y0 = YT − yT·cos ω − xT·sin ω
```

- 3 parametry, minimum 2 body.
- Program spočte klíč podobnostní transformace a λ1, λ2 vydělí
  měřítkem q.

### Afinní

Transformační rovnice:

```
X = X0 + a1·x + a2·y
Y = Y0 + b1·x + b2·y
```

Rovnice oprav identického bodu:

```
vX = a1·xr + a2·yr − Xr
vY = b1·xr + b2·yr − Yr
```

Koeficienty a1, a2 jsou jen ve vX, koeficienty b1, b2 jen ve vY, úloha
se rozpadne na dvě nezávislé. Normální rovnice mají obě stejnou matici:

```
a1·[xx] + a2·[xy] = [xX]        b1·[xx] + b2·[xy] = [xY]
a1·[xy] + a2·[yy] = [yX]        b1·[xy] + b2·[yy] = [yY]
```

Determinant a řešení (Cramerovo pravidlo):

```
D = [xx]·[yy] − [xy]²

a1 = ([xX]·[yy] − [yX]·[xy]) / D       b1 = ([xY]·[yy] − [yY]·[xy]) / D
a2 = ([yX]·[xx] − [xX]·[xy]) / D       b2 = ([yY]·[xx] − [xY]·[xy]) / D

X0 = XT − a1·xT − a2·yT
Y0 = YT − b1·xT − b2·yT
```

- Vždy D ≥ 0 (Cauchyova-Schwarzova nerovnost), D = 0 právě když
  identické body leží v přímce.
- 6 parametrů, minimum 3 body.
- Program počítá přímo tyto vzorce.

### Klíč v protokolu

Protokol píše klíč nejdřív pro Y:

```
Y = Y0 + A11·y + A12·x
X = X0 + A21·y + A22·x
```

| | A11 | A12 | A21 | A22 |
|---|---|---|---|---|
| podobnostní | λ1 | λ2 | −λ2 | λ1 |
| shodnostní | cos ω | sin ω | −sin ω | cos ω |
| afinní | b2 | b1 | a2 | a1 |

## Přesnost

```
v = transformovaná − daná         Sxy = √((vX² + vY²) / 2)
m = √([vX·vX + vY·vY] / n′)
n′ = 2n − 3 u shodnostní, 2n − 4 u podobnostní (počet nadbytečných měření)
```

- Kontrola: [vX] = [vY] = 0.
- m se jen vypisuje, u afinní ne, a jen když je n′ větší než nula.
- Bod se posoudí podle Sxy proti Mxy svého kódu kvality (KatV 13.9,
  15.6): do Mxy (menší než Mxy), do Uxy (nepřekročí Uxy), přes Uxy,
  Uxy = 2·Mxy.
- Protokol vyhodnotí kritéria KatV 13.8: všechny body do Uxy a při více
  než 20 bodech nejméně 40 % do Mxy. Jen když mají všechny body Mxy.
- Rozmístění identických bodů (KatV § 75 odst. 4): kružnice se středem
  v polovině spojnice dvou nejvzdálenějších identických bodů, poloměr
  ¾ její délky. Zaměřené body (určované i kontrolní) mimo kružnici
  protokol vypíše.
