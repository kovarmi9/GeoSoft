# Protínání ze směrů

Úloha 6 určí nové body ze směrů měřených na dvou orientovaných
stanoviscích. Pokrývá i protínání z úhlů.

## Co umí

- Jedna tabulka, bloky oddělené prázdným řádkem:
    1. stanovisko A a pod ním jeho orientace (číslo bodu a směr),
    2. stanovisko B a jeho orientace,
    3. určované body, u každého směr z A a směr z B.
- Souřadnice stanovisek a orientací se doplní ze seznamu.
- Protínání z úhlů: na A jediná orientace na B se směrem 0, na B
  jediná orientace na A se směrem 0. Směry k bodům jsou pak úhly od
  základny.
- Pod tabulkou se ukáže, jak program zápisník pochopil: stanoviska,
  počet orientací, orientační posun a počet určovaných bodů.
- Směr nejde zapsat u stanoviska, směr z B jen u určovaného bodu.
- Výpočet uloží určené body do seznamu, bod, který už v seznamu je,
  se přepíše s dotazem.

## Kde se co počítá

| unit | výpočet |
|---|---|
| `GUI/ForwardIntersection.pas` | tabulka → frame, výsledky zpět, protokol, uložení bodů, zápisník |
| `GeoAlgorithms/GeoAlgorithmForwardIntersection.pas` | bloky, orientace stanovisek, určované body, úhel protnutí |
| `GeoAlgorithms/GeoAlgorithmPolar.pas` | orientační posun a odchylky orientací, společné s polární metodou |

## Matematika

### Značení

| značka | v kódu | význam |
|---|---|---|
| Y, X | `Y`, `X` | souřadnice S-JTSK |
| ΔX, ΔY | — | rozdíly ze stanoviska do bodu |
| ψ | `psi`, pole `HZ`, `Zuhel` | měřený směr, z A a z B |
| σ | `sigma`, `sigmaAP`, `sigmaBP` | směrník |
| φ | `phi` | orientační posun stanoviska |
| p | `p` | váha orientace, s / smax |
| dφ | `dPhi` | odchylka orientace |
| sin ω | `sinOmega` | sinus úhlu protnutí, 0 = rovnoběžné směry |
| sAP | `sAP` | délka ze stanoviska A na určovaný bod |
| ω | `omega` | úhel protnutí |

### Orientační posun

Stejně jako v polární metodě:

```
σi  = arctg2(ΔYi, ΔXi)
φ   = arctg2(Σ pi·sin(σi − ψi), Σ pi·cos(σi − ψi))
dφi = σi − (ψi + φ)
```

### Určovaný bod

```
σAP   = ψA + φA                  σBP = ψB + φB
sin ω = cos σAP·sin σBP − sin σAP·cos σBP
sAP   = (ΔXAB·sin σBP − ΔYAB·cos σBP) / sin ω
XP    = XA + sAP·cos σAP         YP = YA + sAP·sin σAP
ω     = |arctg2(sin ω, cos σAP·cos σBP + sin σAP·sin σBP)| · 200/π
```

## Přesnost

- Kód kvality určovaného bodu je horší ze stanovisek A a B.
- Odchylka orientace dφ nad 0,08 gon vypíše upozornění (Návod pro
  obnovu katastrálního operátu, bod 4.3.5.1.2 c).
- Úhel protnutí mimo 30 až 170 gon vypíše upozornění.
- Bod, který vyjde za stanoviskem A (sAP < 0), vypíše upozornění.
- Chybějící stanovisko, orientace, souřadnice nebo směr a rovnoběžné
  směry jsou chyba.
