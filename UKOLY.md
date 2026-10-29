# GeoSoft - stav a plány

Stav k 29. 10. 2026, větev `test`. Pravidla práce jsou v `CLAUDE.md`.
Verze 1.0 = všechny výpočty včetně nivelace.

## Hotovo

| oblast | stav |
|---|---|
| seznam souřadnic | hotový: import a export, předčíslí, záporná čísla, pořadí Y X |
| datové struktury | `TGeoRow`, `TGeoDataFrame`, CSV, kontrola řádků |
| nastavení | záložky Souřadnice a Měřítko, desetinná místa 0 až 9 |
| úloha 0 ortogonální metoda | mez přímky podle KatV 13.6 |
| úloha 1 polární metoda | pevné i volné stanovisko, měřítko |
| úloha 2 vyrovnání do přímky | pata kolmice, mez Uxy, docs |
| úloha 3 průsečík přímek | poloha na úsečkách, docs |
| úloha 4 konstrukční oměrné | mez podle KatV 13.6, ověřeno na příkladu |
| úloha 5 protínání z délek | strana znaménkem kontrolní délky, docs |
| úloha 6 protínání ze směrů | bloky v jednom gridu, docs |
| úloha 7 konstrukční oměrné s vyrovnáním | uzávěr úměrně délkám, shodnostní klíč |
| úloha 8 protínání zpět | Cassiniho řešení, docs |
| úloha 9 kontrolní oměrné | mez podle KatV 13.6 |
| úloha 51 technická nivelace | jeden pořad, uzavřený i otevřený, 20 mm·√r |
| úloha 65 transformace | shodnostní, podobnostní, afinní, KatV 13.8 |
| úloha 95 výměry | celé m² podle § 82 |
| protokoly | jednotný vzhled, jeden unit ProtocolTable, protokol úlohy ve formuláři, CHYBA i při neúspěšném výpočtu, Č. podle řádku gridu |
| protokol zakázky | `.ptk` vedle seznamu, Nastavení → Protokol (vše, ručně, vypnuto), menu Protokol |
| značení | jednotné podle ČVUT v kódu i v docs |
| testy | 14 testů algoritmů v `tests/Algorithms` |

## C - výpočty do verze 1.0

- Polární metoda rozšířená: výšky, šikmé délky, zenitové úhly, doměrky,
  víc stanovisek, dávka.
- Meze polární metody: orientace jako GEUS (m0 a normovaná odchylka).
  Dnešní mez 0,08 gon je provizorní, mez délky na orientaci
  0,012·√d + 0,10 je stará a má být podle KatV 13.6.
- Nivelace později: víc pořadů, pevné body, obrácený směr, tam a zpět,
  nastavitelná mez. Chybí stránka dokumentace.
- Úloha 2: rovnoběžka.

## D - seznam souřadnic

- Dialog pro duplicity při importu.
- Víc seznamů (S-JTSK a místní).
- Ctrl+F a Jdi na bod.
- UTF-8 a uvozovky v CSV.
- Bezpečné ukládání a verze v hlavičce souboru.
- Naposledy otevřené soubory, velikost okna, kontrola X > Y.
- Zámek bodu a pomocný seznam.
- Seznam na `TGeoFieldsGrid`.

## E - komponenty

- Columns jako v TDBGrid.
- FieldFilters (odloženo, tři neúspěšné pokusy).
- Body 4, 6 a 7 komponentního kola.
- Zadávání kódu kvality, výrazy s NaN a Inf.
- Dvojí OnCellCommitted a Esc.
- Mazání řádků ve výpočtech.

## F - architektura

- GeoForm, kroky 2 až 4 (panel tlačítek do předka, TActionList, TFrame).
- Načítání CSV a `CheckGeoRow`.
- Katalog polí (druh číslo nebo text, role měření nebo výsledek). Odstraní
  provizorní pole:
    - kontrolní oměrné: Vy = rozdíl, Sxy = mez, Vz = vyhovuje,
    - nivelace: Xm, Ym, Zm, Vz, Vy, VC,
    - úloha 6: Zuhel = směr z B,
    - úloha 2: Xm, Ym = bod před posunem.
- Hlavička frame, výměnný formát.
- Sloupec Č. podle řádku gridu i u orientací polární metody a ve výměře
  (obě přeskakují prázdné řádky).

## G - úklid

- `.gitignore` pro Win64x a WinARM64EC.
- `PROJECT_MAP.md` je zastaralý (červen 2026).
- `deploy.yml` nasazuje main i test do stejných gh-pages.
- Smíšené konce řádků CRLF a LF.
- Průchod soubor po souboru.
- Rozlišení obrazovky a protokol s měnitelnou velikostí.
- Menu a nápověda.

## H - dokumentace a vydání

- Prázdné stránky: komponenty (geofieldsgrid, index, kontrola-zadavani),
  výpočty (index, konstrukční, kontrolní, ortogonální, polární,
  výměra). Chybí nivelace.
- README a verze 1.0, sloučit test do main a značka verze.

## Kai a Claude

- Kai je nainstalovaný a do `src/GUI` založil `AGENTS.md` a `.agents/`.
- Claude přes ACP s přihlášením Team účtem (ne API klíč), aby se čerpalo
  z limitů plánu. Ověřit `/status` v Kai.
- V Kai nepovolovat git.
