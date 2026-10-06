# GeoSoft

GeoSoft je software pro geodetické výpočty. Pracuje nad jedním společným
seznamem souřadnic, ze kterého výpočty berou dané body a do kterého ukládají
body vypočtené.

## Co program umí

- **Seznam souřadnic**: zadávání, mazání a úpravy bodů, ukládání do souborů
  `.yxz` a `.xyz`, import a export TXT a CSV
- **Polární metoda**: pevné i volné stanovisko
- **Ortogonální metoda**: měřická přímka a podrobné body
- **Konstrukční oměrné**: výpočet bodů z řetězce délek
- **Kontrolní oměrné**: porovnání měřených délek s vypočtenými
- **Výpočet výměry**: plocha parcely ze souřadnic lomových bodů
- **Protokol**: každý výpočet vytvoří protokol, který lze uložit

## Základní konvence

**Číslo bodu** má 15 číslic: katastrální území (6), číslo záznamu
podrobného měření změn ZPMZ (5) a vlastní číslo bodu (4). Stačí zadat
krátké číslo, například `12`, a program doplní předčíslí z lišty v okně.

**Jednotky.** Délky a souřadnice v metrech, úhly v gonech.

**Desetinná čárka.** Na obrazovce se používá oddělovač podle nastavení
Windows, v protokolu a v souborech vždy čárka. Při čtení souborů program
přijme čárku i tečku.

## Spuštění

Po spuštění je seznam souřadnic prázdný. Založte nový
(*Soubor → Nový seznam*), nebo otevřete existující
(*Soubor → Otevřít seznam*).

Pro předávání dat slouží datová struktura [GeoDataFrame](geodataframe/index.md),
pro software byly vytvořeny upravené varianty komponenty `TStringGrid`
([Komponenty](komponenty/index.md)).
