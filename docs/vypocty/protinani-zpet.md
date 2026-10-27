# Protínání zpět

Úloha 8 určí souřadnice stanoviska ze dvou úhlů měřených na tři dané
body. Program počítá Cassiniho řešením.

## Matematika

### Zadání

**Dáno:** souřadnice tří daných bodů $P_1(Y_1, X_1)$, $P_2(Y_2, X_2)$,
$P_3(Y_3, X_3)$, kde $P_2$ je prostřední bod.

**Měřeno:** na určovaném bodě $S$ vodorovné úhly

$$
\alpha = \angle P_1 S P_2, \qquad \beta = \angle P_2 S P_3 .
$$

Z osnovy směrů $\psi_1, \psi_2, \psi_3$:

$$
\alpha = \psi_2 - \psi_1, \qquad \beta = \psi_3 - \psi_2 \pmod{400^{\mathrm{g}}} .
$$

**Určujeme:** souřadnice $Y_S$, $X_S$ bodu $S$.

### Značení

| značka | význam |
|---|---|
| $Y$, $X$ | souřadnice S-JTSK |
| $P_1$, $P_2$, $P_3$ | dané body, $P_2$ je prostřední |
| $S$ | určovaný bod (stanovisko) |
| $\psi$ | měřený směr |
| $\alpha$, $\beta$ | úhly na $S$ mezi $P_1, P_2$ a mezi $P_2, P_3$ |
| $T$, $U$ | Cassiniho pomocné body |
| $\Delta Y_{12} = Y_2 - Y_1$ | souřadnicový rozdíl, koncový minus počáteční |
| $\sigma$, $d$ | směrník, délka |
| $R$ | pravý úhel, $100^{\mathrm{g}}$ |
| $k$ | koeficient paty kolmice |

### Princip Cassiniho řešení

Kružnice $k_1$ je opsaná bodům $P_1, P_2, S$ a kružnice $k_2$ bodům
$P_2, P_3, S$. Spojnice bodu $P_2$ se středem $s_1$ kružnice $k_1$ ji
protne v bodě $T$, spojnice $P_2$ se středem $s_2$ kružnice $k_2$ ji
protne v bodě $U$. Trojúhelníky $S P_2 T$ a $S P_2 U$ jsou pravoúhlé,
protože jde o obvodové úhly nad průměrem. Body $T$, $S$, $U$ proto leží
na jedné přímce (Cassiniho přímce) a bod $S$ je **patou kolmice spuštěné
z bodu $P_2$ na přímku $TU$**.

Výpočet má dva kroky: rajóny k pomocným bodům $T$ a $U$, potom pata
kolmice z $P_2$ na přímku $TU$.

### 1. Souřadnicové rozdíly daných bodů

$$
\Delta Y_{12} = Y_2 - Y_1, \qquad \Delta X_{12} = X_2 - X_1
$$

$$
\Delta Y_{23} = Y_3 - Y_2, \qquad \Delta X_{23} = X_3 - X_2
$$

### 2. Pomocný bod $T$

Rajón z bodu $P_1$:

$$
Y_T = Y_1 + d_{1T} \sin\sigma_{1T}, \qquad X_T = X_1 + d_{1T} \cos\sigma_{1T}
$$

$$
\sigma_{1T} = \sigma_{12} + R, \qquad d_{1T} = d_{12} \cot\alpha
$$

Platí $\sin(\sigma + R) = \cos\sigma$, $\cos(\sigma + R) = -\sin\sigma$,
$d_{12}\sin\sigma_{12} = \Delta Y_{12}$ a
$d_{12}\cos\sigma_{12} = \Delta X_{12}$, proto

$$
X_T = X_1 - \Delta Y_{12} \cot\alpha
$$

$$
Y_T = Y_1 + \Delta X_{12} \cot\alpha
$$

### 3. Pomocný bod $U$

Rajón z bodu $P_3$:

$$
Y_U = Y_3 + d_{3U} \sin\sigma_{3U}, \qquad X_U = X_3 + d_{3U} \cos\sigma_{3U}
$$

$$
\sigma_{3U} = \sigma_{32} - R = \sigma_{23} + R, \qquad d_{3U} = d_{23} \cot\beta
$$

Stejnou úpravou:

$$
X_U = X_3 - \Delta Y_{23} \cot\beta
$$

$$
Y_U = Y_3 + \Delta X_{23} \cot\beta
$$

### 4. Souřadnicové rozdíly pomocných bodů

$$
\Delta Y_{TU} = Y_U - Y_T, \qquad \Delta X_{TU} = X_U - X_T
$$

$$
\Delta Y_{2T} = Y_T - Y_2, \qquad \Delta X_{2T} = X_T - X_2
$$

### 5. Pata kolmice

Bod $S$ je průsečíkem přímky $TU$ a přímky $P_2 S$, která je na ni
kolmá.

Přímka $TU$:

$$
Y_S - Y_T = \frac{\Delta Y_{TU}}{\Delta X_{TU}}\,(X_S - X_T)
$$

Kolmice z $P_2$:

$$
Y_S - Y_2 = -\frac{\Delta X_{TU}}{\Delta Y_{TU}}\,(X_S - X_2)
$$

Odečtením rovnic a úpravou vyjde koeficient

$$
k = \frac{\Delta Y_{2T}\,\Delta X_{TU} - \Delta Y_{TU}\,\Delta X_{2T}}
         {\Delta Y_{TU}^2 + \Delta X_{TU}^2}
$$

### 6. Souřadnice určovaného bodu

$$
X_S = X_2 - k\,\Delta Y_{TU}
$$

$$
Y_S = Y_2 + k\,\Delta X_{TU}
$$

### 7. Kontrola

Ze souřadnic bodu $S$ se vypočtou směrníky na dané body a musí platit

$$
\alpha = \sigma_{S2} - \sigma_{S1}, \qquad \beta = \sigma_{S3} - \sigma_{S2} \pmod{400^{\mathrm{g}}} .
$$

### Podmínky řešitelnosti

- $\sin\alpha \neq 0$ a $\sin\beta \neq 0$, tedy
  $\alpha, \beta \neq 0^{\mathrm{g}}, 200^{\mathrm{g}}$.
- $\Delta Y_{TU}^2 + \Delta X_{TU}^2 \neq 0$, tedy $T \neq U$. Rovnost
  nastane, když bod $S$ leží na kružnici opsané bodům $P_1, P_2, P_3$
  (nebezpečná kružnice). Úloha pak nemá jednoznačné řešení a v blízkosti
  kružnice je výsledek nepřesný.

### Příklad

| bod | $Y$ | $X$ |
|---|---|---|
| $P_1$ (103) | 739 936,78 | 1 044 454,82 |
| $P_2$ (22) | 737 998,12 | 1 045 881,67 |
| $P_3$ (30) | 739 331,21 | 1 046 906,56 |

$\alpha = 141{,}0182^{\mathrm{g}}$, $\beta = 93{,}5052^{\mathrm{g}}$

| mezivýsledek | hodnota |
|---|---|
| $\cot\alpha$, $\cot\beta$ | $-0{,}751\,268$, $0{,}102\,376$ |
| $T$ | $Y_T = 738\,864{,}83$, $X_T = 1\,042\,998{,}37$ |
| $U$ | $Y_U = 739\,436{,}13$, $X_U = 1\,046\,770{,}08$ |
| $\Delta Y_{TU}$, $\Delta X_{TU}$ | $571{,}30$, $3\,771{,}71$ |
| $k$ | $0{,}337\,83$ |
| $S$ (104) | $Y_S = 739\,272{,}33$, $X_S = 1\,045\,688{,}67$ |
