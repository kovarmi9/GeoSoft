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

- `MxyOfQuality` – $M_{xy}$ kódu kvality podle KatV 13.9 a 15.6, pro
  ostatní kódy neurčeno:

    | kód kvality | 3 | 4 | 5 | 6 | 7 | 8 |
    |---|---|---|---|---|---|---|
    | $M_{xy}$ [m] | 0,14 | 0,26 | 0,50 | 0,21 | 0,50 | 1,00 |

- `MxyBand` – pásmo bodu podle $S_{xy}$: do Mxy ($S_{xy} < M_{xy}$),
  do Uxy ($S_{xy} \le U_{xy}$, $U_{xy} = 2\,M_{xy}$), přes Uxy, podle
  KatV 13.7 a 13.8
