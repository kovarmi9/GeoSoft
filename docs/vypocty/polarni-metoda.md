# Polární metoda

Úloha 1 určí body ze stanoviska měřeným směrem a délkou. Stanovisko
je pevné (bod ze seznamu), nebo volné (určí se z orientací).

## Co umí

- Stanovisko: číslo, výška stroje. Pevné stanovisko bere souřadnice
  a výšku ze seznamu, volné je určí výpočet.
- Horní tabulka jsou orientace na body ze seznamu, dolní podrobné body.
- Nastavení, záložka Úlohy:
    - Délky vodorovné, nebo šikmé se zenitovým úhlem,
    - Počítat výšky (výška stroje, výška cíle, zenitový úhel),
    - Polární doměrek a Polární kolmice,
    - popis bodu, shodnostní transformace u volného stanoviska.
- Nezadaná výška cíle podrobného bodu je naposledy zadaná, u prvního
  bodu výška stroje. Výška cíle 0 je platná (bezhranolové měření).
- Bod s výškou 0 výšku nemá.
- Výpočet uloží podrobné body a volné stanovisko do seznamu.

## Kde se co počítá

| unit | výpočet |
|---|---|
| `GUI/PolarMethod.pas` | tabulky → frame, výsledky zpět, protokol, uložení bodů, zápisník |
| `GeoAlgorithms/GeoAlgorithmPolar.pas` | orientační posun, volné stanovisko, podrobné body, výšky |

## Matematika

### Značení

| značka | v kódu | význam |
|---|---|---|
| ψ | `psi` | měřený vodorovný směr |
| σ | `sigma` | směrník |
| φ | `phi` | orientační posun |
| p | `p` | váha orientace |
| v, w | `dPhi`, `Normed` | odchylka orientačního posunu, normovaná odchylka |
| m0 | `m0` | jednotková střední chyba směru |
| s, z | `SS`, `Zuhel` | šikmá délka, zenitový úhel |
| d | `SH` | vodorovná délka |
| D, k | `PolarD`, `PolarK` | doměrek, kolmice (vpravo kladná) |
| vs, vc | `VS`, `VC` | výška stroje, výška cíle |
| Δh | `HeightDiff` | převýšení záměry |

Délky d, D, k se násobí měřítkem délek z Nastavení, převýšení ne.

### Délka a převýšení

```
d  = s · sin z
Δh = s · cos z            (šikmá délka)
Δh = d · cotg z           (vodorovná délka)
```

Převýšení se neopravuje o zakřivení Země a refrakci.

### Pevné stanovisko

```
p   = s_i / s_max          (délka ze souřadnic)
φ   = vážený průměr (σ_i − ψ_i)
v   = φ − (σ_i − ψ_i)
m0  = √( Σ p·v² / (n − 1) )
w   = v · √p               (normovaná odchylka)
ds  = s_i − d_i            (vypočtená − měřená)
```

### Volné stanovisko

Orientace se převedou do místní soustavy kolem přístroje
(y = d · sin ψ, x = d · cos ψ) a shodnostní, nebo Helmertova
transformace je položí na dané body. Posun je poloha stanoviska,
otočení orientační posun.

Výška stanoviska je průměr z orientací na body s výškou:

```
Z_S = průměr (Z_i + vc_i − vs − Δh_i)
```

### Podrobný bod

```
σ = φ + ψ
Y = Y_S + (d + D) · sin σ + k · cos σ
X = X_S + (d + D) · cos σ − k · sin σ
Z = Z_S + vs + Δh − vc
```

## Přesnost

- Normovaná odchylka |w| nebo m0 nad 0,08 gon je upozornění (Návod
  pro obnovu KO, bod 4.3.5.1.2 c), jako GEUS).
- Rozdíl délek orientace ds musí být menší než ud podle KatV, body
  přílohy 13.5 a 13.6, pro horší kód kvality stanoviska a orientace.
  Bod bez kódu kvality vezme kód druhého bodu.
- Bod dál než nejvzdálenější orientace je upozornění (Návod,
  bod 4.3.2.2.2).
- Volné stanovisko: odchylky transformace se zařadí do pásem do Mxy,
  do Uxy a přes Uxy (KatV, body přílohy 13.7 až 13.9).
- Odchylky výšek orientací dZ jsou jen pro informaci.
