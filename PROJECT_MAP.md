# PROJECT MAP

## 1) Seznam unitů + stručná role

### GUI
- `MainForm` (`src/GUI/MainForm.pas`): Hlavní menu aplikace (Form1), které otevírá `PointsManagement`, `PolarMethod`, `OrthogonalMethod`, `Transformation`, `CheckMeasurement` a `PolarMethodNew`.
- `PointsManagement` (`src/GUI/PointsManagement.pas`): Správa seznamu bodů v `TMyPointsStringGrid`, import/export TXT/CSV/BIN, práce nad globálním singletonem `TPointDictionary` a prefix state (`PointPrefixState`). Pořád používá hlavně starší callback filtry z `InputFilterUtils` a vlastní logiku v `KeyDown`.
- `PolarMethod` (`src/GUI/PolarMethod.pas`): Klasická polární metoda nad `TStringGrid`, lookup bodů přes singleton dictionary a výpočet přes `GeoAlgorithmPolar`.
- `OrthogonalMethod` (`src/GUI/OrthogonalMethod.pas`): UI pro ortogonální metodu s `TMyPointsStringGrid`, validacemi vstupu, vyhodnocováním výrazů při opuštění buňky a výpočtem přes `GeoAlgorithmOrthogonal`.
- `Transformation` (`src/GUI/Transformation.pas`): Formulář pro práci s transformační tabulkou bodů. Aktuálně používá sdílený slovník bodů a vlastní grid rendering, ale transformační algoritmy neimportuje přímo v této unitě.
- `PolarMethodNew` (`src/GUI/PolarMethodNew.pas`): Novější varianta polární metody nad `TGeoDataFrame`/`TGeoRow`; používá custom gridy, callback validace, lookup bodů a ukládání pracovních dat do BIN/CSV.
- `AddPoint` (`src/GUI/AddPoint.pas`): Dialog pro ruční zadání chybějícího bodu, postavený nad `TMyStringGrid`. Pořád používá starý callback systém `SetColumnValidator(...)`.
- `CheckMeasurement` (`src/GUI/CheckMeasurement.pas`): Pomocný formulář (Form7), který otevírá dialog `AddPoint` a pomocný formulář `CalcFormBase`.
- `CalcFormBase` (`src/GUI/CalcFormBase.pas`): Jednoduchý základní formulář bez vlastní doménové logiky.
- `StringGridValidationUtils` (`src/GUI/StringGridValidationUtils.pas`): Sdílené validační utility pro `TStringGrid` a custom gridy.

### Utils
- `Point` (`src/Utils/Point.pas`): Datový typ bodu (`TPoint`) s validacemi hodnot. Základní model, na kterém stojí většina aplikace.
- `ValidationUtils` (`src/Utils/ValidationUtils.pas`): Nízkourovňové validační funkce pro čísla bodů, souřadnice, kvalitu a text.
- `InputFilterUtils` (`src/Utils/InputFilterUtils.pas`): Filtrace znaků při psaní do gridů (point no, coordinate, quality, description).
- `PointPrefixState` (`src/Utils/PointPrefixState.pas`): Sdílený globální stav prefixů bodů (`KU`, `ZPMZ`, `KK`, `Popis`) a helpery pro naplnění/uložení comboboxů a skládání ID bodu.
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
- `MyStringGrid` (`src/Components/MyStringGrid.pas`): Custom komponenta nad `TStringGrid` (hlavičky, sizing, Enter/Tab navigace, validace). Obsahuje `published` property `ColumnFilters`, takže filtry sloupců jsou vidět v Delphi Object Inspectoru. Umí jak starý callback styl `SetColumnValidator(...)`, tak nový filter-based styl přes `ColumnValidation`.
- `MyPointsStringGrid` (`src/Components/MyPointsStringGrid.pas`): Specializace `MyStringGrid` pro práci s body.
- `MyStringGridReg` (`src/Components/MyStringGridReg.pas`): Registrace vlastních komponent do Delphi IDE.
- `ColumnValidation` (`src/Components/ColumnValidation.pas`): Pomocné typy a filtrace pro `MyStringGrid` sloupce. Aktuálně řeší typy `cdtNone`, `cdtInteger`, `cdtFloat`, `cdtExpression`, kolekci `TColumnFilters`, filtraci znaků při psaní a finální validaci textu při opuštění buňky.

### Test_gdf (datový model / test podpora)
- `GeoRow` (`Test_gdf/GeoRow.pas`): Definice geodetického recordu `TGeoRow`, field enumů a binárního load/save řádků.
- `GeoDataFrame` (`Test_gdf/GeoDataFrame.pas`): Tabulkový kontejner nad poli `TGeoRow` + CSV/BIN serializace.

## 2) Hlavní závislosti mezi unity (`uses`)

### Klíčové vazby (architektura)
- `MainForm` -> `PointsManagement`, `PolarMethod`, `PolarMethodNew`, `OrthogonalMethod`, `Transformation`, `CheckMeasurement`.
- GUI výpočtové formuláře (`PolarMethod`, `OrthogonalMethod`, `Transformation`, `AddPoint`, `PointsManagement`, `PolarMethodNew`) -> `Point` + `PointsUtilsSingleton`.
- `Point` -> `ValidationUtils`.
- `PointsManagement`/`AddPoint`/`OrthogonalMethod`/`PolarMethodNew` -> `StringGridValidationUtils` + `InputFilterUtils`.
- `MyStringGrid` -> `ColumnValidation`
- `PolarMethod` -> `GeoAlgorithmPolar`; `OrthogonalMethod` -> `GeoAlgorithmOrthogonal`.
- `PointPrefixState` -> `PointsManagement`, `AddPoint`, `OrthogonalMethod`, `PolarMethodNew`.
- Transformační algoritmy (`GeoAlgorithmTransformBase`, `Similarity`, `Congruent`, `Affine`) jsou součástí GUI projektu přes `GeoSoft.dpr`, ale formulář `Transformation` je aktuálně neimportuje přímo.
- `GeoAlgorithmPolar2` + `PolarMethodNew` -> `GeoDataFrame` + `GeoRow`.
- `MyPointsStringGrid` -> `MyStringGrid`; `MyStringGridReg` -> `MyStringGrid`, `MyPointsStringGrid`.
- `ColumnValidation` je navázaný přímo na komponentu, ne na obecné utily aplikace.
- Projekt teď používá dva validační směry zároveň:
  - starší callback styl přes `InputFilterUtils` a `SetColumnValidator(...)`
  - novější komponentový styl přes `ColumnFilters` a `ColumnValidation`

### Vybrané aktuální `uses` vazby mezi project unity
- `AddPoint` -> `Point`, `StringGridValidationUtils`, `InputFilterUtils`, `PointsUtilsSingleton`, `MyStringGrid`, `PointPrefixState`
- `CheckMeasurement` -> `Point`, `AddPoint`, `CalcFormBase`
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
- `MainForm` -> `Point`, `AddPoint`, `PointsManagement`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`, `GeoAlgorithmTransformSimilarity`, `GeoAlgorithmTransformCongruent`, `GeoAlgorithmTransformAffine`, `MyStringGrid`, `MyPointsStringGrid`, `CheckMeasurement`
- `MyPointsStringGrid` -> `MyStringGrid`
- `MyStringGridReg` -> `MyStringGrid`, `MyPointsStringGrid`
- `MyStringGrid` -> `ColumnValidation`
- `OrthogonalMethod` -> `PointsUtilsSingleton`, `AddPoint`, `Point`, `GeoAlgorithmBase`, `GeoAlgorithmOrthogonal`, `MyPointsStringGrid`, `PointPrefixState`, `StringGridValidationUtils`, `InputFilterUtils`, `MyStringGrid`
- `Point` -> `ValidationUtils`
- `PointsManagement` -> `StringGridValidationUtils`, `InputFilterUtils`, `PointsUtilsSingleton`, `ValidationUtils`, `Point`, `MyPointsStringGrid`, `PointPrefixState`, `MyStringGrid`
- `PointPrefixState` -> `SysUtils`, `StdCtrls`
- `PointsUtils` -> `Point`
- `PointsUtilsSingleton` -> `Point`
- `PolarMethod` -> `PointsUtilsSingleton`, `Point`, `AddPoint`, `GeoAlgorithmBase`, `GeoAlgorithmPolar`
- `PolarMethodNew` -> `MyPointsStringGrid`, `MyStringGrid`, `PointsUtilsSingleton`, `Point`, `AddPoint`, `StringGridValidationUtils`, `InputFilterUtils`, `GeoRow`, `GeoDataFrame`, `PointPrefixState`
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
- `TForm7` / `CheckMeasurement`
- `TForm8` / `CalcFormBase`
- `TForm9` / `PolarMethodNew`

### Datamoduly
- `TDataModule` nebyl v projektu nalezen.

## 4) Potenciálně kritické části

- Globální stav / singleton:
  - `PointsUtilsSingleton.pas`: `class var FInstance` + centrální mutable dictionary pro všechny formuláře.
  - `PointsManagement.pas`: globální proměnné `PointDict` a `Point` ve `var` sekci unitu.
  - `PointPrefixState.pas`: globální stav `GPointPrefix` sdílený mezi více formuláři.
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
  - Velké komentované bloky historického kódu před aktivní unit deklarací: minimálně `PolarMethod.pas`.
  - Riziko: vyšší pravděpodobnost záměny při úpravách a nejasné rozlišení „aktivní vs legacy“ implementace.

## 5) Poznámka k `MyStringGrid.ColumnFilters`

- `ColumnFilters` je `published` property komponenty `MyStringGrid`, proto je vidět v Object Inspectoru.
- `ColumnFilters` je kolekce `TColumnFilters`, takže Delphi pro ni automaticky nabízí standardní collection editor.
- Počet itemů se interně dorovnává na `ColCount` přes `EnsureColumnFilterCount` v `MyStringGrid`.
- Jeden item odpovídá jednomu sloupci a `Column` je odvozený z `Index`, takže se ručně nenastavuje.
- Tlačítka `Add/Delete` jsou ve standardním Delphi editoru pořád vidět, ale komponenta si kolekci po změnách znovu srovná na počet sloupců.
- Samotná filtrace znaků běží při psaní v `MyStringGrid.KeyPress -> ApplyColumnFilter -> ApplyColumnFilterKeyPress`.
- Finální kontrola celé hodnoty běží při opuštění buňky v `MyStringGrid` přes `ValidateTextByColumnFilter(...)`.
- `MyStringGrid` je teď připravený na přechod od starých callback filtrů k obecnějším pravidlům po sloupcích, ale formuláře zatím nejsou sjednocené na jeden styl.

## Poznámka
- Mapa byla aktualizována podle aktuálního stavu zdrojáků (`.pas`/`.dpr`) v repozitáři dne 11. března 2026. Je zaměřená na ručně ověřené hlavní vazby a vstupní body, ne na úplný výpis všech VCL/System závislostí.
