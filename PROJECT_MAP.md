# PROJECT MAP

## 1) Seznam unitů + stručná role

### GUI
- `MainForm` (`src/GUI/MainForm.pas`): Hlavní menu aplikace (Form1). Interface `uses` zahrnuje pouze `Point`, `AddPoint`, `PointsManagement` a transformační algoritmy + custom gridy. V **implementation** `uses` přidává `PolarMethod`, `OrthogonalMethod`, `Transformation`, `CheckMeasurement`, `PolarMethodNew` (formuláře jsou tedy závislé pouze v runtime části). Obsahuje také mrtvé závislosti na DB/Web stacku (`Data.DB`, `Vcl.DBGrids`, `Web.HTTPApp`, `Web.DBWeb`, `Web.DBXpressWeb`).
- `PointsManagement` (`src/GUI/PointsManagement.pas`): Správa seznamu bodů v `TMyPointsStringGrid`, import/export TXT/CSV/BIN, práce nad globálním singletonem `TPointDictionary` a prefix state (`PointPrefixState`). Používá starší callback filtry z `InputFilterUtils` a vlastní logiku v `KeyDown`.
- `PolarMethod` (`src/GUI/PolarMethod.pas`): ⚠️ **Celá unit je zakomentována** – pouze mrtvý kód. TForm3 není aktivní. Formulář je do projektu zahrnován přes implementation uses v MainForm, ale unit sama neposkytuje žádné třídy ani logiku.
- `OrthogonalMethod` (`src/GUI/OrthogonalMethod.pas`): UI pro ortogonální metodu s `TMyPointsStringGrid`, validacemi vstupu, vyhodnocováním výrazů při opuštění buňky a výpočtem přes `GeoAlgorithmOrthogonal`.
- `Transformation` (`src/GUI/Transformation.pas`): Formulář pro práci s transformační tabulkou bodů. Používá sdílený slovník bodů a vlastní grid rendering, transformační algoritmy neimportuje přímo.
- `PolarMethodNew` (`src/GUI/PolarMethodNew.pas`): Novější varianta polární metody nad `TGeoDataFrame`/`TGeoRow`; používá custom gridy, callback validace, lookup bodů a ukládání pracovních dat do BIN/CSV.
- `AddPoint` (`src/GUI/AddPoint.pas`): Dialog pro ruční zadání chybějícího bodu, postavený nad `TMyStringGrid`. Používá starý callback systém `SetColumnValidator(...)`. Exportuje globální `NewPoint: TPoint`.
- `CheckMeasurement` (`src/GUI/CheckMeasurement.pas`): Pomocný formulář (Form7), který otevírá dialog `AddPoint` a pomocný formulář `CalcFormBase`. Nově také závisí na `MyStringGrid`.
- `CalcFormBase` (`src/GUI/CalcFormBase.pas`): Jednoduchý základní formulář (Form8) bez vlastní doménové logiky.
- `StringGridValidationUtils` (`src/GUI/StringGridValidationUtils.pas`): Sdílené validační utility pro `TStringGrid` a custom gridy (procedury, žádné třídy).

### Utils
- `Point` (`src/Utils/Point.pas`): Datový typ bodu (`TPoint`) s poli PointNumber, X, Y, Z, Quality, Description + ukazatel `PPoint`. Základní model celé aplikace.
- `ValidationUtils` (`src/Utils/ValidationUtils.pas`): Nízkourovňové statické validační funkce pro čísla bodů, souřadnice, kvalitu a text.
- `InputFilterUtils` (`src/Utils/InputFilterUtils.pas`): Filtrace znaků při psaní do gridů – typ `TGridCharFilter` (procedure type).
- `PointPrefixState` (`src/Utils/PointPrefixState.pas`): Sdílený globální stav prefixů bodů (`GPointPrefix: TPointPrefixState`) – KU, ZPMZ, KK, Popis. Helpery pro naplnění/uložení comboboxů a skládání ID bodu.
- `PointsUtils` (`src/Utils/PointsUtils.pas`): Nesingleton správce kolekce bodů `TPointDictionary` + import/export (TXT/CSV/BIN).
- `PointsUtilsSingleton` (`src/Utils/PointsUtilsSingleton.pas`): Singleton správce bodů (`TPointDictionary.GetInstance`) sdílený napříč formuláři. `FInstance` je class var uvnitř třídy.
- `GeoAlgorithmBase` (`src/Utils/GeoAlgorithmBase.pas`): Základní abstrakce algoritmu `TAlgorithm` nad `TPointsArray`. Závislý pouze na `Point`.
- `GeoAlgorithmPolar` (`src/Utils/GeoAlgorithmPolar.pas`): Implementace polárního výpočtu nad `TPointsArray`. Typy `TOrientation`, `TOrientations`, třída `TPolarMethodAlgorithm` se statickými property A (station) a B (orientations).
- `GeoAlgorithmOrthogonal` (`src/Utils/GeoAlgorithmOrthogonal.pas`): Implementace ortogonálního výpočtu nad `TPointsArray`. Třída `TOrthogonalMethodAlgorithm` se statickými property StartPoint, EndPoint.

### GeoAlgorithms
- `GeoAlgorithmBase` (`src/GeoAlgorithms/GeoAlgorithmBase.pas`): Rozšířená základní abstrakce algoritmu – navíc referencuje `GeoDataFrame` (oproti verzi v Utils).
- `GeoAlgorithmPolar` (`src/GeoAlgorithms/GeoAlgorithmPolar.pas`): Polární výpočet – objektová varianta s property Station, Orientations (oproti statickým property v Utils verzi).
- `GeoAlgorithmPolar2` (`src/GeoAlgorithms/GeoAlgorithmPolar2.pas`): Polární výpočet pracující přímo s `TGeoDataFrame` vstupy (StationFrame / OrientationFrame / PointsFrame).
- `GeoAlgorithmOrthogonal` (`src/GeoAlgorithms/GeoAlgorithmOrthogonal.pas`): Ortogonální výpočet – objektová varianta (oproti statickým property v Utils verzi).
- `GeoAlgorithmTransformBase` (`src/GeoAlgorithms/GeoAlgorithmTransformBase.pas`): Abstraktní základ `TTransformationAlgorithm` pro transformační algoritmy.
- `GeoAlgorithmTransformSimilarity` (`src/GeoAlgorithms/GeoAlgorithmTransformSimilarity.pas`): Similaritní transformace. Private parametry Lambda1, Lambda2, Omega, Q, X0, Y0.
- `GeoAlgorithmTransformCongruent` (`src/GeoAlgorithms/GeoAlgorithmTransformCongruent.pas`): Kongruentní transformace. Stejná struktura parametrů jako Similarity.
- `GeoAlgorithmTransformAffine` (`src/GeoAlgorithms/GeoAlgorithmTransformAffine.pas`): Afinní transformace s maticovými pomocnými funkcemi (`TMatrix`, `TVector`, `InvertMatrix`, `MultiplyMatrixVector`). Parametry a1–a3, b1–b3.

### Components
- `MyStringGrid` (`src/Components/MyStringGrid.pas`): Custom komponenta nad `TStringGrid`. Published property `ColumnFilters` (viditelná v Object Inspectoru). Enum `TEnterEndBehavior` (ebStayOnLastCell, ebWrapToStart, ebAddRow, ebMoveFocusNext). Obsahuje jak starý callback styl (`SetColumnValidator`, `TMyGridKeyValidator`), tak nový filter-based styl přes `ColumnValidation`.
- `MyPointsStringGrid` (`src/Components/MyPointsStringGrid.pas`): Specializace `MyStringGrid` pro práci s body – EnterEndBehavior := ebAddRow.
- `MyFieldsStringGrid` (`src/Components/MyFieldsStringGrid.pas`): `TMyFieldsStringGrid = class(TMyStringGrid)` specializace pro `TGeoField` sloupce. Published property `GeoFields: TGeoFields` – dynamicky buduje sloupce přes `RebuildColumns`. Per-instance kopie `FColumnData: array[TGeoField] of TGeoFieldColumn`, metody `FieldToCol`/`ColToField`/`SetGeoRow`/`GetGeoRow`. Nahrazuje starší `GeoFieldsStringGrid`.
- `MyStringGridReg` (`src/Components/MyStringGridReg.pas`): Registrace vlastních komponent do Delphi IDE.
- `ColumnValidation` (`src/Components/ColumnValidation.pas`): Typy a logika pro validaci sloupců. Enum `TColumnDataType` (fNone, fInteger, fFloat, fExpression), record `TColumnFilter`, třída `TColumnFilterItem`, kolekce `TColumnFilters`. Expression evaluace přes MSScriptControl COM.
- `GeoFieldColumn` (`src/Components/GeoFieldColumn.pas`): Record `TGeoFieldColumn` (DisplayName + `TColumnFilter`) a globální `GeoFieldColumnData: array[TGeoField] of TGeoFieldColumn` naplněný v `initialization`. Mapování enum `TGeoField` → jméno sloupce + validační pravidla. Závisí na `GeoRow`, `ColumnValidation`. Obecnější nástupce `GeoFieldMeta` z `Test_FieldGrid`.

### Komponenty (design-time package `MyComponentsR.dpk`)
Samostatná větev komponent v rootu `Komponenty/`, nezávislá na `src/Components/`. Instalovaná v Delphi IDE přes package, paleta `MyComponents`.
- `MyGrid` (`Komponenty/MyGrid.pas`): `TMyGrid = class(TStringGrid)` – čistý základní grid. Published properties `ColumnHeaders`, `RowHeaders`, `EnterEndBehavior`. Konstanta `MyGridDefaultOptions` pro výchozí options. Virtuální `CommitCell` (commit hook před každým pohybem), `MoveToNextCell` pro navigační logiku + `FNavigating` flag proti dvojí navigaci. Enum `TEnterEndBehavior` definován zde.
- `GeoGrid` (`Komponenty/GeoGrid.pas`): `TGeoGrid = class(TStringGrid)` – samostatná specializace gridu s vlastní navigací a podporou hlaviček. Všechny metody mají XMLDoc komentáře. Klíčové části:
    - Vnitřní `TGeoInplaceEdit = class(TInplaceEdit)` podstrčený přes override `CreateEditor`. Grid i InplaceEdit v `KeyDown` zachytávají VK_RETURN/VK_TAB a delegují na **virtuální** `TGeoGrid.MoveToNextCell(PressedKey, Shift)`.
    - `MoveToNextCell` zavře editor, posune Col/Row, na poslední buňce aplikuje `FEnterEndBehavior`. Pro `ebMoveFocusNext` posílá `WM_NEXTDLGCTL` formuláři přes `PostMessage` – respektuje Shift+Tab pro reverse. Po pohybu znovu otevře editor **pouze pokud stisknutá klávesa byla Enter** – Tab jen naviguje.
    - Publikované `ColumnHeaders: TStrings` a `RowHeaders: TStrings` (editovatelné v Object Inspectoru). Virtuální `UpdateHeaders` plní buňky fixních řádků/sloupců. Override `Loaded` volá `UpdateHeaders` po streamování z DFM.
    - Virtuální `IsHeaderCell(ACol, ARow)` a `IsDataCell(ACol, ARow)` – pohodlné helpery pro potomky (rozlišení fixních a datových buněk).
    - `DrawCell` override používá `IsHeaderCell` a vykresluje hlavičky tučně + centrovaně (clBtnFace + fsBold).
    - Konstruktor nastavuje `[goEditing, goTabs, goColSizing, goRowSizing]` do `Options`.
    - Enum `TEnterEndBehavior` je redefinovaný lokálně (nezávislý na `MyGrid`).
  Určeno jako základ budoucího `TGeoFieldsGrid`, který přepíše `UpdateHeaders` a naplní `ColumnHeaders` z `TGeoFields` (+ `stored False` pro nepřelévání do DFM). `MainForm` má unit v `uses`, ale komponenta z designeru byla odstraněna (hotová, čeká na produkční nasazení).
- `MyGridReg` (`Komponenty/MyGridReg.pas`): Registrace `TMyGrid` a `TGeoGrid` do IDE palety.

### Test_gdf (datový model / test podpora)
- `GeoRow` (`Test_gdf/GeoRow.pas`): Definice `TGeoField` (enum, 18 polí), `TGeoFields` (set), `TGeoRow` (record), `TGeoRowArray`. Konstanta `GeoFieldNames` pro mapování názvů.
- `GeoDataFrame` (`Test_gdf/GeoDataFrame.pas`): Tabulkový kontejner `TGeoDataFrame` nad `TGeoRowArray` + CSV/BIN serializace.

### Test_FieldGrid (prototyp / test podpora)
- `GeoFieldMeta` (`Test_FieldGrid/GeoFieldMeta.pas`): Starší varianta `TGeoFieldMeta` – nahrazena `GeoFieldColumn` v `src/Components/`. V adresáři zůstává jen zkompilované DCU jako historie.
- `GeoFieldColumn` (`Test_FieldGrid/GeoFieldColumn.pas`): Lokální kopie záznamu `TGeoFieldColumn` pro testovací projekt.
- `GeoFieldsStringGrid` (`Test_FieldGrid/GeoFieldsStringGrid.pas`): Custom grid `TGeoFieldsStringGrid` specificky pro `TGeoField`. Metody FieldToCol, ColToField, SetGeoRow, GetGeoRow. Závisí na `GeoRow`, `ColumnValidation`, `GeoFieldMeta`, `MyStringGrid`. V produkci nahrazován `MyFieldsStringGrid` (`src/Components/`).
- `Test_FieldGrid` (`Test_FieldGrid/Test_FieldGrid.pas`): Testovací formulář (TForm1) s CheckListBox pro výběr zobrazovaných polí.

---

## 2) Hlavní závislosti mezi unity (`uses`)

### Klíčové vazby (architektura)
- `MainForm` (interface) -> `Point`, `AddPoint`, `PointsManagement`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`, `GeoAlgorithmTransformSimilarity`, `GeoAlgorithmTransformCongruent`, `GeoAlgorithmTransformAffine`, `MyStringGrid`, `MyPointsStringGrid`
- `MainForm` (implementation) -> `PolarMethod` *(zakomentovaná unit)*, `OrthogonalMethod`, `Transformation`, `CheckMeasurement`, `PolarMethodNew`
- GUI výpočtové formuláře -> `Point` + `PointsUtilsSingleton`
- `Point` -> `ValidationUtils`
- `PointsManagement`/`AddPoint`/`OrthogonalMethod`/`PolarMethodNew` -> `StringGridValidationUtils` + `InputFilterUtils`
- `MyStringGrid` -> `ColumnValidation`
- `OrthogonalMethod` -> `GeoAlgorithmOrthogonal` (src/GeoAlgorithms)
- `PointPrefixState` -> `PointsManagement`, `AddPoint`, `OrthogonalMethod`, `PolarMethodNew`
- `GeoAlgorithmPolar2` + `PolarMethodNew` -> `GeoDataFrame` + `GeoRow`
- `GeoAlgorithmBase` (GeoAlgorithms) -> `Point`, `GeoDataFrame`
- `MyPointsStringGrid` -> `MyStringGrid`; `MyStringGridReg` -> `MyStringGrid`, `MyPointsStringGrid`
- `GeoFieldsStringGrid` -> `MyStringGrid`, `GeoRow`, `ColumnValidation`, `GeoFieldMeta`
- `GeoFieldMeta` -> `GeoRow`, `ColumnValidation`

### Aktuální `uses` vazby (ověřeno ke stavu 28. března 2026)
- `AddPoint` -> `Point`, `StringGridValidationUtils`, `InputFilterUtils`, `PointsUtilsSingleton`, `MyStringGrid`, `PointPrefixState`
- `CalcFormBase` -> *(pouze VCL/system)*
- `CheckMeasurement` -> `Point`, `AddPoint`, `CalcFormBase`, `MyStringGrid`
- `GeoAlgorithmBase` (GeoAlgorithms) -> `Point`, `GeoDataFrame`
- `GeoAlgorithmBase` (Utils) -> `Point`
- `GeoAlgorithmOrthogonal` (GeoAlgorithms) -> `GeoAlgorithmBase`, `Point`
- `GeoAlgorithmOrthogonal` (Utils) -> `GeoAlgorithmBase`, `Point`
- `GeoAlgorithmPolar` (GeoAlgorithms) -> `GeoAlgorithmBase`, `Point`
- `GeoAlgorithmPolar` (Utils) -> `GeoAlgorithmBase`, `Point`
- `GeoAlgorithmPolar2` -> `GeoAlgorithmBase`, `GeoRow`, `GeoDataFrame`
- `GeoAlgorithmTransformAffine` -> `Point`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`
- `GeoAlgorithmTransformBase` -> `Point`, `GeoAlgorithmBase`
- `GeoAlgorithmTransformCongruent` -> `Point`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`
- `GeoAlgorithmTransformSimilarity` -> `Point`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`
- `GeoDataFrame` -> `GeoRow`
- `GeoFieldMeta` -> `GeoRow`, `ColumnValidation`
- `GeoFieldsStringGrid` -> `GeoRow`, `ColumnValidation`, `GeoFieldMeta`, `MyStringGrid`
- `InputFilterUtils` -> *(SysUtils, Vcl.Grids)*
- `MainForm` (interface) -> `Point`, `AddPoint`, `PointsManagement`, `GeoAlgorithmBase`, `GeoAlgorithmTransformBase`, `GeoAlgorithmTransformSimilarity`, `GeoAlgorithmTransformCongruent`, `GeoAlgorithmTransformAffine`, `MyStringGrid`, `MyPointsStringGrid`
- `MainForm` (implementation) -> `PolarMethod`*, `OrthogonalMethod`, `Transformation`, `CheckMeasurement`, `PolarMethodNew`
- `MyPointsStringGrid` -> `MyStringGrid`
- `MyStringGrid` -> `ColumnValidation`
- `MyStringGridReg` -> `MyStringGrid`, `MyPointsStringGrid`
- `OrthogonalMethod` -> `PointsUtilsSingleton`, `AddPoint`, `Point`, `GeoAlgorithmBase`, `GeoAlgorithmOrthogonal`, `MyPointsStringGrid`, `PointPrefixState`, `StringGridValidationUtils`, `InputFilterUtils`, `MyStringGrid`
- `Point` -> `ValidationUtils`
- `PointPrefixState` -> `SysUtils`, `StdCtrls`
- `PointsManagement` -> `StringGridValidationUtils`, `InputFilterUtils`, `PointsUtilsSingleton`, `ValidationUtils`, `Point`, `MyPointsStringGrid`, `PointPrefixState`, `MyStringGrid`
- `PointsUtils` -> `Point`
- `PointsUtilsSingleton` -> `Point`
- `PolarMethod` -> *(celá unit zakomentována)*
- `PolarMethodNew` -> `MyPointsStringGrid`, `MyStringGrid`, `PointsUtilsSingleton`, `Point`, `AddPoint`, `StringGridValidationUtils`, `InputFilterUtils`, `GeoRow`, `GeoDataFrame`, `PointPrefixState`
- `Test_FieldGrid` -> `GeoRow`, `GeoDataFrame`, `MyStringGrid`, `ColumnValidation`, `GeoFieldMeta`, `GeoFieldsStringGrid`
- `Transformation` -> `PointsUtilsSingleton`, `Point`
- `ValidationUtils` -> *(SysUtils, Math)*

*(* PolarMethod unit je kompletně zakomentována – závislost existuje jen textově)*

---

## 3) Hlavní vstupní body

### DPR programy
- GUI hlavní aplikace: `src/GUI/GeoSoft.dpr`
- Console app: `src/Console/GeoSoftConsole.dpr`
- Console testy: `src/Console/PolarTest.dpr`, `src/Console/OrthogonalTest.dpr`
- Algoritmické testy: `src/GeoAlgorithms/PolarTest.dpr`, `src/GeoAlgorithms/PolarTest2.dpr`, `src/GeoAlgorithms/OrthogonalTest.dpr`, `src/GeoAlgorithms/TransformTest.dpr`, `src/GeoAlgorithms/TransformTestTXT.dpr`, `src/GeoAlgorithms/TestReadTXT.dpr`
- GDF testy: `Test_gdf/TestGeoRow.dpr`, `Test_gdf/TestGeoDataFrame.dpr`
- FieldGrid test: `Test_FieldGrid/TestFieldGrid.dpr`

### Hlavní formy GUI (`GeoSoft.dpr` -> `Application.CreateForm`)
- `TForm1` / `MainForm`
- `TForm2` / `PointsManagement`
- `TForm3` / `PolarMethod` ⚠️ *(unit zakomentována – pravděpodobně nefunkční)*
- `TForm4` / `OrthogonalMethod`
- `TForm5` / `Transformation`
- `TForm6` / `AddPoint`
- `TForm7` / `CheckMeasurement`
- `TForm8` / `CalcFormBase`
- `TForm9` / `PolarMethodNew`

### Datamoduly
- `TDataModule` nebyl v projektu nalezen.

---

## 4) Potenciálně kritické části

- **Globální stav / singleton:**
  - `PointsUtilsSingleton.pas`: `class var FInstance` + centrální mutable dictionary pro všechny formuláře.
  - `PointsManagement.pas`: globální proměnné `PointDict` a `Point` ve `var` sekci unitu.
  - `PointPrefixState.pas`: globální stav `GPointPrefix` sdílený mezi více formuláři.
  - GUI formuláře jsou globální instance (`Form1..Form9`) vytvářené při startu.

- **I/O a persistence:**
  - `PointsUtils.pas` a `PointsUtilsSingleton.pas`: přímé souborové operace (`AssignFile`, `Reset`, `Rewrite`, `TFileStream`) pro TXT/CSV/BIN.
  - `GeoRow.pas` + `GeoDataFrame.pas`: binární i CSV serializace (`SaveRow/LoadRow`, `SaveToFile/LoadFromFile/ToCSV/FromCSV`).
  - `PolarMethodNew.pas`: zápis pracovních dat (`Polar_*.bin`, `Polar_*.csv`) do aktuálního adresáře.

- **Mrtvý kód:**
  - `PolarMethod.pas` je kompletně zakomentovaná unit – TForm3 neexistuje jako aktivní třída. Pokud je `CreateForm(TForm3, Form3)` v DPR, způsobí to chybu při kompilaci nebo runtime crash.
  - `MainForm.pas` má v `uses` (`Data.DB`, `Vcl.DBGrids`, `Web.HTTPApp`, `Web.DBWeb`, `Web.DBXpressWeb`) – neaktivní závislosti na DB/Web stacku.

- **Duplicity názvů unitů:**
  - `GeoAlgorithmBase`, `GeoAlgorithmPolar`, `GeoAlgorithmOrthogonal` existují současně ve `src/Utils` i `src/GeoAlgorithms`. Liší se implementací (statické vs objektové property, Utils verze nezávisí na GeoDataFrame).

- **Threads:**
  - Nebyly nalezeny explicitní thread konstrukce. Single-thread UI + synchronní I/O.

- **Dva validační směry zároveň:**
  - Starší callback styl přes `InputFilterUtils` a `SetColumnValidator(...)`
  - Novější komponentový styl přes `ColumnFilters` a `ColumnValidation`
  - Formuláře nejsou sjednoceny na jeden styl.

---

## 5) Poznámka k `MyStringGrid.ColumnFilters`

- `ColumnFilters` je `published` property komponenty `MyStringGrid`, proto je vidět v Object Inspectoru.
- `ColumnFilters` je kolekce `TColumnFilters` – Delphi pro ni automaticky nabízí standardní collection editor.
- Počet itemů se interně dorovnává na `ColCount` přes `EnsureColumnFilterCount`.
- Jeden item odpovídá jednomu sloupci; `Column` je odvozený z `Index`.
- Filtrace znaků: `MyStringGrid.KeyPress -> ApplyColumnFilter -> ApplyColumnFilterKeyPress`.
- Finální validace: `ValidateTextByColumnFilter(...)` při opuštění buňky.

---

## Poznámka
Mapa aktualizována ke dni **13. dubna 2026**. Zaměřená na ručně ověřené hlavní vazby a vstupní body, ne na úplný výpis VCL/System závislostí.

### Hlavní změny od 28. března 2026
- Přibyl design-time package `Komponenty/MyComponentsR.dpk` s komponentami `TMyGrid` a `TGeoGrid`.
- `TGeoGrid` je dokončená komponenta s vlastní navigací přes `TGeoInplaceEdit` + virtuální `MoveToNextCell`, podporou `ColumnHeaders`/`RowHeaders` (publikované TStrings, editovatelné v OI) a virtuálními helpery `IsHeaderCell`/`IsDataCell`. Připravena jako základ pro `TGeoFieldsGrid`.
- `MoveToNextCell` pokrývá celé chování `TEnterEndBehavior` (ebStayOnLastCell / ebWrapToStart / ebAddRow / ebMoveFocusNext). Pro přechod fokusu používá `PostMessage(..., WM_NEXTDLGCTL, ...)` (respektuje Shift+Tab reverse).
- V `src/Components/` přibyly `GeoFieldColumn.pas` (nástupce `GeoFieldMeta`) a `MyFieldsStringGrid.pas` (nástupce `GeoFieldsStringGrid`).
- `MainForm` má `GeoGrid` v uses, ale test komponenty byly z designeru odstraněny.
