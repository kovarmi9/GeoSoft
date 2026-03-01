# PROJECT MAP

## 1) Seznam unitů + stručná role

### GUI
- `MainForm` (`src/GUI/MainForm.pas`): Hlavní menu aplikace (Form1), které otevírá ostatní výpočetní/formulářové moduly. Funguje jako centrální navigační rozcestník.
- `PointsManagement` (`src/GUI/PointsManagement.pas`): Správa seznamu bodů v gridu (CRUD, import/export, validace vstupů). Napojeno na globální slovník bodů (`TPointDictionary`).
- `PolarMethod` (`src/GUI/PolarMethod.pas`): UI pro klasickou polární metodu (stanovisko/orientace/detaily) a výpočet detailních bodů. Čte/doplňuje body přes dictionary + `AddPoint` dialog.
- `OrthogonalMethod` (`src/GUI/OrthogonalMethod.pas`): UI pro ortogonální metodu s výpočtem bodů z P/K základny. Využívá algoritmickou jednotku `GeoAlgorithmOrthogonal`.
- `Transformation` (`src/GUI/Transformation.pas`): Formulář pro transformační výpočty a práci s body ve gridu. Využívá sdílený slovník bodů.
- `PolarMethodNew` (`src/GUI/PolarMethodNew.pas`): Novější varianta polární metody nad `TGeoDataFrame`/`TGeoRow`; umí serializovat vstupy do BIN/CSV. Kombinuje grid validace, lookup bodů a export dat.
- `AddPoint` (`src/GUI/AddPoint.pas`): Dialog pro doplnění/ruční zadání bodu při chybějícím záznamu. Ukládá do singleton dictionary.
- `Pokus` (`src/GUI/Pokus.pas`): Pomocný/testovací formulář. Slouží pro experimentální UI logiku.
- `CalcFormBase` (`src/GUI/CalcFormBase.pas`): Jednoduchý základní formulář (base shell). Používá se jako podpůrná GUI jednotka.
- `StringGridValidationUtils` (`src/GUI/StringGridValidationUtils.pas`): Sdílené validační utility pro `TStringGrid` vstupy (čísla bodů, souřadnice, kvalita, výrazy).

### Utils
- `Point` (`src/Utils/Point.pas`): Datový typ bodu (`TPoint`) s validacemi hodnot. Základní model, na kterém stojí většina aplikace.
- `ValidationUtils` (`src/Utils/ValidationUtils.pas`): Nízkourovňové validační funkce pro čísla bodů, souřadnice, kvalitu a text.
- `InputFilterUtils` (`src/Utils/InputFilterUtils.pas`): Filtrace znaků při psaní do gridů (point no, coordinate, quality, description).
- `PointsUtils` (`src/Utils/PointsUtils.pas`): Nesingleton správce kolekce bodů + import/export (TXT/CSV/BIN).
- `PointsUtilsSingleton` (`src/Utils/PointsUtilsSingleton.pas`): Singleton správce bodů (`TPointDictionary.GetInstance`) sdílený napříč formuláři.
- `GeoAlgorithmBase` (`src/Utils/GeoAlgorithmBase.pas`): Základní abstrakce algoritmu (`TAlgorithm`) nad polem bodů.
- `GeoAlgorithmPolar` (`src/Utils/GeoAlgorithmPolar.pas`): Implementace polárního výpočtu nad `TPointsArray`.
- `GeoAlgorithmOrthogonal` (`src/Utils/GeoAlgorithmOrthogonal.pas`): Implementace ortogonálního výpočtu nad `TPointsArray`.

### GeoAlgorithms
- `GeoAlgorithmBase` (`src/GeoAlgorithms/GeoAlgorithmBase.pas`): Rozšířená základní abstrakce algoritmu, která navíc referencuje `GeoDataFrame`.
- `GeoAlgorithmPolar` (`src/GeoAlgorithms/GeoAlgorithmPolar.pas`): Algoritmus polární metody (varianta ve složce GeoAlgorithms).
- `GeoAlgorithmPolar2` (`src/GeoAlgorithms/GeoAlgorithmPolar2.pas`): Polární výpočet pracující přímo s `TGeoDataFrame` vstupy (station/orientation/detail frame).
- `GeoAlgorithmOrthogonal` (`src/GeoAlgorithms/GeoAlgorithmOrthogonal.pas`): Algoritmus ortogonální metody (varianta ve složce GeoAlgorithms).
- `GeoAlgorithmTransformBase` (`src/GeoAlgorithms/GeoAlgorithmTransformBase.pas`): Abstraktní základ pro transformační algoritmy.
- `GeoAlgorithmTransformSimilarity` (`src/GeoAlgorithms/GeoAlgorithmTransformSimilarity.pas`): Similaritní transformace (výpočet parametrů + aplikace).
- `GeoAlgorithmTransformCongruent` (`src/GeoAlgorithms/GeoAlgorithmTransformCongruent.pas`): Kongruentní transformace.
- `GeoAlgorithmTransformAffine` (`src/GeoAlgorithms/GeoAlgorithmTransformAffine.pas`): Afinní transformace včetně maticových pomocných funkcí.

### Components
- `MyStringGrid` (`src/Components/MyStringGrid.pas`): Custom komponenta nad `TStringGrid` (hlavičky, sizing, validace).
- `MyPointsStringGrid` (`src/Components/MyPointsStringGrid.pas`): Specializace `MyStringGrid` pro práci s body.
- `MyStringGridReg` (`src/Components/MyStringGridReg.pas`): Registrace vlastních komponent do Delphi IDE.

### Test_gdf (datový model / test podpora)
- `GeoRow` (`Test_gdf/GeoRow.pas`): Definice geodetického recordu `TGeoRow`, field enumů a binárního load/save řádků.
- `GeoDataFrame` (`Test_gdf/GeoDataFrame.pas`): Tabulkový kontejner nad poli `TGeoRow` + CSV/BIN serializace.

## 2) Hlavní závislosti mezi unity (`uses`)

### Klíčové vazby (architektura)
- `MainForm` -> `PointsManagement`, `PolarMethod`, `PolarMethodNew`, `OrthogonalMethod`, `Transformation`, `Pokus`.
- GUI výpočtové formuláře (`PolarMethod`, `OrthogonalMethod`, `Transformation`, `AddPoint`, `PointsManagement`, `PolarMethodNew`) -> `Point` + `PointsUtilsSingleton`.
- `Point` -> `ValidationUtils`.
- `PointsManagement`/`AddPoint`/`PolarMethodNew` -> `StringGridValidationUtils` + `InputFilterUtils`.
- `PolarMethod` -> `GeoAlgorithmPolar`; `OrthogonalMethod` -> `GeoAlgorithmOrthogonal`.
- Transformační modul -> `GeoAlgorithmTransformBase` + konkrétní transformace (`Similarity`, `Congruent`, `Affine`).
- `GeoAlgorithmPolar2` + `PolarMethodNew` -> `GeoDataFrame` + `GeoRow`.
- `MyPointsStringGrid` -> `MyStringGrid`; `MyStringGridReg` -> `MyStringGrid`, `MyPointsStringGrid`.

### Kompletní projektové `uses` vazby mezi unity
- `AddPoint` -> `Point`, `StringGridValidationUtils`, `ValidationUtils`, `InputFilterUtils`, `PointsManagement`, `PointsUtilsSingleton`
- `GeoAlgorithmBase` (`src/GeoAlgorithms`) -> `Point`, `GeoDataFrame`
- `GeoAlgorithmBase` (`src/Utils`) -> `Point`
- `GeoAlgorithmOrthogonal` (`src/GeoAlgorithms`) -> `GeoAlgorithmBase`, `Point`
- `GeoAlgorithmOrthogonal` (`src/Utils`) -> `GeoAlgorithmBase`, `Point`
- `GeoAlgorithmPolar` (`src/GeoAlgorithms`) -> `GeoAlgorithmBase`, `Point`
- `GeoAlgorithmPolar` (`src/Utils`) -> `GeoAlgorithmBase`, `Point`
- `GeoAlgorithmPolar2` -> `GeoAlgorithmBase`, `GeoRow`, `GeoDataFrame`
- `GeoAlgorithmTransformAffine` -> `Point`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`
- `GeoAlgorithmTransformBase` -> `Point`, `GeoAlgorithmBase`
- `GeoAlgorithmTransformCongruent` -> `Point`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`
- `GeoAlgorithmTransformSimilarity` -> `Point`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`
- `GeoDataFrame` -> `GeoRow`
- `MainForm` -> `Point`, `AddPoint`, `PointsManagement`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`, `GeoAlgorithmTransformSimilarity`, `GeoAlgorithmTransformCongruent`, `GeoAlgorithmTransformAffine`, `MyStringGrid`, `MyPointsStringGrid`, `PolarMethod`, `OrthogonalMethod`, `Transformation`, `Pokus`, `PolarMethodNew`
- `MyPointsStringGrid` -> `MyStringGrid`
- `MyStringGridReg` -> `MyStringGrid`, `MyPointsStringGrid`
- `OrthogonalMethod` -> `PointsUtilsSingleton`, `AddPoint`, `Point`, `GeoAlgorithmBase`, `GeoAlgorithmOrthogonal`
- `Point` -> `ValidationUtils`
- `PointsManagement` -> `StringGridValidationUtils`, `InputFilterUtils`, `PointsUtilsSingleton`, `ValidationUtils`, `Point`, `MyPointsStringGrid`
- `PointsUtils` -> `Point`
- `PointsUtilsSingleton` -> `Point`
- `Pokus` -> `Point`, `AddPoint`, `CalcFormBase`
- `PolarMethod` -> `PointsUtilsSingleton`, `Point`, `AddPoint`, `GeoAlgorithmBase`, `GeoAlgorithmPolar`
- `PolarMethodNew` -> `MyPointsStringGrid`, `MyStringGrid`, `PointsUtilsSingleton`, `Point`, `AddPoint`, `StringGridValidationUtils`, `InputFilterUtils`, `GeoRow`, `GeoDataFrame`
- `Transformation` -> `PointsUtilsSingleton`, `Point`

## 3) Hlavní vstupní body

### DPR programy
- GUI hlavní aplikace: `src/GUI/GeoSoft.dpr`
- Console app: `src/Console/GeoSoftConsole.dpr`
- Console testy: `src/Console/PolarTest.dpr`, `src/Console/OrthogonalTest.dpr`
- Algoritmické testy: `src/GeoAlgorithms/PolarTest.dpr`, `src/GeoAlgorithms/PolarTest2.dpr`, `src/GeoAlgorithms/OrthogonalTest.dpr`, `src/GeoAlgorithms/TransformTest.dpr`, `src/GeoAlgorithms/TransformTestTXT.dpr`, `src/GeoAlgorithms/TestReadTXT.dpr`
- GDF testy: `Test_gdf/TestGeoRow.dpr`, `Test_gdf/TestGeoDataFrame.dpr`

### Hlavní formy GUI (`GeoSoft.dpr` -> `Application.CreateForm`)
- `TForm1` / `MainForm`
- `TForm2` / `PointsManagement`
- `TForm3` / `PolarMethod`
- `TForm4` / `OrthogonalMethod`
- `TForm5` / `Transformation`
- `TForm6` / `AddPoint`
- `TForm7` / `Pokus`
- `TForm8` / `CalcFormBase`
- `TForm9` / `PolarMethodNew`

### Datamoduly
- `TDataModule` nebyl v projektu nalezen.

## 4) Potenciálně kritické části

- Globální stav / singleton:
  - `PointsUtilsSingleton.pas`: `class var FInstance` + centrální mutable dictionary pro všechny formuláře.
  - `PointsManagement.pas`: globální proměnné `PointDict` a `Point` ve `var` sekci unitu.
  - GUI formuláře jsou globální instance (`Form1..Form9`) vytvářené při startu.

- I/O a persistence:
  - `PointsUtils.pas` a `PointsUtilsSingleton.pas`: přímé souborové operace (`AssignFile`, `Reset`, `Rewrite`, `TFileStream`) pro TXT/CSV/BIN.
  - `GeoRow.pas` + `GeoDataFrame.pas`: binární i CSV serializace (`SaveRow/LoadRow`, `SaveToFile/LoadFromFile/ToCSV/FromCSV`).
  - `PolarMethodNew.pas`: zápis pracovních dat (`Polar_*.bin`, `Polar_*.csv`) do aktuálního adresáře.

- DB / web stack indikace:
  - `MainForm.pas` má v `uses` (`Data.DB`, `Vcl.DBGrids`, `Web.HTTPApp`, `Web.DBWeb`, `Web.DBXpressWeb`), ale v kódu není zřejmý aktivní datamodul ani DB connection vrstva.
  - Riziko: „mrtvé“ nebo neudržované závislosti v hlavní GUI jednotce.

- Threads:
  - Nebyly nalezeny explicitní thread konstrukce (`TThread`, `BeginThread`, `CreateThread`). Aktuálně to vypadá na single-thread UI + synchronní I/O.

- Strukturální rizika v kódu:
  - Duplicity názvů unitů: `GeoAlgorithmBase`, `GeoAlgorithmPolar`, `GeoAlgorithmOrthogonal` existují současně ve `src/Utils` i `src/GeoAlgorithms`.
  - Velké komentované bloky historického kódu před aktivní unit deklarací: minimálně `PointsManagement.pas`, `PolarMethod.pas`, `OrthogonalMethod.pas`, `PolarMethodNew.pas`.
  - Riziko: vyšší pravděpodobnost záměny při úpravách a nejasné rozlišení „aktivní vs legacy“ implementace.

## Poznámka
- Mapa je sestavená z aktuálního stavu zdrojáků (`.pas`/`.dpr`) v repozitáři, včetně testovacích a experimentálních jednotek.
