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
