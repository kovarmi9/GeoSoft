# Nastavení

Okno Nastavení se otevírá z hlavního okna i z menu každého výpočtu.
Nastavení platí pro celý program až do jeho ukončení.

## Souřadnice

- **Pořadí souřadnic** – Y, X (výchozí, S-JTSK) nebo X, Y. Řídí se jím
  sloupce tabulek, protokoly a soubory TXT a CSV.
- **Desetinná místa délek a souřadnic** – 0 až 9, výchozí 2.
- **Desetinná místa úhlů** – 0 až 9, výchozí 4.
- **Desetinná místa ploch** – 0 až 9, výchozí 0.

## Měřítko

**Měřítko délek** je délkové zkreslení. Polární a ortogonální metoda,
konstrukční a kontrolní oměrné jím násobí každou měřenou délku a protokol
ho uvádí. Tlačítko **1,0** vrátí výchozí hodnotu.

Měřítko se dá určit pro bod nebo místo. **Najít bod** vezme ze seznamu
souřadnic Y, X a výšku bodu, hodnoty jde napsat i ručně.

- **Jen ze zobrazení** – zkreslení Křovákova zobrazení:

    $$
    m = 0{,}9999 + 1{,}22822 \cdot 10^{-14}\, \Delta\rho^2 - 3{,}154 \cdot 10^{-21}\, \Delta\rho^3 + 1{,}848 \cdot 10^{-27}\, \Delta\rho^4
    $$

    kde $\rho = \sqrt{X^2 + Y^2}$ a $\Delta\rho = \rho - 1\,298\,039\ \mathrm{m}$.

- **Jen z výšky** – $m = \dfrac{R}{R + H}$, $R = 6\,381\ \mathrm{km}$.
- **Obojí** – součin obou měřítek.

Výsledek se ukáže vedle tlačítka a přepíše Měřítko délek. Souřadnice musí
ležet v S-JTSK ($1\,100\,000\ \mathrm{m} < \rho < 1\,500\,000\ \mathrm{m}$),
výška mezi 100 a 3 000 m.
Zadané místo si okno pamatuje do ukončení programu.

## Přesnost a desetinná místa

Program pracuje vždy s plnou přesností čísel. Počet desetinných míst
z nastavení určuje jen to, jak se čísla ukazují:

- **v tabulkách** – buňka si pamatuje celé číslo, zaokrouhleně se jen
  kreslí.
- **v protokolu** – sloupce se rozšíří podle počtu desetinných míst,
- **v exportu do TXT a CSV**

Celá čísla se používají:

- **při výpočtu** – napsaná hodnota se nezaokrouhluje, počítá se s tím, co
  bylo napsáno,
- **ve výsledcích** – vypočtený bod jde do tabulky i do seznamu souřadnic celý,
- **v souborech seznamu souřadnic** (.yxz, .xyz) a v zápisníku CSV.

## Úlohy

- **Polární metoda** – výška cíle, popis bodu a shodnostní transformace
  u volného stanoviska.

## Protokol

Kdy se protokol výpočtu zapisuje do protokolu zakázky (.ptk):

- **Protokolovat vše** – po každém úspěšném výpočtu (výchozí).
- **Protokolovat ručně** – zapisuje tlačítko **Zapsat do protokolu**,
  které nejdřív spočítá a pak zapíše.
- **Neprotokolovat** – nezapisuje se nic, tlačítko je skryté.
