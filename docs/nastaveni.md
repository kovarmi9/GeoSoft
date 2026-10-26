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

- **Jen ze zobrazení** – zkreslení Křovákova zobrazení,
  m = 0,9999 + 1,22822·10⁻¹⁴·Δρ² − 3,154·10⁻²¹·Δρ³ + 1,848·10⁻²⁷·Δρ⁴,
  kde ρ = √(X² + Y²) a Δρ = ρ − 1 298 039 m.
- **Jen z výšky** – m = R / (R + H), R = 6 381 km.
- **Obojí** – součin obou měřítek.

Výsledek se ukáže vedle tlačítka a přepíše Měřítko délek. Souřadnice musí
ležet v S-JTSK (1 100 000 m < ρ < 1 500 000 m), výška mezi 100 a 3 000 m.
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
