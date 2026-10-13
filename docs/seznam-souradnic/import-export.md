# Import a export

Seznam lze vyměňovat s jinými programy přes textové soubory: TXT
(hodnoty oddělené tabulátorem) a CSV (oddělené středníkem). Řádek
obsahuje číslo bodu, dvě souřadnice, výšku, kód kvality a popis.
Pořadí souřadnic se řídí přepínačem Y, X / X, Y v programu.
Souřadnice a výška se zapisují na 3 desetinná místa.
Body jsou v souboru seřazené podle čísla. Při importu projde každý bod
validací; řádek s neplatným číslem bodu se přeskočí.

Ukázka řádku TXT (oddělovač je tabulátor) v pořadí Y, X:

```
000000000000012	825000,123	1075000,456	312,500	3	hraniční kámen
```

CSV má stejný řádek, jen se středníky. Textové soubory se čtou a zapisují
v kódování Windows (ANSI); soubor uložený v UTF-8 bude mít v popisu
rozsypanou diakritiku.

Import seznam nemaže: nejdřív přečte celý soubor, pak body přidá. U bodu,
jehož číslo již v seznamu existuje, se zeptá: ponechat původní, uložit nový,
průměr, nebo nové číslo; volbu lze použít pro všechny další body. Na konci
ohlásí počet nových, přepsaných a ponechaných bodů a přeskočených chybných
řádků. Čísla se zapisují s desetinnou čárkou, při čtení se přijme čárka
i tečka.
