# Validace

`TValidationUtils` (unit `ValidationUtils.pas`) je sada funkcí, které
kontrolují hodnoty bodu. Volá je konstruktor `TPoint.Create`, takže každý
bod vytvořený konstruktorem projde kontrolou.

| funkce | povoleno | jinak |
|---|---|---|
| `ValidatePointNumber` | 1 až 999999999999999 | 0 |
| `ValidateCoordinate` | konečné číslo | 0 (i prázdná hodnota NaN) |
| `ValidateQuality` | kód kvality 0 až 8 | 0 |
| `ValidateDescription` | popis do 32 znaků | zkrátí se |

Neplatná hodnota se nahradí tiše, bez hlášení. Hodnoty proto hlídají
už tabulky při psaní, validace je poslední pojistka.

Meze (`PointNumberDigits`, `MaxQuality`, `MaxDescriptionLength`) jsou veřejné
konstanty – podle nich nastavují tabulky svou kontrolu zadávání.

Pro posouzení přesnosti bodu (transformace, polární metoda) slouží:

- `MxyOfQuality` – Mxy kódu kvality podle KatV 13.9 a 15.6
  (3 = 0,14, 4 = 0,26, 5 = 0,50, 6 = 0,21, 7 = 0,50, 8 = 1,00 m), jinak neurčeno
- `MxyBand` – pásmo bodu podle Sxy: do Mxy (menší než Mxy), do Uxy
  (nepřekročí Uxy = 2·Mxy), přes Uxy, podle KatV 13.7 a 13.8
