# Datová struktura

Výpočty ukládají data do dvou typů:

- [Řádek TGeoRow](georow.md) – jedno měření, vždy všech 24 polí
- [Tabulka TGeoDataFrame](geodataframe.md) – řádky jedné úlohy a výběr polí, která úloha používá

Tabulka se naplní z gridu, algoritmus počítá přímo v jejích řádcích a výsledky
se z ní zapíší zpět do gridu nebo do souboru CSV.

Nevyplněné číslo je v řádku NaN („není číslo“), ne nula, protože nula může
být skutečně změřená hodnota.
