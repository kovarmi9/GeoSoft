# GeoSoft - pravidla pro práci s agentem

GeoSoft je program pro katastrální výpočty v S-JTSK (Delphi 13, VCL).
Autor je geodet a v Delphi začátečník. Píše česky a odpovědi chce česky.
Aktuální stav a plány jsou v `UKOLY.md`.

## Postup práce

- Na disku nic neměnit bez schválení. Nejdřív návrh v chatu, ten obsahuje
  ukázku hotového kódu nebo textu, soubory, počet řádků, riziko a co
  otestovat. Zapsat až po výslovném „ano“ nebo „zapiš to“.
- Odpověď na otázku není schválení. „Uprav X“ nebo „piš X“ je zadání,
  ne souhlas s obsahem.
- Na git nesahat: žádné add, commit, stash, push, restore, checkout ani
  branch. Čtení (status, log, diff) je v pořádku. Commit dělá autor sám,
  agent navrhne jen text zprávy.
- Nejmenší zásah. Nepřeformátovávat okolí, nic nedělat „dopředu“, napřed
  zjistit, co už kód umí.
- Nejasnost v geodézii neodhadovat, ale zeptat se. Pořadí zdrojů:
  vyhláška (KatV 357/2013, 31/1995), pak GEUS, pak Groma, Kokeš nebo
  GeoStore, a když nic, zeptat se.
- Nepsat do souborů otevřených v IDE bez upozornění. Po zápisu říct,
  ať autor soubor v IDE znovu načte.
- Výsledky hlásit poctivě, včetně neprošlých testů.
- Dlouhé úkoly dělit na kroky, po každém krátký stav (co je hotové,
  co zbývá). Raději přehledná tabulka než dlouhý text.

## Ověření změn

- Překlad: `rsvars.bat` a pak `msbuild GeoSoft.dproj /t:Build`, testy
  v `tests/Algorithms` (projekty jsou v `ProjectGroup1.groupproj`).
- Testy algoritmů vypisují výsledky na konzoli. Po změně musí výstup
  sedět bajt po bajtu s výstupem před změnou, pokud se výpočet měnit neměl.
- Nový test: `.dpr` s `uses` bez cest, `.dproj` jako kopie
  `OrthogonalTest.dproj` s novým GUID, `.res` z OrthogonalTest, přidat
  do ProjectGroup1. V `src` nesmí vzniknout `.dcu`.

## Styl kódu

- Čitelné pro začátečníka, žádné triky. Jednotně s commitnutým kódem.
- OOP: pomocné funkce jako privátní metody nebo `class function`, ne
  volné funkce mimo třídu.
- Co jde nastavit v Object Inspectoru, patří do `.dfm`. Při ruční změně
  `GeoFields` v `.dfm` sedí `ColCount` a počet `ColWidths`.
- Délka řádku nejvýš 80 znaků. Hlavičky procedur a funkcí, výčty
  a konstantní pole do 125 znaků se nezalamují. Zalamuje se za
  operátorem nebo čárkou, pokračování o 2 mezery víc.
- Výchozí hodnoty parametrů jen v interface. Lokální `TFormatSettings`
  se jmenuje `FS`.
- Kódování: unity s češtinou UTF-8 s BOM, `.dfm` ASCII s #kódy.
  Zachovat konce řádků souboru (CRLF nebo LF).

## Názvy

- Anglicky celými slovy: `PointNumber`, `ListPoint`, `Grid`, `Count`,
  `Number` (ne `No`), `Residual`.
- Geodetické značky jako na ČVUT. Latinské beze změny: `sAB`, `sAP`,
  `s12`, `s1`, `k`, `p`, `h`, `t`, `u`, `D`, `q`.
- Řecké slovem: malé písmeno malým (`sigma`, `psi`, `phi`, `omega`,
  `lambda1`, `rho`, `epsilon`), velké velkým (`Delta`, `DeltaXAB`).
  Složené: `dPhi`, `mPhi`, `sinOmega`, `sigmaAP`.
- `p` je váha, `P` je matice vah. Nepoužívat Bearing, Denominator a jiné
  termíny, které geodet nezná.

## Komentáře

- Anglicky, krátce a jednoduše, ideálně 3 až 5 slov. Jen „proč“, ne „co“.
- Hlavička unitu jeden řádek, případně vzorec. `/// <summary>` jeden krátký
  řádek u veřejných deklarací, každý overload vlastní.
- Bez středníků, místo nich čárka nebo tečka. Pomlčka vždy „-“, nikdy
  „–“ ani „—“. Čísla v příkladech s desetinnou čárkou (0,08).
- GEUS v komentářích nezmiňovat (chovat se jako GEUS a KN smí).
- Komentáře autora neměnit, jen opravit věcně špatné.

## Geodézie

- S-JTSK: X na jih, Y na západ. `TPoint.X` je JTSK X, `TPoint.Y` je
  JTSK Y, nic se neprohazuje. Pořadí ve výpisu podle nastavení.
- Číslo bodu má až 15 číslic (předčíslí KÚ), mohou být záporná.
- Celé názvy úloh („polární metoda“, ne „polárka“). Kódy úloh:
  0 ortogonální, 1 polární, 2 vyrovnání do přímky, 3 průsečík přímek,
  4 konstrukční oměrné, 5 protínání z délek, 6 protínání ze směrů,
  7 konstrukční oměrné s vyrovnáním, 8 protínání zpět, 9 kontrolní
  oměrné, 51 nivelace, 65 transformace, 95 výměry.
- Meze: KatV příloha 13.5 a 13.6: md = k·(d+12)/(d+20), k = √2·mxy,
  ud = 2·md, rozhoduje horší kód kvality. Uxy = 2·Mxy. Technická nivelace
  20 mm·√r (vyhl. 31/1995, 4.9). Úhel protnutí 30 až 170 gon.

## Výpočty a formuláře

- Jeden řádek gridu je jedno měření, zadávání jako v GEUSu, jeden
  zápisník je jedna úloha. Do výpočtu vstupuje vždy jen jeden frame.
- Algoritmus: `TFrameAlgorithm.Calculate(AFrame)`, frame dovnitř,
  výsledky zpět do frame. Formuláře dědí z `TCalcBaseForm`
  (`LookupPoint`, `StorePoint`, `OriginalPoint`, `LoadFrame`, `PutRow`,
  `WriteProtocol`, `ApplyDecimals`).
- Body se do seznamu ukládají tlačítkem Výpočet. Existující bod: dialog
  ponechat, nový, průměr, nové číslo. Hláška „Bod … již v seznamu
  existuje“.
- Hotové a odladěné oblasti (komponenty `GeoComponents`, `GeoRow`,
  `GeoDataFrame`) měnit jen po dohodě a vždy nabídnout řešení v aplikaci.

## Protokol

- `AddError` vypíše „CHYBA:“ (výpočet nejde), `AddWarning` vypíše
  „UPOZORNĚNÍ:“ (překročená mez a podobně).
- Popisky bez jednotek, „vyhovuje“ a „nevyhovuje“, pomlčky „-“.
- Sloupec Č. odpovídá řádku v gridu.
- Pomocníci v `ProtocolTable`: `LimitText`, `LimitSource`, `NoMxy`,
  `Num`, `Ang`, šířky sloupců `ColW…`.

## Dokumentace

- MkDocs v `docs/`, jedna stránka na unit nebo úlohu. Text nejdřív v chatu.
- Popisuje jen hotové věci, žádné plány.
- Stránka výpočtu: Co umí, Kde se co počítá, Matematika (tabulka
  značka | v kódu | význam a vzorce 1:1 s kódem), Přesnost.
- Když se změní výpočet, změnit i stránku.
